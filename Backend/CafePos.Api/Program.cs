using System.Security.Claims;
using System.Text.Json;
using CafePos.Api.Controllers.XacThuc;
using CafePos.Api.Filters;
using CafePos.Application.Constants;
using CafePos.Application.Interfaces.XacThuc;
using CafePos.Infrastructure;
using CafePos.Infrastructure.Data;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;

var builder = WebApplication.CreateBuilder(args);

// Thứ tự ưu tiên cấu hình chuỗi kết nối:
// 1. Biến môi trường (ConnectionStrings__DefaultConnection)
// 2. .NET User Secrets (UserSecretsId trong CafePos.Api.csproj)
// 3. appsettings.Local.json (chỉ nạp khi không chứa placeholder để tránh ghi đè secret thật)
builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: true);
if (builder.Environment.IsDevelopment())
{
    builder.Configuration.AddUserSecrets<Program>(optional: true);
}
builder.Configuration.AddEnvironmentVariables();

// 1. Đăng ký tầng Infrastructure (EF Core + Npgsql PostgreSQL + ASP.NET Core Identity + Services)
builder.Services.AddCafePosInfrastructure(builder.Configuration);

var cookieSecurePolicy = CookieSecurePolicy.Always;

// 2. Cấu hình ASP.NET Core Cookie Authentication
// - HttpOnly = true, Secure = Always (hoặc SameAsRequest ở môi trường Dev), SameSite = Lax
// - Ghi nhớ đăng nhập: tối đa 7 ngày; bỏ chọn: theo phiên trình duyệt
// - OnValidatePrincipal: kiểm tra lại phiên cũ khi tài khoản bị khóa hoặc đổi quyền
builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultSignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    })
    .AddCookie(CookieAuthenticationDefaults.AuthenticationScheme, options =>
    {
        options.Cookie.Name = "PinVuTru.Pos.Auth";
        options.Cookie.HttpOnly = true;
        options.Cookie.SecurePolicy = cookieSecurePolicy;
        options.Cookie.SameSite = SameSiteMode.Lax;
        options.ExpireTimeSpan = TimeSpan.FromDays(7);
        options.SlidingExpiration = true;

        options.Events = new CookieAuthenticationEvents
        {
            OnValidatePrincipal = async context =>
            {
                var userIdRaw = context.Principal?.FindFirstValue(ClaimTypes.NameIdentifier);
                var securityStamp = context.Principal?.FindFirstValue(AuthController.SecurityStampClaimType);

                if (!Guid.TryParse(userIdRaw, out var userId))
                {
                    context.RejectPrincipal();
                    await context.HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
                    return;
                }

                var authService = context.HttpContext.RequestServices.GetRequiredService<IAuthService>();
                var isValid = await authService.IsSessionStillValidAsync(
                    userId,
                    securityStamp,
                    context.HttpContext.RequestAborted);

                if (!isValid)
                {
                    context.RejectPrincipal();
                    await context.HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
                }
            },
            OnRedirectToLogin = async context =>
            {
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                context.Response.ContentType = "application/json; charset=utf-8";
                await context.Response.WriteAsync(JsonSerializer.Serialize(new
                {
                    isSuccess = false,
                    errorCode = "UNAUTHORIZED",
                    message = "Phiên đăng nhập đã hết hạn hoặc chưa đăng nhập."
                }));
            },
            OnRedirectToAccessDenied = async context =>
            {
                context.Response.StatusCode = StatusCodes.Status403Forbidden;
                context.Response.ContentType = "application/json; charset=utf-8";
                await context.Response.WriteAsync(JsonSerializer.Serialize(new
                {
                    isSuccess = false,
                    errorCode = "FORBIDDEN",
                    message = "Tài khoản của bạn không có quyền thực hiện thao tác này."
                }));
            }
        };
    });

// 3. Cấu hình ASP.NET Core Authorization (Staff & Manager)
builder.Services.AddAuthorizationBuilder()
    .AddPolicy("StaffOrManager", policy =>
        policy.RequireRole(RoleNames.Staff, RoleNames.Manager))
    .AddPolicy("ManagerOnly", policy =>
        policy.RequireRole(RoleNames.Manager));

// 4. Cấu hình ASP.NET Core Antiforgery (Chống CSRF cho các thao tác thay đổi dữ liệu bằng Cookie)
builder.Services.AddAntiforgery(options =>
{
    options.HeaderName = "X-CSRF-TOKEN";
    options.Cookie.Name = "PinVuTru.Pos.Antiforgery";
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = cookieSecurePolicy;
    options.Cookie.SameSite = SameSiteMode.Lax;
});
builder.Services.AddScoped<ValidatePosAntiforgeryFilter>();

// 5. Cấu hình CORS cho Flutter Web (cho phép gửi kèm Cookie & header X-CSRF-TOKEN trên localhost)
builder.Services.AddCors(options =>
{
    options.AddPolicy("FlutterWebCors", policy =>
    {
        policy
            .SetIsOriginAllowed(origin =>
            {
                if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri))
                {
                    return false;
                }
                return uri.Host.Equals("localhost", StringComparison.OrdinalIgnoreCase) ||
                       uri.Host.Equals("127.0.0.1", StringComparison.OrdinalIgnoreCase);
            })
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});

builder.Services.AddControllers();

var app = builder.Build();

// Tự động khởi tạo bảng pos."CaLamViec" trên PostgreSQL (không seed tài khoản ảo)
await CafePosDbSeeder.InitializeDatabaseAsync(app.Services);

app.UseCors("FlutterWebCors");

// Phục vụ trực tiếp giao diện Flutter Web (PosClient/build/web) trên cùng origin HTTPS
var flutterBuildWebPath = Path.GetFullPath(
    Path.Combine(app.Environment.ContentRootPath, "..", "..", "PosClient", "build", "web"));

if (Directory.Exists(flutterBuildWebPath))
{
    var fileProvider = new PhysicalFileProvider(flutterBuildWebPath);
    app.UseDefaultFiles(new DefaultFilesOptions
    {
        FileProvider = fileProvider
    });
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = fileProvider
    });
}

app.UseAuthentication();
app.UseAuthorization();

// Endpoint kiểm tra tình trạng hoạt động của Backend & kết nối PostgreSQL (database: cafe_pos)
app.MapGet("/api/health", async (CafePosDbContext db, CancellationToken ct) =>
{
    var canConnect = await db.Database.CanConnectAsync(ct);
    var userCount = canConnect ? await db.Users.CountAsync(ct) : 0;
    var roleCount = canConnect ? await db.Roles.CountAsync(ct) : 0;

    return Results.Ok(new
    {
        status = canConnect ? "Healthy" : "DatabaseUnreachable",
        service = "PinVuTru Cafe POS API (3-Layer Architecture)",
        database = "cafe_pos (schema: pos)",
        usersInDb = userCount,
        rolesInDb = roleCount,
        serverTimeUtc = DateTimeOffset.UtcNow
    });
});

app.MapControllers();

if (Directory.Exists(flutterBuildWebPath))
{
    var indexHtmlPath = Path.Combine(flutterBuildWebPath, "index.html");
    app.MapFallback(async context =>
    {
        if (context.Request.Path.StartsWithSegments("/api"))
        {
            context.Response.StatusCode = StatusCodes.Status404NotFound;
            return;
        }
        context.Response.ContentType = "text/html; charset=utf-8";
        await context.Response.SendFileAsync(indexHtmlPath);
    });
}

app.Run();
