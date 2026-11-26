import '../../../dung_chung/dang_nhap/mo_hinh/phien_dang_nhap.dart';
import '../../../nen_tang/mang/cong_api.dart';

/// Service chuyên trách nghiệp vụ Ca làm việc (Bắt đầu ca / Kết thúc ca)
class ShiftService {
  final PosAuthApiClient apiClient;

  const ShiftService({required this.apiClient});

  /// Bắt đầu ca làm việc mới (POST /api/shifts/start)
  Future<ApiResult<ShiftModel>> startShift({String? note}) =>
      apiClient.startShift(
        note: note ?? 'Bắt đầu ca làm việc tại quầy POS',
      );

  /// Kết thúc ca làm việc hiện tại (POST /api/shifts/end)
  Future<ApiResult<ShiftModel>> endShift({String? note}) =>
      apiClient.endShift(
        note: note ?? 'Kết thúc ca làm việc tại quầy POS',
      );
}
