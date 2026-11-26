import '../../../dung_chung/dang_nhap/mo_hinh/phien_dang_nhap.dart';
import '../../../nen_tang/mang/cong_api.dart';
import '../mo_hinh/du_lieu_tro_ly_ai.dart';

class DichVuTroLyAi {
  DichVuTroLyAi({required PosAuthApiClient apiClient}) : _api = apiClient;

  final PosAuthApiClient _api;

  Future<ApiResult<TrangThaiTroLyAi>> layTrangThai() async {
    final res = await _api.getAiAssistantStatusRaw();
    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }
    return ApiResult.success(
      TrangThaiTroLyAi.fromJson(res.data!),
      message: res.message,
    );
  }

  Future<ApiResult<KetQuaChatAi>> guiTinNhan({
    required String message,
    required List<TinNhanTroLyAi> lichSu,
  }) async {
    final historyPayload = lichSu
        .map(
          (m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();

    final res = await _api.sendAiChatMessageRaw({
      'message': message,
      'history': historyPayload,
    });

    if (!res.isSuccess || res.data == null) {
      return ApiResult.failure(
        res.message,
        errorCode: res.errorCode,
        statusCode: res.statusCode,
      );
    }

    return ApiResult.success(
      KetQuaChatAi.fromJson(res.data!),
      message: res.message,
    );
  }

  Future<ApiResult<Map<String, dynamic>>> xacNhanMiniForm({
    required String actionType,
    required Map<String, String> values,
  }) async {
    return _api.confirmAiMiniFormRaw({
      'actionType': actionType,
      'values': values,
    });
  }
}
