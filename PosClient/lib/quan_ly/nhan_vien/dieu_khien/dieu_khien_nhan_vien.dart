import 'package:flutter/material.dart';
import '../../../dung_chung/dang_nhap/mo_hinh/phien_dang_nhap.dart';
import '../dich_vu/dich_vu_nhan_vien.dart';
import '../mo_hinh/ho_so_nhan_vien.dart';

/// Controller quản lý bộ lọc, tải dữ liệu thật và CRUD nhân sự (Thêm / Sửa / Xóa)
class DieuKhienNhanVien extends ChangeNotifier {
  final DichVuNhanVien dichVu;
  final TextEditingController oTimKiem = TextEditingController();

  String boLocVaiTro = ''; // '' | 'nhan-vien' | 'quan-ly'
  String boLocTrangThai = ''; // '' | 'dang-hoat-dong' | 'da-khoa'

  bool dangTai = false;
  bool dangThaoTac = false;
  String? thongBaoLoi;

  List<HoSoNhanVien> _danhSachGoc = [];

  DieuKhienNhanVien({required this.dichVu}) {
    oTimKiem.addListener(notifyListeners);
  }

  List<HoSoNhanVien> get danhSachHienThi {
    final tuKhoa = oTimKiem.text.trim().toLowerCase();
    return _danhSachGoc.where((nv) {
      if (boLocVaiTro.isNotEmpty && nv.vaiTro != boLocVaiTro) {
        return false;
      }
      if (boLocTrangThai.isNotEmpty && nv.trangThai != boLocTrangThai) {
        return false;
      }
      if (tuKhoa.isNotEmpty) {
        final khopTen = nv.hoTen.toLowerCase().contains(tuKhoa);
        final khopMa = nv.maNhanVien.toLowerCase().contains(tuKhoa);
        final khopUser = nv.tenDangNhap.toLowerCase().contains(tuKhoa);
        if (!khopTen && !khopMa && !khopUser) return false;
      }
      return true;
    }).toList();
  }

  int get tongSoNhanSu => _danhSachGoc.length;

  Future<void> taiDanhSach() async {
    dangTai = true;
    thongBaoLoi = null;
    notifyListeners();

    final res = await dichVu.layDanhSach();
    dangTai = false;
    if (!res.isSuccess || res.data == null) {
      thongBaoLoi = res.message;
      notifyListeners();
      return;
    }

    _danhSachGoc = res.data!;
    notifyListeners();
  }

  Future<ApiResult<HoSoNhanVien>> themMoi(DuLieuThemNhanVien duLieu) async {
    dangThaoTac = true;
    notifyListeners();

    final res = await dichVu.themNhanVien(duLieu);
    dangThaoTac = false;

    if (res.isSuccess) {
      await taiDanhSach();
    } else {
      notifyListeners();
    }
    return res;
  }

  Future<ApiResult<HoSoNhanVien>> capNhat({
    required String staffUserId,
    required DuLieuSuaNhanVien duLieu,
  }) async {
    dangThaoTac = true;
    notifyListeners();

    final res = await dichVu.suaNhanVien(
      staffUserId: staffUserId,
      duLieu: duLieu,
    );
    dangThaoTac = false;

    if (res.isSuccess) {
      await taiDanhSach();
    } else {
      notifyListeners();
    }
    return res;
  }

  Future<ApiResult<bool>> xoa(String staffUserId) async {
    dangThaoTac = true;
    notifyListeners();

    final res = await dichVu.xoaNhanVien(staffUserId);
    dangThaoTac = false;

    // Kể cả trường hợp 409 (chuyển sang Đã khóa do có lịch sử) cũng tải lại bảng để phản ánh DB mới
    if (res.isSuccess || res.errorCode == 'STAFF_HAS_HISTORY_LOCKED') {
      await taiDanhSach();
    } else {
      notifyListeners();
    }
    return res;
  }

  Future<ApiResult<bool>> datLaiMatKhau({
    required String staffUserId,
    required String matKhauMoi,
    required String xacNhanMatKhau,
  }) async {
    dangThaoTac = true;
    notifyListeners();

    final res = await dichVu.datLaiMatKhau(
      staffUserId: staffUserId,
      matKhauMoi: matKhauMoi,
      xacNhanMatKhau: xacNhanMatKhau,
    );
    dangThaoTac = false;
    notifyListeners();
    return res;
  }

  void datBoLocVaiTro(String giaTri) {
    if (boLocVaiTro == giaTri) return;
    boLocVaiTro = giaTri;
    notifyListeners();
  }

  void datBoLocTrangThai(String giaTri) {
    if (boLocTrangThai == giaTri) return;
    boLocTrangThai = giaTri;
    notifyListeners();
  }

  Future<void> lamMoi() async {
    oTimKiem.clear();
    boLocVaiTro = '';
    boLocTrangThai = '';
    await taiDanhSach();
  }

  @override
  void dispose() {
    oTimKiem.removeListener(notifyListeners);
    oTimKiem.dispose();
    super.dispose();
  }
}
