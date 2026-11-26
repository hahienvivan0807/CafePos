using CafePos.Application.Entities;
using Microsoft.AspNetCore.Identity;

namespace CafePos.Infrastructure.Identity;

/// <summary>
/// Thực thể Tài khoản người dùng tích hợp ASP.NET Core Identity (ánh xạ bảng pos."NguoiDung")
/// </summary>
public class AppIdentityUser : IdentityUser<Guid>
{
    public bool DangHoatDong { get; set; } = true;

    public HoSoNguoiDung? HoSo { get; set; }
    public ICollection<CaLamViec> DanhSachCaLamViec { get; set; } = new List<CaLamViec>();
}

/// <summary>
/// Thực thể Vai trò người dùng tích hợp ASP.NET Core Identity (ánh xạ bảng pos."VaiTro")
/// </summary>
public class AppIdentityRole : IdentityRole<Guid>
{
}
