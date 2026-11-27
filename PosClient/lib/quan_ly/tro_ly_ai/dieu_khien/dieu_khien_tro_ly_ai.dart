import 'package:flutter/foundation.dart';

import '../../../nen_tang/mang/cong_api.dart';
import '../dich_vu/dich_vu_tro_ly_ai.dart';
import '../mo_hinh/du_lieu_tro_ly_ai.dart';

class DieuKhienTroLyAi extends ChangeNotifier {
  DieuKhienTroLyAi({required PosAuthApiClient apiClient})
    : _dichVu = DichVuTroLyAi(apiClient: apiClient) {
    _tinNhans.add(
      TinNhanTroLyAi(
        id: 'welcome',
        isUser: false,
        content:
            'Xin chào Quản lý! Mình là Daylight AI, trợ lý vận hành quán cà phê của bạn. Bạn có thể hỏi doanh thu theo ca, món bán chạy, kiểm tra lịch trực thiếu người hoặc nhờ tạo nhanh đề xuất khuyến mãi và phân ca nhé.',
        createdAt: DateTime.now(),
      ),
    );
  }

  final DichVuTroLyAi _dichVu;

  TrangThaiTroLyAi? trangThai;
  bool dangTaiTrangThai = false;
  bool dangGui = false;
  bool dangXacNhanForm = false;
  String? loi;
  int? doTreGanNhatMs;

  final List<TinNhanTroLyAi> _tinNhans = [];
  List<TinNhanTroLyAi> get tinNhans => List.unmodifiable(_tinNhans);

  Future<void> taiTrangThai() async {
    dangTaiTrangThai = true;
    loi = null;
    notifyListeners();

    final res = await _dichVu.layTrangThai();
    dangTaiTrangThai = false;
    if (res.isSuccess && res.data != null) {
      trangThai = res.data;
    } else {
      loi = res.message;
    }
    notifyListeners();
  }

  Future<void> guiCauHoi(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || dangGui) return;

    final lichSuGui = _tinNhans
        .where((m) => m.id != 'welcome')
        .toList(growable: false);

    _tinNhans.add(
      TinNhanTroLyAi(
        id: 'u_${DateTime.now().microsecondsSinceEpoch}',
        isUser: true,
        content: text,
        createdAt: DateTime.now(),
      ),
    );
    dangGui = true;
    loi = null;
    notifyListeners();

    final res = await _dichVu.guiTinNhan(message: text, lichSu: lichSuGui);
    dangGui = false;

    if (res.isSuccess && res.data != null) {
      final data = res.data!;
      doTreGanNhatMs = data.latencyMs;
      if (trangThai != null) {
        trangThai = TrangThaiTroLyAi(
          ollamaTrucTuyen: true,
          tenModel: data.modelUsed.isNotEmpty
              ? data.modelUsed
              : trangThai!.tenModel,
          diaChiOllama: trangThai!.diaChiOllama,
          thongBaoTrangThai: trangThai!.thongBaoTrangThai,
          danhSachModel: trangThai!.danhSachModel,
          nguCanh: data.nguCanh,
        );
      }

      _tinNhans.add(
        TinNhanTroLyAi(
          id: 'a_${DateTime.now().microsecondsSinceEpoch}',
          isUser: false,
          content: data.reply,
          createdAt: DateTime.now(),
          toolUsed: data.toolUsed,
          modelUsed: data.modelUsed,
          latencyMs: data.latencyMs,
          miniFormDraft: data.miniFormDraft,
        ),
      );
    } else {
      loi = res.message;
      _tinNhans.add(
        TinNhanTroLyAi(
          id: 'err_${DateTime.now().microsecondsSinceEpoch}',
          isUser: false,
          content: 'Không thể kết nối Daylight AI: ${res.message}',
          createdAt: DateTime.now(),
        ),
      );
    }

    notifyListeners();
  }

  void batCheDoChinhSua(String messageId) {
    final idx = _tinNhans.indexWhere((m) => m.id == messageId);
    if (idx < 0 || _tinNhans[idx].miniFormDraft == null) return;
    _tinNhans[idx] = _tinNhans[idx].copyWith(
      miniFormDraft: _tinNhans[idx].miniFormDraft!.copyWith(status: 'editing'),
    );
    notifyListeners();
  }

  void capNhatGiaTriTruong(String messageId, String fieldKey, String newValue) {
    final idx = _tinNhans.indexWhere((m) => m.id == messageId);
    if (idx < 0 || _tinNhans[idx].miniFormDraft == null) return;
    final draft = _tinNhans[idx].miniFormDraft!;
    if (draft.status == 'confirmed' || draft.status == 'cancelled') return;
    final updatedFields = draft.fields
        .map((f) => f.key == fieldKey ? f.copyWith(value: newValue) : f)
        .toList();
    _tinNhans[idx] = _tinNhans[idx].copyWith(
      miniFormDraft: draft.copyWith(
        status: 'editing',
        fields: updatedFields,
      ),
    );
    notifyListeners();
  }

  void huyBoMiniForm(String messageId) {
    final idx = _tinNhans.indexWhere((m) => m.id == messageId);
    if (idx < 0 || _tinNhans[idx].miniFormDraft == null) return;
    _tinNhans[idx] = _tinNhans[idx].copyWith(
      miniFormDraft: _tinNhans[idx].miniFormDraft!.copyWith(
        status: 'cancelled',
        resultMessage: 'Quản lý đã hủy bản nháp — không có thay đổi nào được ghi.',
      ),
    );
    notifyListeners();
  }

  Future<String?> xacNhanMiniForm(String messageId) async {
    final idx = _tinNhans.indexWhere((m) => m.id == messageId);
    if (idx < 0 || _tinNhans[idx].miniFormDraft == null || dangXacNhanForm) {
      return null;
    }

    final draft = _tinNhans[idx].miniFormDraft!;
    final values = <String, String>{
      for (final f in draft.fields) f.key: f.value.trim(),
    };

    dangXacNhanForm = true;
    loi = null;
    notifyListeners();

    final res = await _dichVu.xacNhanMiniForm(
      actionType: draft.actionType,
      values: values,
    );

    dangXacNhanForm = false;
    if (res.isSuccess && res.data != null) {
      final summary =
          (res.data!['summary'] ?? res.message).toString();
      final ctxJson = res.data!['storeContext'] as Map<String, dynamic>?;
      if (ctxJson != null && trangThai != null) {
        trangThai = TrangThaiTroLyAi(
          ollamaTrucTuyen: trangThai!.ollamaTrucTuyen,
          tenModel: trangThai!.tenModel,
          diaChiOllama: trangThai!.diaChiOllama,
          thongBaoTrangThai: trangThai!.thongBaoTrangThai,
          danhSachModel: trangThai!.danhSachModel,
          nguCanh: NguCanhCuaHangAi.fromJson(ctxJson),
        );
      }

      _tinNhans[idx] = _tinNhans[idx].copyWith(
        miniFormDraft: draft.copyWith(
          status: 'confirmed',
          resultMessage: summary,
        ),
      );
      notifyListeners();
      return summary;
    }

    loi = res.message;
    notifyListeners();
    return null;
  }
}
