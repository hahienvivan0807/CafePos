import 'package:flutter/material.dart';
import '../../../dung_chung/dang_nhap/mo_hinh/phien_dang_nhap.dart';
import '../dich_vu/dich_vu_phan_ca.dart';
import '../mo_hinh/du_lieu_phan_ca.dart';

class DieuKhienPhanCa extends ChangeNotifier {
  final DichVuPhanCa dichVu;

  int tabDangChon = 0; // 0: Lịch phân ca (Màn 32), 1: Khung ca (Màn 28)

  late DateTime ngayDauTuan;
  String locNhanVienId = '';
  String locViTri = '';

  final TextEditingController oTimKiemKhungCa = TextEditingController();
  String locTrangThaiKhungCa = 'all'; // all | active | inactive

  bool dangTaiLich = false;
  bool dangTaiKhungCa = false;
  bool dangThaoTac = false;
  String? loiLich;
  String? loiKhungCa;

  LichPhanCaTuan? lichTuan;
  List<KhungCaMau> _danhSachKhungCaGoc = [];

  DieuKhienPhanCa({required this.dichVu}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = (today.weekday - DateTime.monday) % 7;
    ngayDauTuan = today.subtract(Duration(days: diff));
    oTimKiemKhungCa.addListener(notifyListeners);
  }

