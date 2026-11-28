import '../../../dung_chung/dang_nhap/mo_hinh/phien_dang_nhap.dart';
import '../../../nen_tang/mang/cong_api.dart';
import '../mo_hinh/ho_so_nhan_vien.dart';

/// Service chuyên trách CRUD nhân sự cho Quản lý (/api/manager/staff)
class DichVuNhanVien {
  final PosAuthApiClient apiClient;

  const DichVuNhanVien({required this.apiClient});

  Future<ApiResult<List<HoSoNhanVien>>> layDanhSach({
    String? tuKhoa,
    String? vaiTro,
    String? trangThai,
  }) async {
    final res = await apiClient.getStaffListRaw(
      search: tuKhoa,
      role: vaiTro,
      status: trangThai,
    );
    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }

    final list = res.data!.map(HoSoNhanVien.fromJson).toList();
    return ApiResult.success(list, message: res.message);
  }

  Future<ApiResult<HoSoNhanVien>> themNhanVien(
    DuLieuThemNhanVien duLieu,
  ) async {
    final res = await apiClient.createStaffRaw(
      staffCode: duLieu.maNhanVien.isEmpty ? null : duLieu.maNhanVien,
      fullName: duLieu.hoTen,
      phoneNumber: duLieu.soDienThoai,
      username: duLieu.tenDangNhap,
      password: duLieu.matKhau,
      role: duLieu.vaiTro,
      isActive: duLieu.trangThai == 'dang-hoat-dong',
    );

    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }

    return ApiResult.success(
      HoSoNhanVien.fromJson(res.data!),
      message: res.message,
      statusCode: res.statusCode,
    );
  }

  Future<ApiResult<HoSoNhanVien>> suaNhanVien({
    required String staffUserId,
    required DuLieuSuaNhanVien duLieu,
  }) async {
    final res = await apiClient.updateStaffRaw(
      staffUserId: staffUserId,
      fullName: duLieu.hoTen,
      phoneNumber: duLieu.soDienThoai,
      role: duLieu.vaiTro,
      isActive: duLieu.trangThai == 'dang-hoat-dong',
    );

    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }

    return ApiResult.success(
      HoSoNhanVien.fromJson(res.data!),
      message: res.message,
    );
  }

  Future<ApiResult<bool>> xoaNhanVien(String staffUserId) =>
      apiClient.deleteStaffRaw(staffUserId: staffUserId);

  Future<ApiResult<bool>> datLaiMatKhau({
    required String staffUserId,
    required String matKhauMoi,
    required String xacNhanMatKhau,
  }) => apiClient.resetStaffPasswordRaw(
    staffUserId: staffUserId,
    newPassword: matKhauMoi,
    confirmPassword: xacNhanMatKhau,
  );
}
