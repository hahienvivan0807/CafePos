import 'package:flutter/material.dart';
import '../dich_vu/dich_vu_bao_cao.dart';
import '../mo_hinh/du_lieu_bao_cao.dart';

enum KyBaoCao { homNay, bayNgayQua, thangNay, tuyChon }

/// Controller quản lý trạng thái cho cả 2 tab: Báo cáo kết quả vận hành & Dự báo (Daylight AI)
class DieuKhienBaoCao extends ChangeNotifier {
  final DichVuBaoCao dichVu;

  int tabDangChon = 0; // 0: Báo cáo vận hành, 1: Dự báo AI
  KyBaoCao kyBaoCao = KyBaoCao.bayNgayQua;

  late DateTime tuNgayBaoCao;
  late DateTime denNgayBaoCao;

  late DateTime tuNgayDuBao;
  late DateTime denNgayDuBao;

  String danhMucLoc = '';

  bool dangTaiBaoCao = false;
  bool dangTaiDuBao = false;
  String? loiBaoCao;
  String? loiDuBao;

  BaoCaoVanHanh? baoCao;
  DuBaoDaylightAi? duBao;

  DieuKhienBaoCao({required this.dichVu, int initialTabIndex = 0}) {
    tabDangChon = initialTabIndex;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    denNgayBaoCao = today;
    tuNgayBaoCao = today.subtract(const Duration(days: 6));

    denNgayDuBao = today;
    tuNgayDuBao = today.subtract(const Duration(days: 13));
  }

  List<MonBanChayBaoCao> get topMonLoc {
    final ds = baoCao?.topMon ?? const [];
    if (danhMucLoc.isEmpty) return ds;
    return ds.where((m) => m.danhMuc == danhMucLoc).toList();
  }

  Future<void> khoiTao() async {
    await Future.wait([taiBaoCao(), taiDuBao()]);
  }

  void chonTab(int index) {
    if (tabDangChon == index) return;
    tabDangChon = index;
    notifyListeners();
  }

  void chonDanhMucLoc(String danhMuc) {
    danhMucLoc = danhMuc;
    notifyListeners();
  }

  Future<void> chonKyBaoCao(KyBaoCao ky) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    kyBaoCao = ky;
    switch (ky) {
      case KyBaoCao.homNay:
        tuNgayBaoCao = today;
        denNgayBaoCao = today;
        break;
      case KyBaoCao.bayNgayQua:
        tuNgayBaoCao = today.subtract(const Duration(days: 6));
        denNgayBaoCao = today;
        break;
      case KyBaoCao.thangNay:
        tuNgayBaoCao = DateTime(today.year, today.month, 1);
        denNgayBaoCao = today;
        break;
      case KyBaoCao.tuyChon:
        break;
    }
    notifyListeners();
    await taiBaoCao();
  }

  Future<void> datKhoangNgayBaoCao(DateTime from, DateTime to) async {
    kyBaoCao = KyBaoCao.tuyChon;
    tuNgayBaoCao = DateTime(from.year, from.month, from.day);
    denNgayBaoCao = DateTime(to.year, to.month, to.day);
    notifyListeners();
    await taiBaoCao();
  }

  Future<void> datKhoangNgayDuBao(DateTime from, DateTime to) async {
    tuNgayDuBao = DateTime(from.year, from.month, from.day);
    denNgayDuBao = DateTime(to.year, to.month, to.day);
    notifyListeners();
    await taiDuBao();
  }

  Future<void> taiBaoCao() async {
    dangTaiBaoCao = true;
    loiBaoCao = null;
    notifyListeners();

    final res = await dichVu.layBaoCaoVanHanh(
      tuNgay: tuNgayBaoCao,
      denNgay: denNgayBaoCao,
    );
    dangTaiBaoCao = false;
    if (!res.isSuccess || res.data == null) {
      loiBaoCao = res.message;
      notifyListeners();
      return;
    }

    baoCao = res.data;
    if (danhMucLoc.isNotEmpty && !(baoCao?.danhMuc.contains(danhMucLoc) ?? false)) {
      danhMucLoc = '';
    }
    notifyListeners();
  }

  Future<void> taiDuBao() async {
    dangTaiDuBao = true;
    loiDuBao = null;
    notifyListeners();

    final res = await dichVu.layDuBaoAi(
      tuNgay: tuNgayDuBao,
      denNgay: denNgayDuBao,
    );
    dangTaiDuBao = false;
    if (!res.isSuccess || res.data == null) {
      loiDuBao = res.message;
      notifyListeners();
      return;
    }

    duBao = res.data;
    notifyListeners();
  }

  Future<void> lamMoiTatCa() async {
    await Future.wait([taiBaoCao(), taiDuBao()]);
  }
}
