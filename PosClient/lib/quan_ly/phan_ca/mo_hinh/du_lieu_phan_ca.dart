class KhungCaMau {
  final String ma;
  final String tenCa;
  final String gioBatDau; // HH:mm
  final String gioKetThuc; // HH:mm
  final bool quaDem;
  final int nghiGiuaCaPhut;
  final int dinhBienPhaChe;
  final int dinhBienThuNgan;
  final int dinhBienPhucVu;
  final bool dangApDung;
  final String? ghiChuBanGiao;
  final int thuTu;
  final double thoiLuongGio;
  final bool daCoLichSu;

  const KhungCaMau({
    required this.ma,
    required this.tenCa,
    required this.gioBatDau,
    required this.gioKetThuc,
    required this.quaDem,
    required this.nghiGiuaCaPhut,
    required this.dinhBienPhaChe,
    required this.dinhBienThuNgan,
    required this.dinhBienPhucVu,
    required this.dangApDung,
    this.ghiChuBanGiao,
    required this.thuTu,
    required this.thoiLuongGio,
    required this.daCoLichSu,
  });

  int get tongDinhBien => dinhBienPhaChe + dinhBienThuNgan + dinhBienPhucVu;

  factory KhungCaMau.fromJson(Map<String, dynamic> json) {
    return KhungCaMau(
      ma: (json['code'] ?? '').toString(),
      tenCa: (json['name'] ?? '').toString(),
      gioBatDau: (json['startTime'] ?? '07:00').toString(),
      gioKetThuc: (json['endTime'] ?? '11:00').toString(),
      quaDem: json['isOvernight'] == true,
      nghiGiuaCaPhut: (json['breakMinutes'] as num?)?.toInt() ?? 0,
      dinhBienPhaChe: (json['baristaQuota'] as num?)?.toInt() ?? 0,
      dinhBienThuNgan: (json['cashierQuota'] as num?)?.toInt() ?? 0,
      dinhBienPhucVu: (json['floorQuota'] as num?)?.toInt() ?? 0,
      dangApDung: json['isActive'] != false,
      ghiChuBanGiao: json['handoverNote']?.toString(),
      thuTu: (json['sortOrder'] as num?)?.toInt() ?? 0,
      thoiLuongGio: (json['durationHours'] as num?)?.toDouble() ?? 0.0,
      daCoLichSu: json['hasUsageHistory'] == true,
    );
  }
}

class DuLieuLuuKhungCa {
  final String ma;
  final String tenCa;
  final String gioBatDau;
  final String gioKetThuc;
  final bool quaDem;
  final int nghiGiuaCaPhut;
  final int dinhBienPhaChe;
  final int dinhBienThuNgan;
  final int dinhBienPhucVu;
  final bool dangApDung;
  final String? ghiChuBanGiao;

  const DuLieuLuuKhungCa({
    required this.ma,
    required this.tenCa,
    required this.gioBatDau,
    required this.gioKetThuc,
    this.quaDem = false,
    this.nghiGiuaCaPhut = 0,
    this.dinhBienPhaChe = 1,
    this.dinhBienThuNgan = 1,
    this.dinhBienPhucVu = 1,
    this.dangApDung = true,
    this.ghiChuBanGiao,
  });

  Map<String, dynamic> toJson() => {
    'code': ma,
    'name': tenCa,
    'startTime': gioBatDau,
    'endTime': gioKetThuc,
    'isOvernight': quaDem,
    'breakMinutes': nghiGiuaCaPhut,
    'baristaQuota': dinhBienPhaChe,
    'cashierQuota': dinhBienThuNgan,
    'floorQuota': dinhBienPhucVu,
    'isActive': dangApDung,
    'handoverNote': ghiChuBanGiao,
  };
}

