class NguCanhCuaHangAi {
  const NguCanhCuaHangAi({
    required this.doanhThuHomNayVnd,
    required this.giaTriDonHomNayVnd,
    required this.donChoXuLy,
    required this.caThieuDinhBien,
    required this.dongBoLuc,
  });

  final int doanhThuHomNayVnd;
  final int giaTriDonHomNayVnd;
  final int donChoXuLy;
  final int caThieuDinhBien;
  final DateTime? dongBoLuc;

  factory NguCanhCuaHangAi.fromJson(Map<String, dynamic> json) {
    return NguCanhCuaHangAi(
      doanhThuHomNayVnd: (json['todayRevenueVnd'] as num?)?.toInt() ?? 0,
      giaTriDonHomNayVnd: (json['todayOrderValueVnd'] as num?)?.toInt() ?? 0,
      donChoXuLy: (json['pendingOrdersCount'] as num?)?.toInt() ?? 0,
      caThieuDinhBien: (json['understaffedSlotsCount'] as num?)?.toInt() ?? 0,
      dongBoLuc: DateTime.tryParse((json['syncedAt'] ?? '').toString()),
    );
  }
}

class TrangThaiTroLyAi {
  const TrangThaiTroLyAi({
    required this.ollamaTrucTuyen,
    required this.tenModel,
    required this.diaChiOllama,
    required this.thongBaoTrangThai,
    required this.danhSachModel,
    required this.nguCanh,
  });

  final bool ollamaTrucTuyen;
  final String tenModel;
  final String diaChiOllama;
  final String thongBaoTrangThai;
  final List<String> danhSachModel;
  final NguCanhCuaHangAi nguCanh;

  factory TrangThaiTroLyAi.fromJson(Map<String, dynamic> json) {
    final models = (json['installedModels'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    final ctxJson =
        (json['storeContext'] as Map<String, dynamic>?) ?? const {};
    return TrangThaiTroLyAi(
      ollamaTrucTuyen: json['isOllamaOnline'] == true,
      tenModel: (json['modelName'] ?? 'qwen2.5:3b').toString(),
      diaChiOllama: (json['ollamaBaseUrl'] ?? 'http://127.0.0.1:11434')
          .toString(),
      thongBaoTrangThai: (json['statusMessage'] ?? '').toString(),
      danhSachModel: models,
      nguCanh: NguCanhCuaHangAi.fromJson(ctxJson),
    );
  }
}

class TruongMiniFormAi {
  const TruongMiniFormAi({
    required this.key,
    required this.label,
    required this.value,
    required this.inputType,
    required this.options,
    required this.placeholder,
    required this.isRequired,
  });

  final String key;
  final String label;
  final String value;
  final String inputType; // "text" | "number" | "select" | "date"
  final List<String> options;
  final String placeholder;
  final bool isRequired;

  TruongMiniFormAi copyWith({String? value}) {
    return TruongMiniFormAi(
      key: key,
      label: label,
      value: value ?? this.value,
      inputType: inputType,
      options: options,
      placeholder: placeholder,
      isRequired: isRequired,
    );
  }

  factory TruongMiniFormAi.fromJson(Map<String, dynamic> json) {
    return TruongMiniFormAi(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      inputType: (json['inputType'] ?? 'text').toString(),
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      placeholder: (json['placeholder'] ?? '').toString(),
      isRequired: json['isRequired'] != false,
    );
  }
}

class BanNhapMiniFormAi {
  const BanNhapMiniFormAi({
    required this.draftId,
    required this.actionType,
    required this.title,
    required this.summary,
    required this.status,
    required this.fields,
    this.resultMessage,
  });

  final String draftId;
  final String actionType;
  final String title;
  final String summary;
  final String status; // "pending" | "editing" | "confirmed" | "cancelled"
  final List<TruongMiniFormAi> fields;
  final String? resultMessage;

  BanNhapMiniFormAi copyWith({
    String? status,
    List<TruongMiniFormAi>? fields,
    String? resultMessage,
  }) {
    return BanNhapMiniFormAi(
      draftId: draftId,
      actionType: actionType,
      title: title,
      summary: summary,
      status: status ?? this.status,
      fields: fields ?? this.fields,
      resultMessage: resultMessage ?? this.resultMessage,
    );
  }

  factory BanNhapMiniFormAi.fromJson(Map<String, dynamic> json) {
    final fields = (json['fields'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TruongMiniFormAi.fromJson)
        .toList();
    return BanNhapMiniFormAi(
      draftId: (json['draftId'] ?? '').toString(),
      actionType: (json['actionType'] ?? '').toString(),
      title: (json['title'] ?? 'Bản nháp Mini-Form').toString(),
      summary: (json['summary'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      fields: fields,
    );
  }
}

class TinNhanTroLyAi {
  const TinNhanTroLyAi({
    required this.id,
    required this.isUser,
    required this.content,
    required this.createdAt,
    this.toolUsed,
    this.modelUsed,
    this.latencyMs,
    this.miniFormDraft,
  });

  final String id;
  final bool isUser;
  final String content;
  final DateTime createdAt;
  final String? toolUsed;
  final String? modelUsed;
  final int? latencyMs;
  final BanNhapMiniFormAi? miniFormDraft;

  TinNhanTroLyAi copyWith({BanNhapMiniFormAi? miniFormDraft}) {
    return TinNhanTroLyAi(
      id: id,
      isUser: isUser,
      content: content,
      createdAt: createdAt,
      toolUsed: toolUsed,
      modelUsed: modelUsed,
      latencyMs: latencyMs,
      miniFormDraft: miniFormDraft ?? this.miniFormDraft,
    );
  }
}

class KetQuaChatAi {
  const KetQuaChatAi({
    required this.reply,
    required this.toolUsed,
    required this.modelUsed,
    required this.latencyMs,
    required this.miniFormDraft,
    required this.nguCanh,
  });

  final String reply;
  final String? toolUsed;
  final String modelUsed;
  final int latencyMs;
  final BanNhapMiniFormAi? miniFormDraft;
  final NguCanhCuaHangAi nguCanh;

  factory KetQuaChatAi.fromJson(Map<String, dynamic> json) {
    final draftJson = json['miniFormDraft'] as Map<String, dynamic>?;
    final ctxJson =
        (json['storeContext'] as Map<String, dynamic>?) ?? const {};
    return KetQuaChatAi(
      reply: (json['reply'] ?? '').toString(),
      toolUsed: json['toolUsed']?.toString(),
      modelUsed: (json['modelUsed'] ?? '').toString(),
      latencyMs: (json['latencyMs'] as num?)?.toInt() ?? 0,
      miniFormDraft: draftJson != null
          ? BanNhapMiniFormAi.fromJson(draftJson)
          : null,
      nguCanh: NguCanhCuaHangAi.fromJson(ctxJson),
    );
  }
}
