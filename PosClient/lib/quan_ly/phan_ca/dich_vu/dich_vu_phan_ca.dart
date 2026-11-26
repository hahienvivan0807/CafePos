import '../../../dung_chung/dang_nhap/mo_hinh/phien_dang_nhap.dart';
import '../../../nen_tang/mang/cong_api.dart';
import '../mo_hinh/du_lieu_phan_ca.dart';

class DichVuPhanCa {
  final PosAuthApiClient apiClient;

  const DichVuPhanCa({required this.apiClient});

  Future<ApiResult<List<KhungCaMau>>> layDanhSachKhungCa({
    String? tuKhoa,
    String? trangThai,
  }) async {
    final res = await apiClient.getShiftTemplatesRaw(
      search: tuKhoa,
      status: trangThai,
    );
    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }
    return ApiResult.success(
      res.data!.map(KhungCaMau.fromJson).toList(),
      message: res.message,
    );
  }

  Future<ApiResult<KhungCaMau>> taoKhungCa(DuLieuLuuKhungCa duLieu) async {
    final res = await apiClient.createShiftTemplateRaw(duLieu.toJson());
    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }
    return ApiResult.success(
      KhungCaMau.fromJson(res.data!),
      message: res.message,
      statusCode: res.statusCode,
    );
  }

  Future<ApiResult<KhungCaMau>> suaKhungCa(
    String ma,
    DuLieuLuuKhungCa duLieu,
  ) async {
    final res = await apiClient.updateShiftTemplateRaw(ma, duLieu.toJson());
    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }
    return ApiResult.success(
      KhungCaMau.fromJson(res.data!),
      message: res.message,
    );
  }

  Future<ApiResult<bool>> xoaHoacNgungKhungCa(
    String ma, {
    String? lyDo,
  }) => apiClient.deleteShiftTemplateRaw(ma, reason: lyDo);

  Future<ApiResult<LichPhanCaTuan>> layLichTuan(DateTime dauTuan) async {
    final res = await apiClient.getWeeklyScheduleRaw(
      weekStart: dinhDangIso(dauTuan),
    );
    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }
    return ApiResult.success(
      LichPhanCaTuan.fromJson(res.data!),
      message: res.message,
    );
  }

  Future<ApiResult<PhanCongCa>> ganNhanVien({
    required DateTime ngayLam,
    required String maKhungCa,
    required String idNhanVien,
    required String viTri,
    String? gioVao,
    String? gioRa,
  }) async {
    final res = await apiClient.assignStaffToShiftRaw({
      'workDate': dinhDangIso(ngayLam),
      'shiftCode': maKhungCa,
      'staffUserId': idNhanVien,
      'position': viTri,
      if (gioVao != null && gioVao.trim().isNotEmpty) 'startTime': gioVao.trim(),
      if (gioRa != null && gioRa.trim().isNotEmpty) 'endTime': gioRa.trim(),
    });
    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }
    return ApiResult.success(
      PhanCongCa.fromJson(res.data!),
      message: res.message,
      statusCode: res.statusCode,
    );
  }

  Future<ApiResult<bool>> huyPhanCong(int id, {String? lyDo}) =>
      apiClient.cancelShiftAssignmentRaw(id, reason: lyDo);

  Future<ApiResult<bool>> congBoTuan(DateTime dauTuan) =>
      apiClient.publishWeekScheduleRaw(dinhDangIso(dauTuan));

  Future<ApiResult<int>> saoChepTuanTruoc(DateTime dauTuan) =>
      apiClient.copyPreviousWeekScheduleRaw(dinhDangIso(dauTuan));

  static String dinhDangIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
