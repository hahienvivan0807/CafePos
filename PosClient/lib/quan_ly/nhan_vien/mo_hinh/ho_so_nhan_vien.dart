/// Mô hình hồ sơ nhân sự hiển thị trên Màn 24 & Modal 25/26
class HoSoNhanVien {
  final String id;
  final String maNhanVien;
  final String hoTen;
  final String soDienThoai;
  final String tenDangNhap;
  final String vaiTro; // 'nhan-vien' | 'quan-ly'
  final String trangThai; // 'dang-hoat-dong' | 'da-khoa'

  const HoSoNhanVien({
    required this.id,
    required this.maNhanVien,
    required this.hoTen,
    required this.soDienThoai,
    required this.tenDangNhap,
    required this.vaiTro,
    required this.trangThai,
  });

  String get tenVaiTroHienThi =>
      vaiTro == 'quan-ly' ? 'Quản lý' : 'Nhân viên';

  String get tenTrangThaiHienThi =>
      trangThai == 'da-khoa' ? 'Đã khóa' : 'Đang hoạt động';

  HoSoNhanVien copyWith({
    String? hoTen,
    String? soDienThoai,
    String? vaiTro,
    String? trangThai,
  }) {
    return HoSoNhanVien(
      id: id,
      maNhanVien: maNhanVien,
      hoTen: hoTen ?? this.hoTen,
      soDienThoai: soDienThoai ?? this.soDienThoai,
      tenDangNhap: tenDangNhap,
      vaiTro: vaiTro ?? this.vaiTro,
      trangThai: trangThai ?? this.trangThai,
    );
  }

  factory HoSoNhanVien.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['role'] ?? 'Staff').toString().toLowerCase();
    final isManager = rawRole == 'manager' || rawRole == 'quan-ly';
    final isActive = json['isActive'] != false;

    return HoSoNhanVien(
      id: (json['id'] ?? '').toString(),
      maNhanVien: (json['staffCode'] ?? '').toString(),
      hoTen: (json['fullName'] ?? '').toString(),
      soDienThoai: (json['phoneNumber'] ?? '').toString(),
      tenDangNhap: (json['username'] ?? '').toString(),
      vaiTro: isManager ? 'quan-ly' : 'nhan-vien',
      trangThai: isActive ? 'dang-hoat-dong' : 'da-khoa',
    );
  }
}

/// Dữ liệu đầu vào khi bấm "Thêm nhân viên" ở Modal 25
class DuLieuThemNhanVien {
  final String maNhanVien;
  final String hoTen;
  final String soDienThoai;
  final String tenDangNhap;
  final String vaiTro;
  final String trangThai;

  const DuLieuThemNhanVien({
    required this.maNhanVien,
    required this.hoTen,
    required this.soDienThoai,
    required this.tenDangNhap,
    required this.vaiTro,
    required this.trangThai,
  });
}

/// Dữ liệu đầu vào khi bấm "Lưu thay đổi" ở Modal 26
class DuLieuSuaNhanVien {
  final String hoTen;
  final String soDienThoai;
  final String vaiTro;
  final String trangThai;

  const DuLieuSuaNhanVien({
    required this.hoTen,
    required this.soDienThoai,
    required this.vaiTro,
    required this.trangThai,
  });
}
