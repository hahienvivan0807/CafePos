import '../../../dung_chung/dang_nhap/mo_hinh/phien_dang_nhap.dart';
import '../../../nen_tang/mang/cong_api.dart';
import '../mo_hinh/du_lieu_bao_cao.dart';

/// Service gọi 2 API Báo cáo kinh doanh & Dự báo Daylight AI (/api/manager/reports)
class DichVuBaoCao {
  final PosAuthApiClient apiClient;

  const DichVuBaoCao({required this.apiClient});

  Future<ApiResult<BaoCaoVanHanh>> layBaoCaoVanHanh({
    required DateTime tuNgay,
    required DateTime denNgay,
  }) async {
    final res = await apiClient.getRevenueAnalyticsRaw(
      fromDate: _dinhDangIso(tuNgay),
      toDate: _dinhDangIso(denNgay),
    );
    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }
    return ApiResult.success(
      BaoCaoVanHanh.fromJson(res.data!),
      message: res.message,
    );
  }

  Future<ApiResult<DuBaoDaylightAi>> layDuBaoAi({
    required DateTime tuNgay,
    required DateTime denNgay,
  }) async {
    final res = await apiClient.getAiForecastRaw(
      fromDate: _dinhDangIso(tuNgay),
      toDate: _dinhDangIso(denNgay),
    );
    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }
    return ApiResult.success(
      DuBaoDaylightAi.fromJson(res.data!),
      message: res.message,
    );
  }

  Future<ApiResult<DanhSachHoaDonCa>> layHoaDonTheoCa({
    required String maCa,
    required DateTime tuNgay,
    required DateTime denNgay,
  }) async {
    final res = await apiClient.getShiftOrdersRaw(
      slot: maCa,
      fromDate: _dinhDangIso(tuNgay),
      toDate: _dinhDangIso(denNgay),
    );
    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }
    return ApiResult.success(
      DanhSachHoaDonCa.fromJson(res.data!),
      message: res.message,
    );
  }

  Future<ApiResult<ChiTietHoaDonBaoCao>> layChiTietHoaDon(int orderId) async {
    final res = await apiClient.getOrderDetailsRaw(orderId);
    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }
    return ApiResult.success(
      ChiTietHoaDonBaoCao.fromJson(res.data!),
      message: res.message,
    );
  }

  static String _dinhDangIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
