namespace CafePos.Application.Entities;

/// <summary>
/// Thực thể Hồ sơ người dùng (ánh xạ bảng pos."HoSoNguoiDung" trong database cafe_pos)
/// </summary>
public class HoSoNguoiDung
{
    public Guid IdNguoiDung { get; set; }
    public string HoTen { get; set; } = string.Empty;
    public string? SoDienThoaiLienHe { get; set; }
    public string? AnhDaiDien { get; set; }
    public DateTimeOffset CapNhatLuc { get; set; } = DateTimeOffset.UtcNow;
}

/// <summary>
/// Thực thể Ca làm việc (ánh xạ bảng pos."CaLamViec" trong database cafe_pos)
/// </summary>
public class CaLamViec
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid IdNguoiDung { get; set; }
    public string TrangThai { get; set; } = Constants.ShiftStatuses.DangMo;
    public DateTimeOffset BatDauLuc { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? KetThucLuc { get; set; }
    public string? GhiChuMoCa { get; set; }
    public string? GhiChuKetCa { get; set; }
}

/// <summary>
/// Thực thể Danh mục món (ánh xạ bảng pos."DanhMucMon")
/// </summary>
public class DanhMucMon
{
    public long Id { get; set; }
    public string Ma { get; set; } = string.Empty;
    public string Ten { get; set; } = string.Empty;

    public ICollection<Mon> DanhSachMon { get; set; } = new List<Mon>();
}

/// <summary>
/// Thực thể Món trong menu (ánh xạ bảng pos."Mon")
/// </summary>
public class Mon
{
    public long Id { get; set; }
    public long IdDanhMuc { get; set; }
    public string Ma { get; set; } = string.Empty;
    public string Ten { get; set; } = string.Empty;
    public long GiaVnd { get; set; }
    public bool DangHoatDong { get; set; } = true;

    public DanhMucMon? DanhMuc { get; set; }
}

/// <summary>
/// Thực thể Bàn phục vụ (ánh xạ bảng pos."Ban")
/// </summary>
public class Ban
{
    public long Id { get; set; }
    public string Ma { get; set; } = string.Empty;
    public string Ten { get; set; } = string.Empty;
    public bool DangHoatDong { get; set; } = true;

    public ICollection<LuotBan> DanhSachLuotBan { get; set; } = new List<LuotBan>();
}

/// <summary>
/// Thực thể Lượt sử dụng bàn (ánh xạ bảng pos."LuotBan")
/// Ràng buộc UqLuotMoMoiBan: mỗi bàn có tối đa 1 lượt đang mở (TraBanLuc IS NULL).
/// </summary>
public class LuotBan
{
    public long Id { get; set; }
    public long IdBan { get; set; }
    public Guid IdNguoiMo { get; set; }
    public DateTimeOffset MoLuc { get; set; } = DateTimeOffset.UtcNow;
    public Guid? IdNguoiTraBan { get; set; }
    public DateTimeOffset? TraBanLuc { get; set; }

    public Ban? Ban { get; set; }
    public ICollection<DonHang> DanhSachDonHang { get; set; } = new List<DonHang>();
}

/// <summary>
/// Danh mục các khung ca làm việc chuẩn của quán (ánh xạ bảng pos."KhungCaLam")
/// </summary>
public class KhungCaLam
{
    public string Ma { get; set; } = string.Empty; // CA_SANG | CA_TRUA | CA_CHIEU | CA_TOI ...
    public string TenCa { get; set; } = string.Empty;
    public TimeOnly GioBatDau { get; set; }
    public TimeOnly GioKetThuc { get; set; }
    public bool QuaDem { get; set; }
    public int NghiGiuaCaPhut { get; set; }
    public int DinhBienPhaChe { get; set; } = 1;
    public int DinhBienThuNgan { get; set; } = 1;
    public int DinhBienPhucVu { get; set; } = 1;
    public bool DangApDung { get; set; } = true;
    public string? GhiChuBanGiao { get; set; }
    public int ThuTu { get; set; }
    public DateTimeOffset CapNhatLuc { get; set; } = DateTimeOffset.UtcNow;

    public ICollection<DonHang> DanhSachDonHang { get; set; } = new List<DonHang>();
    public ICollection<PhanCaNhanVien> DanhSachPhanCa { get; set; } = new List<PhanCaNhanVien>();
}

