namespace CafePos.Application.DTOs.Pos;

public record MenuCategoryDto(
    long Id,
    string Code,
    string Name,
    int ItemCount
);

public record MenuItemDto(
    long Id,
    long CategoryId,
    string CategoryCode,
    string CategoryName,
    string Code,
    string Name,
    long PriceVnd,
    bool IsActive
);

public record OrderLineDto(
    long Id,
    long MenuItemId,
    string ItemName,
    long UnitPriceVnd,
    int Quantity,
    long LineTotalVnd,
    string? Note,
    DateTimeOffset CreatedAt,
    string? CancelStatus
);

public record OrderDetailDto(
    long Id,
    string Code,
    string DisplayLabel, // VD: "#A", "#B"
    string Status,       // 'open' | 'awaiting_payment' | 'paid' | 'cancelled'
    DateTimeOffset CreatedAt,
    DateTimeOffset? PaidAt,
    long TotalAmountVnd,
    int TotalItemsCount,
    bool IsAddOnOrder,
    IReadOnlyList<OrderLineDto> Lines
);

public record OrderDetailsViewDto(
    long TableId,
    string TableCode,
    string TableName,
    string? StaffName,
    long PaidAmountVnd,
    long RemainingAmountVnd,
    bool CanAddItems,
    bool CanPay,
    OrderDetailDto Order
);

public record TableSessionDetailDto(
    long SessionId,
    long TableId,
    string TableCode,
    string TableName,
    DateTimeOffset OpenedAt,
    int SeatedMinutes,
    long TotalAllOrdersVnd,
    long PaidAmountVnd,
    long RemainingAmountVnd,
    long? ActiveUnpaidOrderId,
    string? ActiveUnpaidOrderCode,
    string? ActiveUnpaidOrderStatus,
    bool CanCloseTable,
    IReadOnlyList<OrderDetailDto> Orders
);

public record TableCardDto(
    long TableId,
    string TableCode,
    string TableName,
    string AreaName,
    string VisualStatus, // 'EMPTY' | 'OCCUPIED' | 'AWAITING_QR' | 'ADD_ON'
    string BadgeText,
    long DisplayAmountVnd,
    int TotalItemsCount,
    int? SeatedMinutes,
    long? ActiveSessionId,
    string? ActiveOrderLabel,
    string? ActiveOrderStatus,
    TableSessionDetailDto? SessionDetail
);

public record AreaSummaryDto(
    string AreaName,
    int TableCount
);

public record DashboardOverviewDto(
    int TotalTables,
    int EmptyTables,
    int OccupiedTables,
    int AwaitingQrTables,
    int AddOnTables,
    IReadOnlyList<AreaSummaryDto> Areas,
    IReadOnlyList<TableCardDto> Tables,
    IReadOnlyList<MenuCategoryDto> Categories,
    IReadOnlyList<MenuItemDto> MenuItems,
    DateTimeOffset SyncedAt
);

public record OrderItemInputDto(
    long MenuItemId,
    int Quantity,
    string? Note = null
);

public record OpenTableOrAddItemsRequestDto(
    long TableId,
    IReadOnlyList<OrderItemInputDto>? Items = null,
    long? OrderId = null
);
