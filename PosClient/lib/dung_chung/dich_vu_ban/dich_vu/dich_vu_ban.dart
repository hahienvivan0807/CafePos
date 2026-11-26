import '../../../nen_tang/mang/cong_api.dart';
import '../../dang_nhap/mo_hinh/phien_dang_nhap.dart';
import '../mo_hinh/du_lieu_ban.dart';

/// Service chuyên trách nghiệp vụ Sơ đồ bàn, Thực đơn, Mở bàn, Ghi món & Thanh toán VietQR
class DashboardService {
  final PosAuthApiClient apiClient;

  const DashboardService({required this.apiClient});

  /// Lấy tổng quan dành cho Quản lý (GET /api/dashboard/manager-overview)
  Future<ApiResult<DashboardOverviewModel>> getManagerOverview() =>
      apiClient.getManagerOverview();

  /// Mở bàn hoặc ghi thêm món vào bàn (POST /api/dashboard/tables/open-or-order)
  Future<ApiResult<TableCardModel>> openTableOrAddItems({
    required int tableId,
    List<OrderItemInputModel>? items,
    int? orderId,
  }) => apiClient.openTableOrAddItems(
    tableId: tableId,
    items: items,
    orderId: orderId,
  );

  /// Yêu cầu phát hành mã VietQR (POST /api/dashboard/tables/{tableId}/request-vietqr)
  Future<ApiResult<TableCardModel>> requestVietQr({
    required int tableId,
    int? orderId,
  }) => apiClient.requestVietQr(tableId: tableId, orderId: orderId);

  /// Xác nhận đơn đã thanh toán VietQR (POST /api/dashboard/tables/{tableId}/confirm-paid)
  Future<ApiResult<TableCardModel>> confirmVietQrPaid({
    required int tableId,
    int? orderId,
  }) => apiClient.confirmVietQrPaid(tableId: tableId, orderId: orderId);

  /// Trả bàn (POST /api/dashboard/tables/{tableId}/close-table)
  Future<ApiResult<TableCardModel>> closeTableSession({required int tableId}) =>
      apiClient.closeTableSession(tableId: tableId);
}