/// <summary>
/// Bảng trung gian phân công nhân viên vào từng khung ca theo ngày (ánh xạ bảng pos."PhanCaNhanVien")
/// </summary>
public class PhanCaNhanVien
{
    public long Id { get; set; }
    public DateOnly NgayLam { get; set; }
    public string MaKhungCa { get; set; } = string.Empty;
    public Guid IdNguoiDung { get; set; }
    public string ViTri { get; set; } = "PhaChe"; // PhaChe | ThuNgan | PhucVu | TruongCa
    public TimeOnly GioVao { get; set; }
    public TimeOnly GioRa { get; set; }
    public string TrangThaiTuan { get; set; } = "Nhap"; // Nhap | DaCongBo
    public string TrangThai { get; set; } = "HoatDong"; // HoatDong | DaHuy
    public string? LyDoHuy { get; set; }
    public DateTimeOffset TaoLuc { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset CapNhatLuc { get; set; } = DateTimeOffset.UtcNow;

    public KhungCaLam? KhungCa { get; set; }
}

/// <summary>
/// Thực thể Đơn hàng trong một lượt bàn (ánh xạ bảng pos."DonHang")
/// TrangThai: 'open' | 'awaiting_payment' | 'paid' | 'cancelled'
/// </summary>
public class DonHang
{
    public long Id { get; set; }
    public long IdLuotBan { get; set; }
    public string Ma { get; set; } = string.Empty;
    public string TrangThai { get; set; } = Constants.OrderStatuses.Open;
    public Guid IdNguoiTao { get; set; }
    public string? MaKhungCa { get; set; }
    public DateTimeOffset TaoLuc { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? ThanhToanLuc { get; set; }

    public LuotBan? LuotBan { get; set; }
    public KhungCaLam? KhungCa { get; set; }
    public ICollection<DongMon> DanhSachDongMon { get; set; } = new List<DongMon>();
    public ICollection<YeuCauQrThanhToan> DanhSachYeuCauQr { get; set; } = new List<YeuCauQrThanhToan>();
    public ICollection<GiaoDichThanhToan> DanhSachGiaoDich { get; set; } = new List<GiaoDichThanhToan>();
}

/// <summary>
/// Thực thể Dòng món đã ghi trong đơn hàng (ánh xạ bảng pos."DongMon")
/// </summary>
public class DongMon
{
    public long Id { get; set; }
    public long IdDonHang { get; set; }
    public long IdMon { get; set; }
    public string TenMonLucBan { get; set; } = string.Empty;
    public long DonGiaLucBanVnd { get; set; }
    public int SoLuong { get; set; }
    public string? GhiChu { get; set; }
    public Guid IdNguoiGhiMon { get; set; }
    public DateTimeOffset GhiMonLuc { get; set; } = DateTimeOffset.UtcNow;

    public DonHang? DonHang { get; set; }
    public Mon? Mon { get; set; }
    public ICollection<YeuCauHuyMon> DanhSachYeuCauHuy { get; set; } = new List<YeuCauHuyMon>();
}

/// <summary>
/// Thực thể Yêu cầu hủy món (ánh xạ bảng pos."YeuCauHuyMon")
/// </summary>
public class YeuCauHuyMon
{
    public long Id { get; set; }
    public long IdDongMon { get; set; }
    public string LyDoYeuCau { get; set; } = string.Empty;
    public Guid IdNguoiYeuCau { get; set; }
    public DateTimeOffset YeuCauLuc { get; set; } = DateTimeOffset.UtcNow;
    public string TrangThai { get; set; } = "pending";
    public Guid? IdNguoiXuLy { get; set; }
    public DateTimeOffset? XuLyLuc { get; set; }
    public string? LyDoTuChoi { get; set; }

    public DongMon? DongMon { get; set; }
}

/// <summary>
/// Phiên mã VietQR đã sinh cho đơn hàng (ánh xạ bảng pos."YeuCauQrThanhToan").
/// Khi khách gọi thêm món (65k -> 90k), bản cũ chuyển 'DaThayThe' nhưng vẫn giữ MaThamChieu để đối soát khoản đến muộn.
/// </summary>
public class YeuCauQrThanhToan
{
    public long Id { get; set; }
    public long IdDonHang { get; set; }
    public int PhienBan { get; set; } = 1;
    public string MaThamChieu { get; set; } = string.Empty; // VD: POS1042V1
    public long SoTienVnd { get; set; }
    public string MaNganHang { get; set; } = "MB";
    public string SoTaiKhoan { get; set; } = string.Empty;
    public string TenTaiKhoan { get; set; } = string.Empty;
    public string DuongDanAnhQr { get; set; } = string.Empty;
    public string TrangThai { get; set; } = "DangCho"; // DangCho | DaThayThe | DaThuDu | DaHuy
    public DateTimeOffset TaoLuc { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? CapNhatLuc { get; set; }

    public DonHang? DonHang { get; set; }
}

/// <summary>
/// Giao dịch thanh toán thực tế đã nhận (VietQR hoặc Tiền mặt) — ánh xạ bảng pos."GiaoDichThanhToan".
/// Ràng buộc UNIQUE trên MaGiaoDichNganHang để đảm bảo Idempotency (chống cộng tiền 2 lần).
/// </summary>
public class GiaoDichThanhToan
{
    public long Id { get; set; }
    public long IdDonHang { get; set; }
    public long? IdYeuCauQr { get; set; }
    public string PhuongThuc { get; set; } = "vietqr"; // vietqr | cash
    public string? MaGiaoDichNganHang { get; set; } // UNIQUE khi khác NULL
    public string? CongThanhToan { get; set; } // MBBank | VietinBank | DemoWebhook | Cash
    public string? MaThamChieuKhop { get; set; }
    public string? NoiDungChuyenKhoan { get; set; }
    public long SoTienVnd { get; set; }
    public bool CanDoiSoat { get; set; }
    public string TrangThaiDoiSoat { get; set; } = "KhongCan"; // KhongCan | ChoXuLy | DaXuLy
    public string? GhiChuDoiSoat { get; set; }
    public Guid? IdNguoiXacNhan { get; set; }
    public DateTimeOffset GhiNhanLuc { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? DoiSoatLuc { get; set; }

    public DonHang? DonHang { get; set; }
    public YeuCauQrThanhToan? YeuCauQr { get; set; }
}
