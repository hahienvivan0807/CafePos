using CafePos.Application.Constants;
using CafePos.Application.Entities;
using CafePos.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace CafePos.Infrastructure.Data;

/// <summary>
/// DbContext ánh xạ chính xác 100% sang schema 'pos' của database cafe_pos theo file 01-pos-schema.sql
/// </summary>
public class CafePosDbContext : IdentityDbContext<AppIdentityUser, AppIdentityRole, Guid>
{
    public CafePosDbContext(DbContextOptions<CafePosDbContext> options)
        : base(options)
    {
    }

    public DbSet<HoSoNguoiDung> HoSoNguoiDungs => Set<HoSoNguoiDung>();
    public DbSet<CaLamViec> CaLamViecs => Set<CaLamViec>();
    public DbSet<DanhMucMon> DanhMucMons => Set<DanhMucMon>();
    public DbSet<Mon> Mons => Set<Mon>();
    public DbSet<Ban> Bans => Set<Ban>();
    public DbSet<LuotBan> LuotBans => Set<LuotBan>();
    public DbSet<DonHang> DonHangs => Set<DonHang>();
    public DbSet<DongMon> DongMons => Set<DongMon>();
    public DbSet<YeuCauHuyMon> YeuCauHuyMons => Set<YeuCauHuyMon>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.HasDefaultSchema("pos");

        // 1. Bảng pos."NguoiDung"
        builder.Entity<AppIdentityUser>(entity =>
        {
            entity.ToTable("NguoiDung", "pos");

            entity.Property(x => x.Id).HasColumnName("Id");
            entity.Property(x => x.UserName).HasColumnName("TenDangNhap").HasMaxLength(256);
            entity.Property(x => x.NormalizedUserName).HasColumnName("TenDangNhapChuanHoa").HasMaxLength(256);
            entity.Property(x => x.Email).HasColumnName("Email").HasMaxLength(256);
            entity.Property(x => x.NormalizedEmail).HasColumnName("EmailChuanHoa").HasMaxLength(256);
            entity.Property(x => x.EmailConfirmed).HasColumnName("DaXacNhanEmail").HasDefaultValue(false);
            entity.Property(x => x.PasswordHash).HasColumnName("MatKhauBam");
            entity.Property(x => x.SecurityStamp).HasColumnName("DauBaoMat");
            entity.Property(x => x.ConcurrencyStamp).HasColumnName("DauPhienBan");
            entity.Property(x => x.PhoneNumber).HasColumnName("SoDienThoai");
            entity.Property(x => x.PhoneNumberConfirmed).HasColumnName("DaXacNhanSoDienThoai").HasDefaultValue(false);
            entity.Property(x => x.TwoFactorEnabled).HasColumnName("BatXacThucHaiYeuTo").HasDefaultValue(false);
            entity.Property(x => x.LockoutEnd).HasColumnName("KhoaDen");
            entity.Property(x => x.LockoutEnabled).HasColumnName("ChoPhepKhoa").HasDefaultValue(true);
            entity.Property(x => x.AccessFailedCount).HasColumnName("SoLanDangNhapThatBai").HasDefaultValue(0);
            entity.Property(x => x.DangHoatDong).HasColumnName("DangHoatDong").HasDefaultValue(true);

            entity.HasIndex(x => x.NormalizedUserName)
                .HasDatabaseName("UqNguoiDungTenDangNhap")
                .IsUnique();

            entity.HasIndex(x => x.NormalizedEmail)
                .HasDatabaseName("IdxNguoiDungEmail");
        });

        // 2. Bảng pos."VaiTro"
        builder.Entity<AppIdentityRole>(entity =>
        {
            entity.ToTable("VaiTro", "pos");

            entity.Property(x => x.Id).HasColumnName("Id");
            entity.Property(x => x.Name).HasColumnName("Ten").HasMaxLength(256);
            entity.Property(x => x.NormalizedName).HasColumnName("TenChuanHoa").HasMaxLength(256);
            entity.Property(x => x.ConcurrencyStamp).HasColumnName("DauPhienBan");

            entity.HasIndex(x => x.NormalizedName)
                .HasDatabaseName("UqVaiTroTen")
                .IsUnique();
        });

        // 3. Bảng pos."NguoiDungVaiTro"
        builder.Entity<IdentityUserRole<Guid>>(entity =>
        {
            entity.ToTable("NguoiDungVaiTro", "pos");
            entity.Property(x => x.UserId).HasColumnName("IdNguoiDung");
            entity.Property(x => x.RoleId).HasColumnName("IdVaiTro");
        });

        // 4. Bảng pos."QuyenNguoiDung"
        builder.Entity<IdentityUserClaim<Guid>>(entity =>
        {
            entity.ToTable("QuyenNguoiDung", "pos");
            entity.Property(x => x.Id).HasColumnName("Id");
            entity.Property(x => x.UserId).HasColumnName("IdNguoiDung");
            entity.Property(x => x.ClaimType).HasColumnName("LoaiQuyen");
            entity.Property(x => x.ClaimValue).HasColumnName("GiaTriQuyen");
        });

