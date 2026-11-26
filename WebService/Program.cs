using CafePosTracker.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration
    .AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: true)
    .AddEnvironmentVariables();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "Chưa cấu hình ConnectionStrings:DefaultConnection. Hãy thiết lập qua User Secrets, biến môi trường hoặc file appsettings.Local.json.");
}

builder.Services.AddRazorPages();
builder.Services.AddDbContext<TrackerDbContext>(options =>
    options.UseSqlServer(connectionString));

var app = builder.Build();

// Khởi tạo / migrate database và seed dữ liệu idempotent khi khởi động.
using (var scope = app.Services.CreateScope())
{
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    try
    {
        var db = scope.ServiceProvider.GetRequiredService<TrackerDbContext>();
        await db.Database.MigrateAsync();
        await TrackerSeeder.SeedAsync(db);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Không thể kết nối hoặc migrate SQL Server khi khởi động.");
    }
}

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
}

app.UseRouting();
app.UseAuthorization();

app.MapStaticAssets();
app.MapRazorPages()
   .WithStaticAssets();

app.MapGet("/health", () => Results.Ok(new { status = "ok", timestamp = DateTime.UtcNow }));

app.MapPost("/api/items/{id:int}/status", async (
    int id,
    UpdateItemStatusRequest request,
    TrackerDbContext db,
    CancellationToken cancellationToken) =>
{
    try
    {
        var item = await db.WorkItems
            .Include(i => i.Group)
            .FirstOrDefaultAsync(i => i.Id == id, cancellationToken);

        if (item is null)
        {
            return Results.NotFound(new { message = "Không tìm thấy công việc cần cập nhật." });
        }

        var now = DateTime.UtcNow;
        item.IsCompleted = request.IsCompleted;
        item.CompletedAt = request.IsCompleted ? now : null;
        item.UpdatedAt = now;

        await db.SaveChangesAsync(cancellationToken);

        var stats = await db.WorkItems
            .GroupBy(i => i.GroupId)
            .Select(g => new
            {
                GroupId = g.Key,
                Total = g.Count(),
                Completed = g.Count(x => x.IsCompleted)
            })
            .ToListAsync(cancellationToken);

        var totalAll = stats.Sum(s => s.Total);
        var completedAll = stats.Sum(s => s.Completed);

        return Results.Ok(new
        {
            id = item.Id,
            code = item.Code,
            groupId = item.GroupId,
            groupCode = item.Group?.Code,
            isCompleted = item.IsCompleted,
            completedAt = item.CompletedAt,
            updatedAt = item.UpdatedAt,
            overall = new
            {
                total = totalAll,
                completed = completedAll,
                percent = totalAll == 0 ? 0 : (int)Math.Round(completedAll * 100.0 / totalAll)
            },
            groups = stats.Select(s => new
            {
                groupId = s.GroupId,
                total = s.Total,
                completed = s.Completed
            })
        });
    }
    catch (Exception ex)
    {
        return Results.Problem(
            title: "Không thể lưu vào SQL Server",
            detail: ex.Message,
            statusCode: StatusCodes.Status503ServiceUnavailable);
    }
});

app.Run();

public sealed record UpdateItemStatusRequest(bool IsCompleted);
