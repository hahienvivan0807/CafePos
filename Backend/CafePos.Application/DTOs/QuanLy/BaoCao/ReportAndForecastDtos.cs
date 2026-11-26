namespace CafePos.Application.DTOs.QuanLy.BaoCao;

public record TimeSlotRevenueDto(
    string SlotKey,       // "morning" | "noon" | "afternoon" | "evening"
    string Label,         // "Sáng (07:00 - 11:00)" ...
    long OrderValueVnd,   // Tổng giá trị đơn hàng (GOV)
    long CollectedVnd,    // Thực tế tiền đã thu (Paid)
    int OrderCount
);

public record PaymentBreakdownItemDto(
    string MethodKey,     // "vietqr" | "cash"
    string Label,
    long AmountVnd,
    double Percentage
);

public record TopMenuItemReportDto(
    int Rank,
    long MenuItemId,
    string ItemCode,
    string ItemName,
    string CategoryName,
    int QuantitySold,
    long RevenueVnd,
    double ContributionPercent
);

public record RevenueAnalyticsResponseDto(
    DateOnly FromDate,
    DateOnly ToDate,
    long TotalOrderValueVnd,       // Gross Order Value (GOV)
    long ActualCollectedAmountVnd, // Net Collected (Paid)
    int TotalTableSessions,
    int CompletedTableSessions,
    double TableCompletionRate,
    int TotalOrders,
    int PaidOrders,
    int AwaitingPaymentOrders,
    int OpenOrders,
    string? TopBestSellerName,
    int TopBestSellerQuantity,
    IReadOnlyList<TimeSlotRevenueDto> TimeSlots,
    IReadOnlyList<PaymentBreakdownItemDto> PaymentBreakdown,
    IReadOnlyList<TopMenuItemReportDto> TopItems,
    IReadOnlyList<string> Categories,
    DateTimeOffset SyncedAt
);

public record ForecastDataPointDto(
    DateOnly Date,
    string Label,           // "dd/MM"
    long? ActualRevenueVnd,
    long? ForecastRevenueVnd,
    int? ActualOrderCount,
    int? ForecastOrderCount
);

public record IngredientSuggestionDto(
    string Name,
    string Category,
    string CurrentStockLabel,
    string SuggestedRestockLabel,
    string PriorityLabel
);

public record AiForecastResponseDto(
    DateOnly FromDate,
    DateOnly ToDate,
    bool HasEnoughData,
    int HistoricalDaysAvailable,
    int MinimumDaysRequired,
    double DataCoveragePercent,
    string StatusTitle,
    string StatusDescription,
    long ProjectedNext7DaysRevenueVnd,
    double TrendPercent,
    string PeakTimeWindow,
    IReadOnlyList<ForecastDataPointDto> Series,
    IReadOnlyList<IngredientSuggestionDto> IngredientSuggestions,
    DateTimeOffset SyncedAt
);

public record ShiftOrderSummaryDto(
    long OrderId,
    string OrderCode,
    string TableCode,
    string TableName,
    string StaffName,
    string Status,
    DateTimeOffset CreatedAt,
    DateTimeOffset? PaidAt,
    int TotalItemsCount,
    long TotalAmountVnd
);

public record ShiftOrdersResponseDto(
    string ShiftCode,
    string ShiftLabel,
    DateOnly FromDate,
    DateOnly ToDate,
    long TotalOrderValueVnd,
    long TotalCollectedVnd,
    IReadOnlyList<ShiftOrderSummaryDto> Orders
);
