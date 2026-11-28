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

            CREATE TABLE IF NOT EXISTS pos."KhungCaLam" (
                "Ma" varchar(24) PRIMARY KEY,
                "TenCa" varchar(120) NOT NULL,
                "GioBatDau" time NOT NULL,
                "GioKetThuc" time NOT NULL,
                "ThuTu" int NOT NULL DEFAULT 1
            );

            ALTER TABLE pos."KhungCaLam" ADD COLUMN IF NOT EXISTS "QuaDem" boolean NOT NULL DEFAULT false;
            ALTER TABLE pos."KhungCaLam" ADD COLUMN IF NOT EXISTS "NghiGiuaCaPhut" int NOT NULL DEFAULT 0;
            ALTER TABLE pos."KhungCaLam" ADD COLUMN IF NOT EXISTS "DinhBienPhaChe" int NOT NULL DEFAULT 1;
            ALTER TABLE pos."KhungCaLam" ADD COLUMN IF NOT EXISTS "DinhBienThuNgan" int NOT NULL DEFAULT 1;
            ALTER TABLE pos."KhungCaLam" ADD COLUMN IF NOT EXISTS "DinhBienPhucVu" int NOT NULL DEFAULT 1;
            ALTER TABLE pos."KhungCaLam" ADD COLUMN IF NOT EXISTS "DangApDung" boolean NOT NULL DEFAULT true;
            ALTER TABLE pos."KhungCaLam" ADD COLUMN IF NOT EXISTS "GhiChuBanGiao" text;
            ALTER TABLE pos."KhungCaLam" ADD COLUMN IF NOT EXISTS "CapNhatLuc" timestamptz NOT NULL DEFAULT now();

            INSERT INTO pos."KhungCaLam" ("Ma", "TenCa", "GioBatDau", "GioKetThuc", "ThuTu", "NghiGiuaCaPhut", "DinhBienPhaChe", "DinhBienThuNgan", "DinhBienPhucVu")
            VALUES
                ('CA_SANG',  'Ca Sáng · Mở quán',       '07:00:00', '11:00:00', 1, 0,  1, 1, 1),
                ('CA_TRUA',  'Ca Trưa · Giờ nghỉ',      '11:00:00', '14:00:00', 2, 15, 1, 1, 1),
                ('CA_CHIEU', 'Ca Chiều · Học tập',      '14:00:00', '18:00:00', 3, 15, 2, 1, 1),
                ('CA_TOI',   'Ca Tối · Chạy deadline',  '18:00:00', '22:30:00', 4, 15, 2, 1, 2)
            ON CONFLICT ("Ma") DO NOTHING;

            CREATE TABLE IF NOT EXISTS pos."PhanCaNhanVien" (
                "Id" bigserial PRIMARY KEY,
                "NgayLam" date NOT NULL,
                "MaKhungCa" varchar(24) NOT NULL REFERENCES pos."KhungCaLam" ("Ma") ON DELETE RESTRICT,
                "IdNguoiDung" uuid NOT NULL REFERENCES pos."NguoiDung" ("Id") ON DELETE RESTRICT,
                "ViTri" varchar(32) NOT NULL DEFAULT 'PhaChe',
                "GioVao" time NOT NULL,
                "GioRa" time NOT NULL,
                "TrangThaiTuan" varchar(24) NOT NULL DEFAULT 'Nhap',
                "TrangThai" varchar(24) NOT NULL DEFAULT 'HoatDong',
                "LyDoHuy" text,
                "TaoLuc" timestamptz NOT NULL DEFAULT now(),
                "CapNhatLuc" timestamptz NOT NULL DEFAULT now()
            );

            CREATE INDEX IF NOT EXISTS "IdxPhanCaNgayKhungCa"
                ON pos."PhanCaNhanVien" ("NgayLam", "MaKhungCa");

            ALTER TABLE pos."DonHang"
                ADD COLUMN IF NOT EXISTS "MaKhungCa" varchar(24);

            DO $$
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 FROM pg_constraint
                    WHERE conname = 'FkDonHangKhungCaLam'
                ) THEN
                    ALTER TABLE pos."DonHang"
                        ADD CONSTRAINT "FkDonHangKhungCaLam"
                        FOREIGN KEY ("MaKhungCa")
                        REFERENCES pos."KhungCaLam" ("Ma")
                        ON DELETE RESTRICT;
                END IF;
            END $$;

            UPDATE pos."DonHang"
            SET "MaKhungCa" = CASE
                WHEN EXTRACT(HOUR FROM ("TaoLuc" AT TIME ZONE 'Asia/Ho_Chi_Minh')) < 11 THEN 'CA_SANG'
                WHEN EXTRACT(HOUR FROM ("TaoLuc" AT TIME ZONE 'Asia/Ho_Chi_Minh')) < 14 THEN 'CA_TRUA'
                WHEN EXTRACT(HOUR FROM ("TaoLuc" AT TIME ZONE 'Asia/Ho_Chi_Minh')) < 18 THEN 'CA_CHIEU'
                ELSE 'CA_TOI'
            END
            WHERE "MaKhungCa" IS NULL;

            CREATE TABLE IF NOT EXISTS pos."YeuCauQrThanhToan" (
                "Id" bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
                "IdDonHang" bigint NOT NULL REFERENCES pos."DonHang" ("Id") ON DELETE RESTRICT,
                "PhienBan" integer NOT NULL DEFAULT 1,
                "MaThamChieu" varchar(48) NOT NULL UNIQUE,
                "SoTienVnd" bigint NOT NULL,
                "MaNganHang" varchar(24) NOT NULL DEFAULT 'MB',
                "SoTaiKhoan" varchar(40) NOT NULL,
                "TenTaiKhoan" varchar(120) NOT NULL,
                "DuongDanAnhQr" text NOT NULL,
                "TrangThai" varchar(24) NOT NULL DEFAULT 'DangCho',
                "TaoLuc" timestamptz NOT NULL DEFAULT now(),
                "CapNhatLuc" timestamptz
            );

            CREATE INDEX IF NOT EXISTS "IdxYeuCauQrDonHang"
                ON pos."YeuCauQrThanhToan" ("IdDonHang", "PhienBan");

            CREATE TABLE IF NOT EXISTS pos."GiaoDichThanhToan" (
                "Id" bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
                "IdDonHang" bigint NOT NULL REFERENCES pos."DonHang" ("Id") ON DELETE RESTRICT,
                "IdYeuCauQr" bigint REFERENCES pos."YeuCauQrThanhToan" ("Id") ON DELETE RESTRICT,
                "PhuongThuc" varchar(24) NOT NULL DEFAULT 'vietqr',
                "MaGiaoDichNganHang" varchar(120),
                "CongThanhToan" varchar(64),
                "MaThamChieuKhop" varchar(48),
                "NoiDungChuyenKhoan" text,
                "SoTienVnd" bigint NOT NULL,
                "CanDoiSoat" boolean NOT NULL DEFAULT false,
                "TrangThaiDoiSoat" varchar(24) NOT NULL DEFAULT 'KhongCan',
                "GhiChuDoiSoat" text,
                "IdNguoiXacNhan" uuid,
                "GhiNhanLuc" timestamptz NOT NULL DEFAULT now(),
                "DoiSoatLuc" timestamptz
            );

            CREATE UNIQUE INDEX IF NOT EXISTS "UqGiaoDichMaNganHang"
                ON pos."GiaoDichThanhToan" ("MaGiaoDichNganHang")
                WHERE "MaGiaoDichNganHang" IS NOT NULL;

            CREATE INDEX IF NOT EXISTS "IdxGiaoDichDonHang"
                ON pos."GiaoDichThanhToan" ("IdDonHang");

            CREATE INDEX IF NOT EXISTS "IdxGiaoDichCanDoiSoat"
                ON pos."GiaoDichThanhToan" ("CanDoiSoat", "TrangThaiDoiSoat");
            """);

        // Đảm bảo 2 danh mục vai trò hệ thống (Staff, Manager) trong pos."VaiTro"
        await EnsureRoleAsync(roleManager, RoleNames.Staff);
        await EnsureRoleAsync(roleManager, RoleNames.Manager);

        // Bổ sung idempotent 3 tài khoản nhân viên thật (nv01, nv02, nv03) nếu chưa có trong pos."NguoiDung"
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppIdentityUser>>();
        await EnsureInitialStaffAccountsAsync(db, userManager);

        // Bổ sung idempotent thực đơn đầy đủ chuẩn quán cà phê học bài (5 danh mục, 18 món)
        await EnsureStudyCafeMenuAsync(db);

        // Bổ sung idempotent dữ liệu giao dịch thật cho cả 3 kỳ báo cáo (Hôm nay / 7 ngày qua / Tháng này)
        // và cả 3 trạng thái đơn (paid / awaiting_payment / open)
        await EnsureHistoricalReportOrdersAsync(db);

        // Bổ sung idempotent đơn mẫu đa dạng món quán cà phê học bài đều cả 4 ca làm việc
        await EnsureStudyCafeShiftOrdersAsync(db);

        // Bổ sung idempotent vài phân công mẫu cho tuần hiện tại để Lịch phân ca có dữ liệu thật ngay
        await EnsureSampleShiftAssignmentsAsync(db);

        logger.LogInformation("Đã kết nối PostgreSQL (database cafe_pos, schema pos) và đồng bộ KhungCaLam, PhanCaNhanVien, thực đơn quán học bài & báo cáo thành công.");
    }

    private static async Task EnsureSampleShiftAssignmentsAsync(CafePosDbContext db)
    {
        if (await db.PhanCaNhanViens.AnyAsync()) return;

        var activeUsers = await db.Users
            .Where(u => u.DangHoatDong)
            .OrderBy(u => u.UserName)
            .Take(2)
            .ToListAsync();
        if (activeUsers.Count == 0) return;

        var vnOffset = TimeSpan.FromHours(7);
        var today = DateOnly.FromDateTime(DateTimeOffset.UtcNow.ToOffset(vnOffset).DateTime);
        var diffToMonday = ((int)today.DayOfWeek + 6) % 7;
        var monday = today.AddDays(-diffToMonday);

        var samples = new List<PhanCaNhanVien>
        {
            new()
            {
                NgayLam = monday,
                MaKhungCa = "CA_SANG",
                IdNguoiDung = activeUsers[0].Id,
                ViTri = "PhaChe",
                GioVao = new TimeOnly(7, 0),
                GioRa = new TimeOnly(11, 0),
                TrangThaiTuan = "Nhap",
                TrangThai = "HoatDong"
            },
            new()
            {
                NgayLam = today,
                MaKhungCa = "CA_CHIEU",
                IdNguoiDung = activeUsers[0].Id,
                ViTri = "PhaChe",
                GioVao = new TimeOnly(14, 0),
                GioRa = new TimeOnly(18, 0),
                TrangThaiTuan = "Nhap",
                TrangThai = "HoatDong"
            }
        };

        if (activeUsers.Count > 1)
        {
            samples.Add(new PhanCaNhanVien
            {
                NgayLam = today,
                MaKhungCa = "CA_CHIEU",
                IdNguoiDung = activeUsers[1].Id,
                ViTri = "ThuNgan",
                GioVao = new TimeOnly(14, 0),
                GioRa = new TimeOnly(18, 0),
                TrangThaiTuan = "Nhap",
                TrangThai = "HoatDong"
            });
            samples.Add(new PhanCaNhanVien
            {
                NgayLam = today,
                MaKhungCa = "CA_TOI",
                IdNguoiDung = activeUsers[1].Id,
                ViTri = "PhucVu",
                GioVao = new TimeOnly(18, 0),
                GioRa = new TimeOnly(22, 30),
                TrangThaiTuan = "Nhap",
                TrangThai = "HoatDong"
            });
        }

        db.PhanCaNhanViens.AddRange(samples);
        await db.SaveChangesAsync();
    }

    private static async Task EnsureStudyCafeMenuAsync(CafePosDbContext db)
    {
        var categoriesSpec = new[]
        {
            (Ma: "COFFEE", Ten: "Cà phê"),
            (Ma: "TEA", Ten: "Trà"),
            (Ma: "MATCHA", Ten: "Matcha & Đá xay"),
            (Ma: "JUICE", Ten: "Nước ép & Soda"),
            (Ma: "PASTRY", Ten: "Bánh ngọt học bài")
        };

        var catMap = new Dictionary<string, long>(StringComparer.OrdinalIgnoreCase);
        foreach (var cat in categoriesSpec)
        {
            var existing = await db.DanhMucMons.FirstOrDefaultAsync(c => c.Ma == cat.Ma);
            if (existing is null)
            {
                existing = new DanhMucMon { Ma = cat.Ma, Ten = cat.Ten };
                db.DanhMucMons.Add(existing);
                await db.SaveChangesAsync();
            }
            catMap[cat.Ma] = existing.Id;
        }

        var itemsSpec = new[]
        {
            ("COFFEE", "CA-PHE-DEN", "Cà phê đen đá", 25000L),
            ("COFFEE", "CA-PHE-MUOI", "Cà phê muối", 35000L),
            ("COFFEE", "AMERICANO-DA", "Americano đá", 35000L),
            ("COFFEE", "LATTE-NONG-DA", "Latte nóng/đá", 42000L),
            ("COFFEE", "COLD-BREW-CAM", "Cold Brew cam sả", 45000L),
            ("TEA", "TRA-VAI-HOA-HONG", "Trà vải hoa hồng", 42000L),
            ("TEA", "TRA-SEN-VANG", "Trà sen vàng kem cheese", 45000L),
            ("TEA", "TRA-OLONG-TC", "Trà ô long trân châu", 40000L),
            ("TEA", "TRA-CHANH-MAT-ONG", "Trà chanh mật ong gừng", 35000L),
            ("MATCHA", "MATCHA-LATTE", "Matcha Latte Nhật", 48000L),
            ("MATCHA", "CACAO-SUA-DA", "Cacao sữa đá", 38000L),
            ("MATCHA", "COOKIE-CREAM", "Cookie & Cream đá xay", 50000L),
            ("JUICE", "SODA-VIET-QUAT", "Soda việt quất bạc hà", 40000L),
            ("JUICE", "EP-CAM-TUOI", "Nước ép cam tươi", 42000L),
            ("PASTRY", "CROISSANT-BO", "Croissant bơ Pháp", 35000L),
            ("PASTRY", "TIRAMISU-HOP", "Bánh Tiramisu hộp", 45000L)
        };

        var existingCodes = await db.Mons
            .Select(m => m.Ma)
            .ToListAsync();
        var existingSet = new HashSet<string>(existingCodes, StringComparer.OrdinalIgnoreCase);

        foreach (var (catCode, itemCode, itemName, price) in itemsSpec)
        {
            if (existingSet.Contains(itemCode)) continue;
            db.Mons.Add(new Mon
            {
                IdDanhMuc = catMap[catCode],
                Ma = itemCode,
                Ten = itemName,
                GiaVnd = price,
                DangHoatDong = true
            });
        }

        await db.SaveChangesAsync();
    }

    private static async Task EnsureStudyCafeShiftOrdersAsync(CafePosDbContext db)
    {
        if (await db.DonHangs.AnyAsync(d => d.Ma.StartsWith("STUDY-")))
        {
            return;
        }

        var tables = await db.Bans.Where(b => b.DangHoatDong).OrderBy(b => b.Id).ToListAsync();
        var menuItems = await db.Mons.Where(m => m.DangHoatDong).OrderBy(m => m.Id).ToListAsync();
        var staffUser = await db.Users.OrderBy(u => u.UserName).FirstOrDefaultAsync();
        if (tables.Count == 0 || menuItems.Count < 6 || staffUser is null) return;

        var vnOffset = TimeSpan.FromHours(7);
        var todayLocal = DateOnly.FromDateTime(DateTimeOffset.UtcNow.ToOffset(vnOffset).DateTime);

        var shiftSpecs = new[]
        {
            (Code: "CA_SANG", Hour: 8, Minute: 30),
            (Code: "CA_TRUA", Hour: 12, Minute: 20),
            (Code: "CA_CHIEU", Hour: 15, Minute: 40),
            (Code: "CA_TOI", Hour: 20, Minute: 10)
        };

        var seq = 1;
        // Tạo đơn đa dạng món quán học bài cho 4 ngày gần nhất (bao gồm hôm nay) đều ở cả 4 ca
        for (var dOff = 3; dOff >= 0; dOff--)
        {
            var date = todayLocal.AddDays(-dOff);
            for (var sIdx = 0; sIdx < shiftSpecs.Length; sIdx++)
            {
                var spec = shiftSpecs[sIdx];
                var table = tables[(dOff + sIdx) % tables.Count];
                var openedLocal = new DateTimeOffset(date.ToDateTime(new TimeOnly(spec.Hour, spec.Minute)), vnOffset);
                var paidLocal = openedLocal.AddMinutes(35);
                var closedLocal = openedLocal.AddMinutes(55);

                var luot = new LuotBan
                {
                    IdBan = table.Id,
                    IdNguoiMo = staffUser.Id,
                    MoLuc = openedLocal.ToUniversalTime(),
                    IdNguoiTraBan = staffUser.Id,
                    TraBanLuc = closedLocal.ToUniversalTime()
                };
                db.LuotBans.Add(luot);
                await db.SaveChangesAsync();

                var don = new DonHang
                {
                    IdLuotBan = luot.Id,
                    Ma = $"STUDY-{date:MMdd}-{seq++:D3}",
                    TrangThai = OrderStatuses.Paid,
                    IdNguoiTao = staffUser.Id,
                    MaKhungCa = spec.Code,
                    TaoLuc = openedLocal.ToUniversalTime(),
                    ThanhToanLuc = paidLocal.ToUniversalTime()
                };
                db.DonHangs.Add(don);
                await db.SaveChangesAsync();

                var m1 = menuItems[(seq * 2) % menuItems.Count];
                var m2 = menuItems[(seq * 3 + 5) % menuItems.Count];
                db.DongMons.AddRange(
                    new DongMon
                    {
                        IdDonHang = don.Id,
                        IdMon = m1.Id,
                        TenMonLucBan = m1.Ten,
                        DonGiaLucBanVnd = m1.GiaVnd,
                        SoLuong = 1 + (seq % 2),
                        IdNguoiGhiMon = staffUser.Id,
                        GhiMonLuc = openedLocal.ToUniversalTime()
                    },
                    new DongMon
                    {
                        IdDonHang = don.Id,
                        IdMon = m2.Id,
                        TenMonLucBan = m2.Ten,
                        DonGiaLucBanVnd = m2.GiaVnd,
                        SoLuong = 1,
                        IdNguoiGhiMon = staffUser.Id,
                        GhiMonLuc = openedLocal.AddMinutes(3).ToUniversalTime()
                    });
                await db.SaveChangesAsync();
            }
        }
    }

    private static async Task EnsureHistoricalReportOrdersAsync(CafePosDbContext db)
    {
        var alreadySeeded = await db.DonHangs.AnyAsync(d => d.Ma.StartsWith("RPT-"));
        if (alreadySeeded)
        {
            return;
        }

        var tables = await db.Bans
            .Where(b => b.DangHoatDong)
            .OrderBy(b => b.Id)
            .ToListAsync();
        var menuItems = await db.Mons
            .Where(m => m.DangHoatDong)
            .OrderBy(m => m.Id)
            .ToListAsync();
        var staffUser = await db.Users
            .OrderBy(u => u.UserName)
            .FirstOrDefaultAsync();

        if (tables.Count == 0 || menuItems.Count == 0 || staffUser is null)
        {
            return;
        }

        var vnOffset = TimeSpan.FromHours(7);
        var todayLocal = DateOnly.FromDateTime(DateTimeOffset.UtcNow.ToOffset(vnOffset).DateTime);
        var slotsHours = new[] { 8, 12, 15, 20 }; // Sáng, Trưa, Chiều, Tối
        var seq = 1;

        // 1. Seed 12 ngày lịch sử (từ -12 đến -1) phủ đủ cả "Tháng này", "7 ngày qua" và mô hình "Dự báo AI" (>= 7 ngày)
        for (var dayOffset = 12; dayOffset >= 1; dayOffset--)
        {
            var date = todayLocal.AddDays(-dayOffset);
            var isWeekend = date.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday;
            var ordersForDay = isWeekend ? 4 : 3;

            for (var i = 0; i < ordersForDay; i++)
            {
                var table = tables[(dayOffset + i) % tables.Count];
                var hour = slotsHours[(dayOffset + i) % slotsHours.Length];
                var openedLocal = new DateTimeOffset(date.ToDateTime(new TimeOnly(hour, (i * 13) % 50)), vnOffset);
                var paidLocal = openedLocal.AddMinutes(35);
                var closedLocal = openedLocal.AddMinutes(50);

                var luot = new LuotBan
                {
                    IdBan = table.Id,
                    IdNguoiMo = staffUser.Id,
                    MoLuc = openedLocal.ToUniversalTime(),
                    IdNguoiTraBan = staffUser.Id,
                    TraBanLuc = closedLocal.ToUniversalTime()
                };
                db.LuotBans.Add(luot);
                await db.SaveChangesAsync();

                var don = new DonHang
                {
                    IdLuotBan = luot.Id,
                    Ma = $"RPT-{date:MMdd}-{seq++:D3}",
                    TrangThai = OrderStatuses.Paid,
                    IdNguoiTao = staffUser.Id,
                    TaoLuc = openedLocal.ToUniversalTime(),
                    ThanhToanLuc = paidLocal.ToUniversalTime()
                };
                db.DonHangs.Add(don);
                await db.SaveChangesAsync();

                var item1 = menuItems[(dayOffset + i) % menuItems.Count];
                var item2 = menuItems[(dayOffset + i + 2) % menuItems.Count];
                var qty1 = isWeekend ? 3 : 2;
                var qty2 = 1 + ((dayOffset + i) % 2);

                db.DongMons.AddRange(
                    new DongMon
                    {
                        IdDonHang = don.Id,
                        IdMon = item1.Id,
                        TenMonLucBan = item1.Ten,
                        DonGiaLucBanVnd = item1.GiaVnd,
                        SoLuong = qty1,
                        IdNguoiGhiMon = staffUser.Id,
                        GhiMonLuc = openedLocal.ToUniversalTime()
                    },
                    new DongMon
                    {
                        IdDonHang = don.Id,
                        IdMon = item2.Id,
                        TenMonLucBan = item2.Ten,
                        DonGiaLucBanVnd = item2.GiaVnd,
                        SoLuong = qty2,
                        IdNguoiGhiMon = staffUser.Id,
                        GhiMonLuc = openedLocal.AddMinutes(2).ToUniversalTime()
                    });
                await db.SaveChangesAsync();
            }
        }

        // 2. Seed dữ liệu cho "Hôm nay" với đủ 3 trạng thái đơn (paid, awaiting_payment, open)
        var todayPaidSpecs = new[] { 8, 11, 14 };
        foreach (var hour in todayPaidSpecs)
        {
            var table = tables[seq % tables.Count];
            var openedLocal = new DateTimeOffset(todayLocal.ToDateTime(new TimeOnly(hour, 15)), vnOffset);
            var paidLocal = openedLocal.AddMinutes(30);
            var closedLocal = openedLocal.AddMinutes(45);

            var luot = new LuotBan
            {
                IdBan = table.Id,
                IdNguoiMo = staffUser.Id,
                MoLuc = openedLocal.ToUniversalTime(),
                IdNguoiTraBan = staffUser.Id,
                TraBanLuc = closedLocal.ToUniversalTime()
            };
            db.LuotBans.Add(luot);
            await db.SaveChangesAsync();

            var don = new DonHang
            {
                IdLuotBan = luot.Id,
                Ma = $"RPT-{todayLocal:MMdd}-{seq++:D3}",
                TrangThai = OrderStatuses.Paid,
                IdNguoiTao = staffUser.Id,
                TaoLuc = openedLocal.ToUniversalTime(),
                ThanhToanLuc = paidLocal.ToUniversalTime()
            };
            db.DonHangs.Add(don);
            await db.SaveChangesAsync();

            var item = menuItems[seq % menuItems.Count];
            db.DongMons.Add(new DongMon
            {
                IdDonHang = don.Id,
                IdMon = item.Id,
                TenMonLucBan = item.Ten,
                DonGiaLucBanVnd = item.GiaVnd,
                SoLuong = 2,
                IdNguoiGhiMon = staffUser.Id,
                GhiMonLuc = openedLocal.ToUniversalTime()
            });
            await db.SaveChangesAsync();
        }

        // Thêm 1 đơn awaiting_payment và 1 đơn open hôm nay (trên các bàn hiện đang trống để không vi phạm UqLuotMoMoiBan)
        var openTableIds = await db.LuotBans
            .Where(l => l.TraBanLuc == null)
            .Select(l => l.IdBan)
            .ToListAsync();
        var freeTables = tables.Where(t => !openTableIds.Contains(t.Id)).Take(2).ToList();

        var liveStatuses = new[] { OrderStatuses.AwaitingPayment, OrderStatuses.Open };
        for (var idx = 0; idx < freeTables.Count; idx++)
        {
            var table = freeTables[idx];
            var openedLocal = DateTimeOffset.UtcNow.ToOffset(vnOffset).AddMinutes(-(25 - idx * 10));
            var luot = new LuotBan
            {
                IdBan = table.Id,
                IdNguoiMo = staffUser.Id,
                MoLuc = openedLocal.ToUniversalTime()
            };
            db.LuotBans.Add(luot);
            await db.SaveChangesAsync();

            var don = new DonHang
            {
                IdLuotBan = luot.Id,
                Ma = $"RPT-{todayLocal:MMdd}-{seq++:D3}",
                TrangThai = liveStatuses[idx],
                IdNguoiTao = staffUser.Id,
                TaoLuc = openedLocal.ToUniversalTime()
            };
            db.DonHangs.Add(don);
            await db.SaveChangesAsync();

            var item = menuItems[(idx + 1) % menuItems.Count];
            db.DongMons.Add(new DongMon
            {
                IdDonHang = don.Id,
                IdMon = item.Id,
                TenMonLucBan = item.Ten,
                DonGiaLucBanVnd = item.GiaVnd,
                SoLuong = 2,
                IdNguoiGhiMon = staffUser.Id,
                GhiMonLuc = openedLocal.ToUniversalTime()
            });
            await db.SaveChangesAsync();
        }
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
