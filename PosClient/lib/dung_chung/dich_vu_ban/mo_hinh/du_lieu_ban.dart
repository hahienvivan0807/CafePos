class MenuCategoryModel {
  final int id;
  final String code;
  final String name;
  final int itemCount;

  const MenuCategoryModel({
    required this.id,
    required this.code,
    required this.name,
    required this.itemCount,
  });

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) {
    return MenuCategoryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class MenuItemModel {
  final int id;
  final int categoryId;
  final String categoryCode;
  final String categoryName;
  final String code;
  final String name;
  final int priceVnd;
  final bool isActive;

  const MenuItemModel({
    required this.id,
    required this.categoryId,
    required this.categoryCode,
    required this.categoryName,
    required this.code,
    required this.name,
    required this.priceVnd,
    required this.isActive,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryCode: (json['categoryCode'] ?? '').toString(),
      categoryName: (json['categoryName'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      priceVnd: (json['priceVnd'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] == true,
    );
  }
}

class OrderLineModel {
  final int id;
  final int menuItemId;
  final String itemName;
  final int unitPriceVnd;
  final int quantity;
  final int lineTotalVnd;
  final String? note;
  final DateTime createdAt;
  final String? cancelStatus;

  const OrderLineModel({
    required this.id,
    required this.menuItemId,
    required this.itemName,
    required this.unitPriceVnd,
    required this.quantity,
    required this.lineTotalVnd,
    this.note,
    required this.createdAt,
    this.cancelStatus,
  });

  factory OrderLineModel.fromJson(Map<String, dynamic> json) {
    return OrderLineModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      menuItemId: (json['menuItemId'] as num?)?.toInt() ?? 0,
      itemName: (json['itemName'] ?? '').toString(),
      unitPriceVnd: (json['unitPriceVnd'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      lineTotalVnd: (json['lineTotalVnd'] as num?)?.toInt() ?? 0,
      note: json['note']?.toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      cancelStatus: json['cancelStatus']?.toString(),
    );
  }
}

class OrderDetailModel {
  final int id;
  final String code;
  final String displayLabel;
  final String status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final int totalAmountVnd;
  final int totalItemsCount;
  final bool isAddOnOrder;
  final List<OrderLineModel> lines;

  const OrderDetailModel({
    required this.id,
    required this.code,
    required this.displayLabel,
    required this.status,
    required this.createdAt,
    this.paidAt,
    required this.totalAmountVnd,
    required this.totalItemsCount,
    required this.isAddOnOrder,
    required this.lines,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List? ?? const [];
    return OrderDetailModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: (json['code'] ?? '').toString(),
      displayLabel: (json['displayLabel'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString())?.toLocal()
          : null,
      totalAmountVnd: (json['totalAmountVnd'] as num?)?.toInt() ?? 0,
      totalItemsCount: (json['totalItemsCount'] as num?)?.toInt() ?? 0,
      isAddOnOrder: json['isAddOnOrder'] == true,
      lines: rawLines
          .whereType<Map<String, dynamic>>()
          .map(OrderLineModel.fromJson)
          .toList(),
    );
  }
}

class TableSessionDetailModel {
  final int sessionId;
  final int tableId;
  final String tableCode;
  final String tableName;
  final DateTime openedAt;
  final int seatedMinutes;
  final int totalAllOrdersVnd;
  final int paidAmountVnd;
  final int remainingAmountVnd;
  final int? activeUnpaidOrderId;
  final String? activeUnpaidOrderCode;
  final String? activeUnpaidOrderStatus;
  final bool canCloseTable;
  final List<OrderDetailModel> orders;

  const TableSessionDetailModel({
    required this.sessionId,
    required this.tableId,
    required this.tableCode,
    required this.tableName,
    required this.openedAt,
    required this.seatedMinutes,
    required this.totalAllOrdersVnd,
    required this.paidAmountVnd,
    required this.remainingAmountVnd,
    this.activeUnpaidOrderId,
    this.activeUnpaidOrderCode,
    this.activeUnpaidOrderStatus,
    required this.canCloseTable,
    required this.orders,
  });

  factory TableSessionDetailModel.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'] as List? ?? const [];
    return TableSessionDetailModel(
      sessionId: (json['sessionId'] as num?)?.toInt() ?? 0,
      tableId: (json['tableId'] as num?)?.toInt() ?? 0,
      tableCode: (json['tableCode'] ?? '').toString(),
      tableName: (json['tableName'] ?? '').toString(),
      openedAt:
          DateTime.tryParse((json['openedAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      seatedMinutes: (json['seatedMinutes'] as num?)?.toInt() ?? 0,
      totalAllOrdersVnd: (json['totalAllOrdersVnd'] as num?)?.toInt() ?? 0,
      paidAmountVnd: (json['paidAmountVnd'] as num?)?.toInt() ?? 0,
      remainingAmountVnd: (json['remainingAmountVnd'] as num?)?.toInt() ?? 0,
      activeUnpaidOrderId: (json['activeUnpaidOrderId'] as num?)?.toInt(),
      activeUnpaidOrderCode: json['activeUnpaidOrderCode']?.toString(),
      activeUnpaidOrderStatus: json['activeUnpaidOrderStatus']?.toString(),
      canCloseTable: json['canCloseTable'] == true,
      orders: rawOrders
          .whereType<Map<String, dynamic>>()
          .map(OrderDetailModel.fromJson)
          .toList(),
    );
  }
}

class TableCardModel {
  final int tableId;
  final String tableCode;
  final String tableName;
  final String areaName;
  final String visualStatus;
  final String badgeText;
  final int displayAmountVnd;
  final int totalItemsCount;
  final int? seatedMinutes;
  final int? activeSessionId;
  final String? activeOrderLabel;
  final String? activeOrderStatus;
  final TableSessionDetailModel? sessionDetail;

  const TableCardModel({
    required this.tableId,
    required this.tableCode,
    required this.tableName,
    required this.areaName,
    required this.visualStatus,
    required this.badgeText,
    required this.displayAmountVnd,
    required this.totalItemsCount,
    this.seatedMinutes,
    this.activeSessionId,
    this.activeOrderLabel,
    this.activeOrderStatus,
    this.sessionDetail,
  });

  factory TableCardModel.fromJson(Map<String, dynamic> json) {
    final sessionMap = json['sessionDetail'] as Map<String, dynamic>?;
    return TableCardModel(
      tableId: (json['tableId'] as num?)?.toInt() ?? 0,
      tableCode: (json['tableCode'] ?? '').toString(),
      tableName: (json['tableName'] ?? '').toString(),
      areaName: (json['areaName'] ?? '').toString(),
      visualStatus: (json['visualStatus'] ?? 'EMPTY').toString(),
      badgeText: (json['badgeText'] ?? '').toString(),
      displayAmountVnd: (json['displayAmountVnd'] as num?)?.toInt() ?? 0,
      totalItemsCount: (json['totalItemsCount'] as num?)?.toInt() ?? 0,
      seatedMinutes: (json['seatedMinutes'] as num?)?.toInt(),
      activeSessionId: (json['activeSessionId'] as num?)?.toInt(),
      activeOrderLabel: json['activeOrderLabel']?.toString(),
      activeOrderStatus: json['activeOrderStatus']?.toString(),
      sessionDetail: sessionMap != null
          ? TableSessionDetailModel.fromJson(sessionMap)
          : null,
    );
  }
}

class AreaSummaryModel {
  final String areaName;
  final int tableCount;

  const AreaSummaryModel({
    required this.areaName,
    required this.tableCount,
  });

  factory AreaSummaryModel.fromJson(Map<String, dynamic> json) {
    return AreaSummaryModel(
      areaName: (json['areaName'] ?? '').toString(),
      tableCount: (json['tableCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardOverviewModel {
  final int totalTables;
  final int emptyTables;
  final int occupiedTables;
  final int awaitingQrTables;
  final int addOnTables;
  final List<AreaSummaryModel> areas;
  final List<TableCardModel> tables;
  final List<MenuCategoryModel> categories;
  final List<MenuItemModel> menuItems;
  final DateTime syncedAt;

  const DashboardOverviewModel({
    required this.totalTables,
    required this.emptyTables,
    required this.occupiedTables,
    required this.awaitingQrTables,
    required this.addOnTables,
    required this.areas,
    required this.tables,
    required this.categories,
    required this.menuItems,
    required this.syncedAt,
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    final rawAreas = json['areas'] as List? ?? const [];
    final rawTables = json['tables'] as List? ?? const [];
    final rawCategories = json['categories'] as List? ?? const [];
    final rawMenuItems = json['menuItems'] as List? ?? const [];

    return DashboardOverviewModel(
      totalTables: (json['totalTables'] as num?)?.toInt() ?? 0,
      emptyTables: (json['emptyTables'] as num?)?.toInt() ?? 0,
      occupiedTables: (json['occupiedTables'] as num?)?.toInt() ?? 0,
      awaitingQrTables: (json['awaitingQrTables'] as num?)?.toInt() ?? 0,
      addOnTables: (json['addOnTables'] as num?)?.toInt() ?? 0,
      areas: rawAreas
          .whereType<Map<String, dynamic>>()
          .map(AreaSummaryModel.fromJson)
          .toList(),
      tables: rawTables
          .whereType<Map<String, dynamic>>()
          .map(TableCardModel.fromJson)
          .toList(),
      categories: rawCategories
          .whereType<Map<String, dynamic>>()
          .map(MenuCategoryModel.fromJson)
          .toList(),
      menuItems: rawMenuItems
          .whereType<Map<String, dynamic>>()
          .map(MenuItemModel.fromJson)
          .toList(),
      syncedAt:
          DateTime.tryParse((json['syncedAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
    );
  }
}

class OrderItemInputModel {
  final int menuItemId;
  final int quantity;
  final String? note;

  const OrderItemInputModel({
    required this.menuItemId,
    required this.quantity,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'menuItemId': menuItemId,
    'quantity': quantity,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}