class PhanCongCa {
  final int id;
  final String ngayLam; // yyyy-MM-dd
  final String maKhungCa;
  final String idNhanVien;
  final String maNhanVien;
  final String tenNhanVien;
  final String viTri;
  final String nhanViTri;
  final String gioVao;
  final String gioRa;
  final double thoiLuongGio;
  final String trangThaiTuan;
  final String trangThai;

  const PhanCongCa({
    required this.id,
    required this.ngayLam,
    required this.maKhungCa,
    required this.idNhanVien,
    required this.maNhanVien,
    required this.tenNhanVien,
    required this.viTri,
    required this.nhanViTri,
    required this.gioVao,
    required this.gioRa,
    required this.thoiLuongGio,
    required this.trangThaiTuan,
    required this.trangThai,
  });

  factory PhanCongCa.fromJson(Map<String, dynamic> json) {
    return PhanCongCa(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ngayLam: (json['workDate'] ?? '').toString(),
      maKhungCa: (json['shiftCode'] ?? '').toString(),
      idNhanVien: (json['staffUserId'] ?? '').toString(),
      maNhanVien: (json['staffCode'] ?? '').toString(),
      tenNhanVien: (json['staffName'] ?? '').toString(),
      viTri: (json['position'] ?? 'PhaChe').toString(),
      nhanViTri: (json['positionLabel'] ?? 'Pha chế').toString(),
      gioVao: (json['startTime'] ?? '').toString(),
      gioRa: (json['endTime'] ?? '').toString(),
      thoiLuongGio: (json['durationHours'] as num?)?.toDouble() ?? 0.0,
      trangThaiTuan: (json['weekStatus'] ?? 'Nhap').toString(),
      trangThai: (json['status'] ?? 'HoatDong').toString(),
    );
  }
}

class NhanVienSanSang {
  final String id;
  final String maNhanVien;
  final String hoTen;
  final String vaiTro;

  const NhanVienSanSang({
    required this.id,
    required this.maNhanVien,
    required this.hoTen,
    required this.vaiTro,
  });

  factory NhanVienSanSang.fromJson(Map<String, dynamic> json) {
    return NhanVienSanSang(
      id: (json['userId'] ?? '').toString(),
      maNhanVien: (json['staffCode'] ?? '').toString(),
      hoTen: (json['fullName'] ?? '').toString(),
      vaiTro: (json['role'] ?? 'Staff').toString(),
    );
  }
}

class LichPhanCaTuan {
  final String dauTuan; // yyyy-MM-dd
  final String cuoiTuan; // yyyy-MM-dd
  final String trangThaiTuan; // Nhap | DaCongBo
  final double tongGioTuan;
  final int soCaThieuNhanSu;
  final List<KhungCaMau> khungCa;
  final List<PhanCongCa> danhSachPhanCong;
  final List<NhanVienSanSang> nhanVienSanSang;

  const LichPhanCaTuan({
    required this.dauTuan,
    required this.cuoiTuan,
    required this.trangThaiTuan,
    required this.tongGioTuan,
    required this.soCaThieuNhanSu,
    required this.khungCa,
    required this.danhSachPhanCong,
    required this.nhanVienSanSang,
  });

  factory LichPhanCaTuan.fromJson(Map<String, dynamic> json) {
    return LichPhanCaTuan(
      dauTuan: (json['weekStart'] ?? '').toString(),
      cuoiTuan: (json['weekEnd'] ?? '').toString(),
      trangThaiTuan: (json['weekStatus'] ?? 'Nhap').toString(),
      tongGioTuan: (json['totalPlannedHours'] as num?)?.toDouble() ?? 0.0,
      soCaThieuNhanSu: (json['understaffedSlotsCount'] as num?)?.toInt() ?? 0,
      khungCa: (json['templates'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(KhungCaMau.fromJson)
          .toList(),
      danhSachPhanCong: (json['assignments'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PhanCongCa.fromJson)
          .toList(),
      nhanVienSanSang: (json['activeStaff'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(NhanVienSanSang.fromJson)
          .toList(),
    );
  }
}
