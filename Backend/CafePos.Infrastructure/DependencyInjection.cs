using CafePos.Application.Interfaces.CaLam;
using CafePos.Application.Interfaces.Pos;
using CafePos.Application.Interfaces.Pos.ThanhToan;
using CafePos.Application.Interfaces.QuanLy.BaoCao;
using CafePos.Application.Interfaces.QuanLy.NhanVien;
using CafePos.Application.Interfaces.QuanLy.PhanCa;
using CafePos.Application.Interfaces.QuanLy.TroLyAi;
using CafePos.Application.Interfaces.XacThuc;
using CafePos.Infrastructure.Data;
using CafePos.Infrastructure.Identity;
using CafePos.Infrastructure.Services.CaLam;
using CafePos.Infrastructure.Services.Pos;
using CafePos.Infrastructure.Services.Pos.ThanhToan;
using CafePos.Infrastructure.Services.QuanLy.BaoCao;
using CafePos.Infrastructure.Services.QuanLy.NhanVien;
using CafePos.Infrastructure.Services.QuanLy.PhanCa;
using CafePos.Infrastructure.Services.QuanLy.TroLyAi;
using CafePos.Infrastructure.Services.XacThuc;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace CafePos.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddCafePosInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = ResolveConnectionString(configuration);
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "Chưa cấu hình chuỗi kết nối PostgreSQL 'ConnectionStrings:DefaultConnection' (hoặc User Secrets / biến môi trường ConnectionStrings__DefaultConnection).");
        }

        services.AddDbContext<CafePosDbContext>(options =>
        {
            options.UseNpgsql(connectionString);
        });

        services
            .AddIdentityCore<AppIdentityUser>(options =>
            {
                // Cấu hình mật khẩu
                options.Password.RequireDigit = true;
                options.Password.RequiredLength = 6;
                options.Password.RequireNonAlphanumeric = false;
                options.Password.RequireUppercase = false;
                options.Password.RequireLowercase = false;

                // Cấu hình đếm lần nhập sai và khóa tạm (Lockout)
                options.Lockout.AllowedForNewUsers = true;
                options.Lockout.MaxFailedAccessAttempts = 5;
                options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
            })
            .AddRoles<AppIdentityRole>()
            .AddSignInManager<SignInManager<AppIdentityUser>>()
            .AddEntityFrameworkStores<CafePosDbContext>()
            .AddDefaultTokenProviders();

        services.AddScoped<IShiftService, ShiftService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IPosDashboardService, PosDashboardService>();
        services.AddScoped<IPaymentService, PaymentService>();
        services.AddScoped<IStaffManagementService, StaffManagementService>();
        services.AddScoped<IReportAnalyticsService, ReportAnalyticsService>();
        services.AddScoped<IShiftScheduleService, ShiftScheduleService>();
        services.AddScoped<IAiAssistantService, OllamaAiAssistantService>();

        var ollamaTimeoutSec = int.TryParse(configuration["Ollama:TimeoutSeconds"], out var tSec) && tSec > 0
            ? tSec
            : 120;
        services.AddHttpClient("Ollama", client =>
        {
            client.Timeout = TimeSpan.FromSeconds(ollamaTimeoutSec);
        });

        return services;
    }

    public static string? ResolveConnectionString(IConfiguration configuration)
    {
        var candidates = new[]
        {
            Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection"),
            configuration.GetConnectionString("DefaultConnection"),
            configuration["ConnectionString:DefaultConnection"],
            configuration["ConnectionString"]
        };

        foreach (var raw in candidates)
        {
            if (IsUsableConnectionString(raw))
            {
                return raw!.Trim();
            }
        }

        return null;
    }

    public static bool IsUsableConnectionString(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        var trimmed = value.Trim();
        if (trimmed.Contains('<') ||
            trimmed.Contains('>') ||
            trimmed.Contains("YOUR_PASSWORD", StringComparison.OrdinalIgnoreCase) ||
            trimmed.Contains("CHANGE_ME", StringComparison.OrdinalIgnoreCase) ||
            trimmed.Contains("PLACEHOLDER", StringComparison.OrdinalIgnoreCase) ||
            trimmed.Contains("PASSWORD_HERE", StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        return true;
    }
}