        // 5. Bảng pos."QuyenVaiTro"
        builder.Entity<IdentityRoleClaim<Guid>>(entity =>
        {
            entity.ToTable("QuyenVaiTro", "pos");
            entity.Property(x => x.Id).HasColumnName("Id");
            entity.Property(x => x.RoleId).HasColumnName("IdVaiTro");
            entity.Property(x => x.ClaimType).HasColumnName("LoaiQuyen");
            entity.Property(x => x.ClaimValue).HasColumnName("GiaTriQuyen");
        });

        // 6. Bảng pos."DangNhapLienKet"
        builder.Entity<IdentityUserLogin<Guid>>(entity =>
        {
            entity.ToTable("DangNhapLienKet", "pos");
            entity.Property(x => x.LoginProvider).HasColumnName("NhaCungCap");
            entity.Property(x => x.ProviderKey).HasColumnName("KhoaNhaCungCap");
            entity.Property(x => x.ProviderDisplayName).HasColumnName("TenNhaCungCap");
            entity.Property(x => x.UserId).HasColumnName("IdNguoiDung");
        });

        // 7. Bảng pos."MaXacThucNguoiDung"
        builder.Entity<IdentityUserToken<Guid>>(entity =>
        {
            entity.ToTable("MaXacThucNguoiDung", "pos");
            entity.Property(x => x.UserId).HasColumnName("IdNguoiDung");
            entity.Property(x => x.LoginProvider).HasColumnName("NhaCungCap");
            entity.Property(x => x.Name).HasColumnName("Ten");
            entity.Property(x => x.Value).HasColumnName("GiaTri");
        });

