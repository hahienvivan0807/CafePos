using System.Security.Cryptography;
using CafePos.Application.Constants;
using CafePos.Application.Entities;
using CafePos.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace CafePos.Infrastructure.Data;

public static class CafePosDbSeeder
{
    public static async Task InitializeDatabaseAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var logger = scope.ServiceProvider.GetRequiredService<ILoggerFactory>()
            .CreateLogger("CafePosDbSeeder");

        var db = scope.ServiceProvider.GetRequiredService<CafePosDbContext>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<AppIdentityRole>>();

        // Đảm bảo schema pos và bảng pos."CaLamViec" kèm Unique Filtered Index tồn tại trên database cafe_pos
        await db.Database.ExecuteSqlRawAsync("""
            CREATE SCHEMA IF NOT EXISTS pos;

            CREATE TABLE IF NOT EXISTS pos."CaLamViec" (
                "Id" uuid PRIMARY KEY,
                "IdNguoiDung" uuid NOT NULL REFERENCES pos."NguoiDung" ("Id") ON DELETE CASCADE,
                "TrangThai" varchar(20) NOT NULL DEFAULT 'DangMo'
                    CHECK ("TrangThai" IN ('DangMo', 'DaDong')),
                "BatDauLuc" timestamptz NOT NULL DEFAULT now(),
                "KetThucLuc" timestamptz,
                "GhiChuMoCa" text,
                "GhiChuKetCa" text,
                CHECK (("TrangThai" = 'DaDong') = ("KetThucLuc" IS NOT NULL))
            );

            CREATE INDEX IF NOT EXISTS "IdxCaLamViecNguoiDung"
                ON pos."CaLamViec" ("IdNguoiDung");

            CREATE UNIQUE INDEX IF NOT EXISTS "UqCaLamViecDangMoMoiNguoi"
                ON pos."CaLamViec" ("IdNguoiDung")
                WHERE "TrangThai" = 'DangMo';
            """);

        // Đảm bảo 2 danh mục vai trò hệ thống (Staff, Manager) trong pos."VaiTro"
        await EnsureRoleAsync(roleManager, RoleNames.Staff);
        await EnsureRoleAsync(roleManager, RoleNames.Manager);

        // Bổ sung idempotent 3 tài khoản nhân viên thật (nv01, nv02, nv03) nếu chưa có trong pos."NguoiDung"
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppIdentityUser>>();
        await EnsureInitialStaffAccountsAsync(db, userManager);

        logger.LogInformation("Đã kết nối PostgreSQL (database cafe_pos, schema pos) và đồng bộ bảng pos.\"CaLamViec\" cùng dữ liệu nhân sự thành công.");
    }

    private static async Task EnsureInitialStaffAccountsAsync(
        CafePosDbContext db,
        UserManager<AppIdentityUser> userManager)
    {
        var initialStaff = new[]
        {
            (Username: "nv01", FullName: "Nguyễn Minh Khang", Phone: "0909111222", IsActive: true),
            (Username: "nv02", FullName: "Trần Thảo Vy", Phone: "0909333444", IsActive: true),
            (Username: "nv03", FullName: "Lê Hoàng Phúc", Phone: "0909555666", IsActive: false)
        };

        foreach (var item in initialStaff)
        {
            var normalized = item.Username.ToUpperInvariant();
            var exists = await db.Users.AnyAsync(u => u.NormalizedUserName == normalized);
            if (exists)
            {
                continue;
            }

            var user = new AppIdentityUser
            {
                Id = Guid.NewGuid(),
                UserName = item.Username,
                NormalizedUserName = normalized,
                PhoneNumber = item.Phone,
                DangHoatDong = item.IsActive,
                LockoutEnabled = true
            };

            var tempPin = RandomNumberGenerator.GetInt32(100000, 999999);
            var created = await userManager.CreateAsync(user, $"Pos{tempPin}");
            if (!created.Succeeded)
            {
                continue;
            }

            await userManager.AddToRoleAsync(user, RoleNames.Staff);
            db.HoSoNguoiDungs.Add(new HoSoNguoiDung
            {
                IdNguoiDung = user.Id,
                HoTen = item.FullName,
                SoDienThoaiLienHe = item.Phone,
                CapNhatLuc = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }
    }

    private static async Task EnsureRoleAsync(
        RoleManager<AppIdentityRole> roleManager,
        string roleName)
    {
        if (!await roleManager.RoleExistsAsync(roleName))
        {
            await roleManager.CreateAsync(new AppIdentityRole
            {
                Id = Guid.NewGuid(),
                Name = roleName,
                NormalizedName = roleName.ToUpperInvariant(),
                ConcurrencyStamp = Guid.NewGuid().ToString()
            });
        }
    }
}
