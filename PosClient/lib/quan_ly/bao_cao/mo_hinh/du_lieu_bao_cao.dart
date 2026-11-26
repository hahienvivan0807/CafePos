class KhungGioDoanhThu {
  final String maKhung;
  final String nhanHienThi;
  final int giaTriDonVnd;
  final int thucThuVnd;
  final int soDon;

  const KhungGioDoanhThu({
    required this.maKhung,
    required this.nhanHienThi,
    required this.giaTriDonVnd,
    required this.thucThuVnd,
    required this.soDon,
  });

  factory KhungGioDoanhThu.fromJson(Map<String, dynamic> json) {
    return KhungGioDoanhThu(
      maKhung: (json['slotKey'] ?? '').toString(),
      nhanHienThi: (json['label'] ?? '').toString(),
      giaTriDonVnd: (json['orderValueVnd'] as num?)?.toInt() ?? 0,
      thucThuVnd: (json['collectedVnd'] as num?)?.toInt() ?? 0,
      soDon: (json['orderCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class CoCauThanhToan {
  final String maPhuongThuc;
  final String nhanHienThi;
  final int soTienVnd;
  final double tyLePhanTram;

  const CoCauThanhToan({
    required this.maPhuongThuc,
    required this.nhanHienThi,
    required this.soTienVnd,
    required this.tyLePhanTram,
  });

  factory CoCauThanhToan.fromJson(Map<String, dynamic> json) {
    return CoCauThanhToan(
      maPhuongThuc: (json['methodKey'] ?? '').toString(),
      nhanHienThi: (json['label'] ?? '').toString(),
      soTienVnd: (json['amountVnd'] as num?)?.toInt() ?? 0,
      tyLePhanTram: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MonBanChayBaoCao {
  final int thuHang;
  final int idMon;
  final String maMon;
  final String tenMon;
  final String danhMuc;
  final int soLuongBan;
  final int doanhSoVnd;
  final double tyTrongPhanTram;

  const MonBanChayBaoCao({
    required this.thuHang,
    required this.idMon,
    required this.maMon,
    required this.tenMon,
    required this.danhMuc,
    required this.soLuongBan,
    required this.doanhSoVnd,
    required this.tyTrongPhanTram,
  });

  factory MonBanChayBaoCao.fromJson(Map<String, dynamic> json) {
    return MonBanChayBaoCao(
      thuHang: (json['rank'] as num?)?.toInt() ?? 0,
      idMon: (json['menuItemId'] as num?)?.toInt() ?? 0,
      maMon: (json['itemCode'] ?? '').toString(),
      tenMon: (json['itemName'] ?? '').toString(),
      danhMuc: (json['categoryName'] ?? '').toString(),
      soLuongBan: (json['quantitySold'] as num?)?.toInt() ?? 0,
      doanhSoVnd: (json['revenueVnd'] as num?)?.toInt() ?? 0,
      tyTrongPhanTram: (json['contributionPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BaoCaoVanHanh {
  final String tuNgay;
  final String denNgay;
  final int tongGiaTriDonVnd;
  final int thucTeDaThuVnd;
  final int tongLuotBan;
  final int luotBanHoanTat;
  final double tyLeHoanTatBan;
  final int tongDonHang;
  final int donDaThanhToan;
  final int donChoQr;
  final int donDangMo;
  final String? monBanChayNhat;
  final int soLuongMonBanChayNhat;
  final List<KhungGioDoanhThu> khungGio;
  final List<CoCauThanhToan> coCauThanhToan;
  final List<MonBanChayBaoCao> topMon;
  final List<String> danhMuc;

  const BaoCaoVanHanh({
    required this.tuNgay,
    required this.denNgay,
    required this.tongGiaTriDonVnd,
    required this.thucTeDaThuVnd,
    required this.tongLuotBan,
    required this.luotBanHoanTat,
    required this.tyLeHoanTatBan,
    required this.tongDonHang,
    required this.donDaThanhToan,
    required this.donChoQr,
    required this.donDangMo,
    required this.monBanChayNhat,
    required this.soLuongMonBanChayNhat,
    required this.khungGio,
    required this.coCauThanhToan,
    required this.topMon,
    required this.danhMuc,
  });

  factory BaoCaoVanHanh.fromJson(Map<String, dynamic> json) {
    return BaoCaoVanHanh(
      tuNgay: (json['fromDate'] ?? '').toString(),
      denNgay: (json['toDate'] ?? '').toString(),
      tongGiaTriDonVnd: (json['totalOrderValueVnd'] as num?)?.toInt() ?? 0,
      thucTeDaThuVnd: (json['actualCollectedAmountVnd'] as num?)?.toInt() ?? 0,
      tongLuotBan: (json['totalTableSessions'] as num?)?.toInt() ?? 0,
      luotBanHoanTat: (json['completedTableSessions'] as num?)?.toInt() ?? 0,
      tyLeHoanTatBan: (json['tableCompletionRate'] as num?)?.toDouble() ?? 0.0,
      tongDonHang: (json['totalOrders'] as num?)?.toInt() ?? 0,
      donDaThanhToan: (json['paidOrders'] as num?)?.toInt() ?? 0,
      donChoQr: (json['awaitingPaymentOrders'] as num?)?.toInt() ?? 0,
      donDangMo: (json['openOrders'] as num?)?.toInt() ?? 0,
      monBanChayNhat: json['topBestSellerName']?.toString(),
      soLuongMonBanChayNhat:
          (json['topBestSellerQuantity'] as num?)?.toInt() ?? 0,
      khungGio: (json['timeSlots'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(KhungGioDoanhThu.fromJson)
          .toList(),
      coCauThanhToan: (json['paymentBreakdown'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CoCauThanhToan.fromJson)
          .toList(),
      topMon: (json['topItems'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MonBanChayBaoCao.fromJson)
          .toList(),
      danhMuc: (json['categories'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class DiemDuBao {
  final String ngay;
  final String nhanNgay;
  final int? doanhThuThucTeVnd;
  final int? doanhThuDuBaoVnd;
  final int? soDonThucTe;
  final int? soDonDuBao;

  const DiemDuBao({
    required this.ngay,
    required this.nhanNgay,
    this.doanhThuThucTeVnd,
    this.doanhThuDuBaoVnd,
    this.soDonThucTe,
    this.soDonDuBao,
  });

  factory DiemDuBao.fromJson(Map<String, dynamic> json) {
    return DiemDuBao(
      ngay: (json['date'] ?? '').toString(),
      nhanNgay: (json['label'] ?? '').toString(),
      doanhThuThucTeVnd: (json['actualRevenueVnd'] as num?)?.toInt(),
      doanhThuDuBaoVnd: (json['forecastRevenueVnd'] as num?)?.toInt(),
      soDonThucTe: (json['actualOrderCount'] as num?)?.toInt(),
      soDonDuBao: (json['forecastOrderCount'] as num?)?.toInt(),
    );
  }
}

class GoiYNguyenLieu {
  final String ten;
  final String danhMuc;
  final String tonKhoHienTai;
  final String dinhMucGoiY;
  final String mucUuTien;

  const GoiYNguyenLieu({
    required this.ten,
    required this.danhMuc,
    required this.tonKhoHienTai,
    required this.dinhMucGoiY,
    required this.mucUuTien,
  });

  factory GoiYNguyenLieu.fromJson(Map<String, dynamic> json) {
    return GoiYNguyenLieu(
      ten: (json['name'] ?? '').toString(),
      danhMuc: (json['category'] ?? '').toString(),
      tonKhoHienTai: (json['currentStockLabel'] ?? '').toString(),
      dinhMucGoiY: (json['suggestedRestockLabel'] ?? '').toString(),
      mucUuTien: (json['priorityLabel'] ?? '').toString(),
    );
  }
}

class DuBaoDaylightAi {
  final String tuNgay;
  final String denNgay;
  final bool duDuLieu;
  final int soNgayLichSu;
  final int soNgayToiThieu;
  final double doPhuPhanTram;
  final String tieuDeTrangThai;
  final String moTaTrangThai;
  final int doanhThuDuBao7NgayVnd;
  final double xuHuongPhanTram;
  final String khungGioCaoDiem;
  final List<DiemDuBao> chuoiDuLieu;
  final List<GoiYNguyenLieu> goiYNguyenLieu;

  const DuBaoDaylightAi({
    required this.tuNgay,
    required this.denNgay,
    required this.duDuLieu,
    required this.soNgayLichSu,
    required this.soNgayToiThieu,
    required this.doPhuPhanTram,
    required this.tieuDeTrangThai,
    required this.moTaTrangThai,
    required this.doanhThuDuBao7NgayVnd,
    required this.xuHuongPhanTram,
    required this.khungGioCaoDiem,
    required this.chuoiDuLieu,
    required this.goiYNguyenLieu,
  });

  factory DuBaoDaylightAi.fromJson(Map<String, dynamic> json) {
    return DuBaoDaylightAi(
      tuNgay: (json['fromDate'] ?? '').toString(),
      denNgay: (json['toDate'] ?? '').toString(),
      duDuLieu: json['hasEnoughData'] == true,
      soNgayLichSu: (json['historicalDaysAvailable'] as num?)?.toInt() ?? 0,
      soNgayToiThieu: (json['minimumDaysRequired'] as num?)?.toInt() ?? 7,
      doPhuPhanTram: (json['dataCoveragePercent'] as num?)?.toDouble() ?? 0.0,
      tieuDeTrangThai: (json['statusTitle'] ?? '').toString(),
      moTaTrangThai: (json['statusDescription'] ?? '').toString(),
      doanhThuDuBao7NgayVnd:
          (json['projectedNext7DaysRevenueVnd'] as num?)?.toInt() ?? 0,
      xuHuongPhanTram: (json['trendPercent'] as num?)?.toDouble() ?? 0.0,
      khungGioCaoDiem: (json['peakTimeWindow'] ?? '').toString(),
      chuoiDuLieu: (json['series'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DiemDuBao.fromJson)
          .toList(),
      goiYNguyenLieu: (json['ingredientSuggestions'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GoiYNguyenLieu.fromJson)
          .toList(),
    );
  }
}

class HoaDonTrongCa {
  final int idDonHang;
  final String maDonHang;
  final String maBan;
  final String tenBan;
  final String tenNhanVien;
  final String trangThai;
  final DateTime taoLuc;
  final DateTime? thanhToanLuc;
  final int tongSoMon;
  final int tongTienVnd;

  const HoaDonTrongCa({
    required this.idDonHang,
    required this.maDonHang,
    required this.maBan,
    required this.tenBan,
    required this.tenNhanVien,
    required this.trangThai,
    required this.taoLuc,
    this.thanhToanLuc,
    required this.tongSoMon,
    required this.tongTienVnd,
  });

  factory HoaDonTrongCa.fromJson(Map<String, dynamic> json) {
    return HoaDonTrongCa(
      idDonHang: (json['orderId'] as num?)?.toInt() ?? 0,
      maDonHang: (json['orderCode'] ?? '').toString(),
      maBan: (json['tableCode'] ?? '').toString(),
      tenBan: (json['tableName'] ?? '').toString(),
      tenNhanVien: (json['staffName'] ?? '').toString(),
      trangThai: (json['status'] ?? '').toString(),
      taoLuc:
          DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      thanhToanLuc: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())?.toLocal()
          : null,
      tongSoMon: (json['totalItemsCount'] as num?)?.toInt() ?? 0,
      tongTienVnd: (json['totalAmountVnd'] as num?)?.toInt() ?? 0,
    );
  }
}

class DanhSachHoaDonCa {
  final String maCa;
  final String tenCa;
  final int tongGiaTriVnd;
  final int tongDaThuVnd;
  final List<HoaDonTrongCa> danhSachHoaDon;

  const DanhSachHoaDonCa({
    required this.maCa,
    required this.tenCa,
    required this.tongGiaTriVnd,
    required this.tongDaThuVnd,
    required this.danhSachHoaDon,
  });

  factory DanhSachHoaDonCa.fromJson(Map<String, dynamic> json) {
    return DanhSachHoaDonCa(
      maCa: (json['shiftCode'] ?? '').toString(),
      tenCa: (json['shiftLabel'] ?? '').toString(),
      tongGiaTriVnd: (json['totalOrderValueVnd'] as num?)?.toInt() ?? 0,
      tongDaThuVnd: (json['totalCollectedVnd'] as num?)?.toInt() ?? 0,
      danhSachHoaDon: (json['orders'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HoaDonTrongCa.fromJson)
          .toList(),
    );
  }
}

class DongMonChiTietHoaDon {
  final String tenMon;
  final int donGiaVnd;
  final int soLuong;
  final int thanhTienVnd;
  final String? ghiChu;
  final String? trangThaiHuy;

  const DongMonChiTietHoaDon({
    required this.tenMon,
    required this.donGiaVnd,
    required this.soLuong,
    required this.thanhTienVnd,
    this.ghiChu,
    this.trangThaiHuy,
  });

  factory DongMonChiTietHoaDon.fromJson(Map<String, dynamic> json) {
    return DongMonChiTietHoaDon(
      tenMon: (json['itemName'] ?? '').toString(),
      donGiaVnd: (json['unitPriceVnd'] as num?)?.toInt() ?? 0,
      soLuong: (json['quantity'] as num?)?.toInt() ?? 0,
      thanhTienVnd: (json['lineTotalVnd'] as num?)?.toInt() ?? 0,
      ghiChu: json['note']?.toString(),
      trangThaiHuy: json['cancelStatus']?.toString(),
    );
  }
}

class ChiTietHoaDonBaoCao {
  final int idDonHang;
  final String maDonHang;
  final String maBan;
  final String tenBan;
  final String tenNhanVien;
  final String trangThai;
  final DateTime taoLuc;
  final DateTime? thanhToanLuc;
  final int tongTienVnd;
  final int daThanhToanVnd;
  final int conLaiVnd;
  final List<DongMonChiTietHoaDon> danhSachMon;

  const ChiTietHoaDonBaoCao({
    required this.idDonHang,
    required this.maDonHang,
    required this.maBan,
    required this.tenBan,
    required this.tenNhanVien,
    required this.trangThai,
    required this.taoLuc,
    this.thanhToanLuc,
    required this.tongTienVnd,
    required this.daThanhToanVnd,
    required this.conLaiVnd,
    required this.danhSachMon,
  });

  factory ChiTietHoaDonBaoCao.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>? ?? const {};
    return ChiTietHoaDonBaoCao(
      idDonHang: (order['id'] as num?)?.toInt() ?? 0,
      maDonHang: (order['code'] ?? '').toString(),
      maBan: (json['tableCode'] ?? '').toString(),
      tenBan: (json['tableName'] ?? '').toString(),
      tenNhanVien: (json['staffName'] ?? 'Nhân viên').toString(),
      trangThai: (order['status'] ?? '').toString(),
      taoLuc:
          DateTime.tryParse((order['createdAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      thanhToanLuc: order['paidAt'] != null
          ? DateTime.tryParse(order['paidAt'].toString())?.toLocal()
          : null,
      tongTienVnd: (order['totalAmountVnd'] as num?)?.toInt() ?? 0,
      daThanhToanVnd: (json['paidAmountVnd'] as num?)?.toInt() ?? 0,
      conLaiVnd: (json['remainingAmountVnd'] as num?)?.toInt() ?? 0,
      danhSachMon: (order['lines'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DongMonChiTietHoaDon.fromJson)
          .toList(),
    );
  }
}