        // 8. Bảng pos."HoSoNguoiDung"
        builder.Entity<HoSoNguoiDung>(entity =>
        {
            entity.ToTable("HoSoNguoiDung", "pos");
            entity.HasKey(x => x.IdNguoiDung);

            entity.Property(x => x.IdNguoiDung).HasColumnName("IdNguoiDung");
            entity.Property(x => x.HoTen).HasColumnName("HoTen").IsRequired().HasMaxLength(160);
            entity.Property(x => x.SoDienThoaiLienHe).HasColumnName("SoDienThoaiLienHe").HasMaxLength(32);
            entity.Property(x => x.AnhDaiDien).HasColumnName("AnhDaiDien");
            entity.Property(x => x.CapNhatLuc).HasColumnName("CapNhatLuc").HasDefaultValueSql("now()");

            entity.HasOne<AppIdentityUser>()
                .WithOne(u => u.HoSo)
                .HasForeignKey<HoSoNguoiDung>(x => x.IdNguoiDung)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // 9. Bảng pos."CaLamViec"
        builder.Entity<CaLamViec>(entity =>
        {
            entity.ToTable("CaLamViec", "pos");
            entity.HasKey(x => x.Id);

            entity.Property(x => x.Id).HasColumnName("Id");
            entity.Property(x => x.IdNguoiDung).HasColumnName("IdNguoiDung");
            entity.Property(x => x.TrangThai)
                .HasColumnName("TrangThai")
                .IsRequired()
                .HasMaxLength(20)
                .HasDefaultValue(ShiftStatuses.DangMo);
            entity.Property(x => x.BatDauLuc).HasColumnName("BatDauLuc").HasDefaultValueSql("now()");
            entity.Property(x => x.KetThucLuc).HasColumnName("KetThucLuc");
            entity.Property(x => x.GhiChuMoCa).HasColumnName("GhiChuMoCa");
            entity.Property(x => x.GhiChuKetCa).HasColumnName("GhiChuKetCa");

            entity.HasOne<AppIdentityUser>()
                .WithMany(u => u.DanhSachCaLamViec)
                .HasForeignKey(x => x.IdNguoiDung)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(x => x.IdNguoiDung)
                .HasDatabaseName("UqCaLamViecDangMoMoiNguoi")
                .IsUnique()
                .HasFilter($"\"TrangThai\" = '{ShiftStatuses.DangMo}'");
        });

        // 10. Bảng pos."DanhMucMon"
        builder.Entity<DanhMucMon>(entity =>
        {
            entity.ToTable("DanhMucMon", "pos");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("Id");
            entity.Property(x => x.Ma).HasColumnName("Ma").IsRequired().HasMaxLength(32);
            entity.Property(x => x.Ten).HasColumnName("Ten").IsRequired().HasMaxLength(120);
        });

        // 11. Bảng pos."Mon"
        builder.Entity<Mon>(entity =>
        {
            entity.ToTable("Mon", "pos");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("Id");
            entity.Property(x => x.IdDanhMuc).HasColumnName("IdDanhMuc");
            entity.Property(x => x.Ma).HasColumnName("Ma").IsRequired().HasMaxLength(32);
            entity.Property(x => x.Ten).HasColumnName("Ten").IsRequired().HasMaxLength(160);
            entity.Property(x => x.GiaVnd).HasColumnName("GiaVnd");
            entity.Property(x => x.DangHoatDong).HasColumnName("DangHoatDong").HasDefaultValue(true);

            entity.HasOne(x => x.DanhMuc)
                .WithMany(c => c.DanhSachMon)
                .HasForeignKey(x => x.IdDanhMuc);
        });

        // 12. Bảng pos."Ban"
        builder.Entity<Ban>(entity =>
        {
            entity.ToTable("Ban", "pos");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("Id");
            entity.Property(x => x.Ma).HasColumnName("Ma").IsRequired().HasMaxLength(32);
            entity.Property(x => x.Ten).HasColumnName("Ten").IsRequired().HasMaxLength(120);
            entity.Property(x => x.DangHoatDong).HasColumnName("DangHoatDong").HasDefaultValue(true);
        });

        // 13. Bảng pos."LuotBan"
        builder.Entity<LuotBan>(entity =>
        {
            entity.ToTable("LuotBan", "pos");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("Id");
            entity.Property(x => x.IdBan).HasColumnName("IdBan");
            entity.Property(x => x.IdNguoiMo).HasColumnName("IdNguoiMo");
            entity.Property(x => x.MoLuc).HasColumnName("MoLuc").HasDefaultValueSql("now()");
            entity.Property(x => x.IdNguoiTraBan).HasColumnName("IdNguoiTraBan");
            entity.Property(x => x.TraBanLuc).HasColumnName("TraBanLuc");

            entity.HasOne(x => x.Ban)
                .WithMany(b => b.DanhSachLuotBan)
                .HasForeignKey(x => x.IdBan);
        });

        // 14. Bảng pos."DonHang"
        builder.Entity<DonHang>(entity =>
        {
            entity.ToTable("DonHang", "pos");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("Id");
            entity.Property(x => x.IdLuotBan).HasColumnName("IdLuotBan");
            entity.Property(x => x.Ma).HasColumnName("Ma").IsRequired().HasMaxLength(40);
            entity.Property(x => x.TrangThai).HasColumnName("TrangThai").IsRequired().HasMaxLength(24);
            entity.Property(x => x.IdNguoiTao).HasColumnName("IdNguoiTao");
            entity.Property(x => x.TaoLuc).HasColumnName("TaoLuc").HasDefaultValueSql("now()");
            entity.Property(x => x.ThanhToanLuc).HasColumnName("ThanhToanLuc");

            entity.HasOne(x => x.LuotBan)
                .WithMany(l => l.DanhSachDonHang)
                .HasForeignKey(x => x.IdLuotBan);
        });

        // 15. Bảng pos."DongMon"
        builder.Entity<DongMon>(entity =>
        {
            entity.ToTable("DongMon", "pos");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("Id");
            entity.Property(x => x.IdDonHang).HasColumnName("IdDonHang");
            entity.Property(x => x.IdMon).HasColumnName("IdMon");
            entity.Property(x => x.TenMonLucBan).HasColumnName("TenMonLucBan").IsRequired().HasMaxLength(160);
            entity.Property(x => x.DonGiaLucBanVnd).HasColumnName("DonGiaLucBanVnd");
            entity.Property(x => x.SoLuong).HasColumnName("SoLuong");
            entity.Property(x => x.GhiChu).HasColumnName("GhiChu");
            entity.Property(x => x.IdNguoiGhiMon).HasColumnName("IdNguoiGhiMon");
            entity.Property(x => x.GhiMonLuc).HasColumnName("GhiMonLuc").HasDefaultValueSql("now()");

            entity.HasOne(x => x.DonHang)
                .WithMany(d => d.DanhSachDongMon)
                .HasForeignKey(x => x.IdDonHang);

            entity.HasOne(x => x.Mon)
                .WithMany()
                .HasForeignKey(x => x.IdMon);
        });

        // 16. Bảng pos."YeuCauHuyMon"
        builder.Entity<YeuCauHuyMon>(entity =>
        {
            entity.ToTable("YeuCauHuyMon", "pos");
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasColumnName("Id");
            entity.Property(x => x.IdDongMon).HasColumnName("IdDongMon");
            entity.Property(x => x.LyDoYeuCau).HasColumnName("LyDoYeuCau").IsRequired();
            entity.Property(x => x.IdNguoiYeuCau).HasColumnName("IdNguoiYeuCau");
            entity.Property(x => x.YeuCauLuc).HasColumnName("YeuCauLuc").HasDefaultValueSql("now()");
            entity.Property(x => x.TrangThai).HasColumnName("TrangThai").IsRequired().HasMaxLength(16);
            entity.Property(x => x.IdNguoiXuLy).HasColumnName("IdNguoiXuLy");
            entity.Property(x => x.XuLyLuc).HasColumnName("XuLyLuc");
            entity.Property(x => x.LyDoTuChoi).HasColumnName("LyDoTuChoi");

            entity.HasOne(x => x.DongMon)
                .WithMany(d => d.DanhSachYeuCauHuy)
                .HasForeignKey(x => x.IdDongMon);
        });
    }
}