  List<KhungCaMau> get danhSachKhungCaHienThi {
    final q = oTimKiemKhungCa.text.trim().toLowerCase();
    return _danhSachKhungCaGoc.where((k) {
      if (locTrangThaiKhungCa == 'active' && !k.dangApDung) return false;
      if (locTrangThaiKhungCa == 'inactive' && k.dangApDung) return false;
      if (q.isNotEmpty) {
        if (!k.ma.toLowerCase().contains(q) &&
            !k.tenCa.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get tongKhungCa => _danhSachKhungCaGoc.length;
  int get soKhungCaDangApDung =>
      _danhSachKhungCaGoc.where((k) => k.dangApDung).length;

  List<PhanCongCa> phanCongChoO(DateTime ngay, String maKhungCa) {
    final iso = DichVuPhanCa.dinhDangIso(ngay);
    final ds = lichTuan?.danhSachPhanCong ?? const <PhanCongCa>[];
    return ds.where((p) {
      if (p.ngayLam != iso || p.maKhungCa != maKhungCa) return false;
      if (locNhanVienId.isNotEmpty && p.idNhanVien != locNhanVienId) {
        return false;
      }
      if (locViTri.isNotEmpty && p.viTri != locViTri) return false;
      return true;
    }).toList();
  }

  Future<void> khoiTao() async {
    await Future.wait([taiLichTuan(), taiDanhSachKhungCa()]);
  }

  void chonTab(int idx) {
    if (tabDangChon == idx) return;
    tabDangChon = idx;
    notifyListeners();
  }

  void datLocNhanVien(String id) {
    locNhanVienId = id;
    notifyListeners();
  }

  void datLocViTri(String viTri) {
    locViTri = viTri;
    notifyListeners();
  }

  void datLocTrangThaiKhungCa(String val) {
    locTrangThaiKhungCa = val;
    notifyListeners();
  }

  Future<void> chuyenTuan(int offsetWeeks) async {
    if (offsetWeeks == 0) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final diff = (today.weekday - DateTime.monday) % 7;
      ngayDauTuan = today.subtract(Duration(days: diff));
    } else {
      ngayDauTuan = ngayDauTuan.add(Duration(days: offsetWeeks * 7));
    }
    notifyListeners();
    await taiLichTuan();
  }

  Future<void> taiLichTuan() async {
    dangTaiLich = true;
    loiLich = null;
    notifyListeners();

    final res = await dichVu.layLichTuan(ngayDauTuan);
    dangTaiLich = false;
    if (!res.isSuccess || res.data == null) {
      loiLich = res.message;
    } else {
      lichTuan = res.data;
    }
    notifyListeners();
  }

  Future<void> taiDanhSachKhungCa() async {
    dangTaiKhungCa = true;
    loiKhungCa = null;
    notifyListeners();

    final res = await dichVu.layDanhSachKhungCa();
    dangTaiKhungCa = false;
    if (!res.isSuccess || res.data == null) {
      loiKhungCa = res.message;
    } else {
      _danhSachKhungCaGoc = res.data!;
    }
    notifyListeners();
  }

  Future<ApiResult<KhungCaMau>> taoKhungCa(DuLieuLuuKhungCa duLieu) async {
    dangThaoTac = true;
    notifyListeners();
    final res = await dichVu.taoKhungCa(duLieu);
    dangThaoTac = false;
    if (res.isSuccess) {
      await Future.wait([taiDanhSachKhungCa(), taiLichTuan()]);
    } else {
      notifyListeners();
    }
    return res;
  }

  Future<ApiResult<KhungCaMau>> suaKhungCa(
    String ma,
    DuLieuLuuKhungCa duLieu,
  ) async {
    dangThaoTac = true;
    notifyListeners();
    final res = await dichVu.suaKhungCa(ma, duLieu);
    dangThaoTac = false;
    if (res.isSuccess) {
      await Future.wait([taiDanhSachKhungCa(), taiLichTuan()]);
    } else {
      notifyListeners();
    }
    return res;
  }

  Future<ApiResult<bool>> xoaHoacNgungKhungCa(
    String ma, {
    String? lyDo,
  }) async {
    dangThaoTac = true;
    notifyListeners();
    final res = await dichVu.xoaHoacNgungKhungCa(ma, lyDo: lyDo);
    dangThaoTac = false;
    if (res.isSuccess) {
      await Future.wait([taiDanhSachKhungCa(), taiLichTuan()]);
    } else {
      notifyListeners();
    }
    return res;
  }

  Future<ApiResult<PhanCongCa>> ganNhanVien({
    required DateTime ngayLam,
    required String maKhungCa,
    required String idNhanVien,
    required String viTri,
    String? gioVao,
    String? gioRa,
  }) async {
    dangThaoTac = true;
    notifyListeners();
    final res = await dichVu.ganNhanVien(
      ngayLam: ngayLam,
      maKhungCa: maKhungCa,
      idNhanVien: idNhanVien,
      viTri: viTri,
      gioVao: gioVao,
      gioRa: gioRa,
    );
    dangThaoTac = false;
    if (res.isSuccess) {
      await taiLichTuan();
    } else {
      notifyListeners();
    }
    return res;
  }

  Future<ApiResult<bool>> huyPhanCong(int id, {String? lyDo}) async {
    dangThaoTac = true;
    notifyListeners();
    final res = await dichVu.huyPhanCong(id, lyDo: lyDo);
    dangThaoTac = false;
    if (res.isSuccess) {
      await taiLichTuan();
    } else {
      notifyListeners();
    }
    return res;
  }

  Future<ApiResult<bool>> congBoTuan() async {
    dangThaoTac = true;
    notifyListeners();
    final res = await dichVu.congBoTuan(ngayDauTuan);
    dangThaoTac = false;
    if (res.isSuccess) {
      await taiLichTuan();
    } else {
      notifyListeners();
    }
    return res;
  }

  Future<ApiResult<int>> saoChepTuanTruoc() async {
    dangThaoTac = true;
    notifyListeners();
    final res = await dichVu.saoChepTuanTruoc(ngayDauTuan);
    dangThaoTac = false;
    if (res.isSuccess) {
      await taiLichTuan();
    } else {
      notifyListeners();
    }
    return res;
  }

  @override
  void dispose() {
    oTimKiemKhungCa.removeListener(notifyListeners);
    oTimKiemKhungCa.dispose();
    super.dispose();
  }
}
