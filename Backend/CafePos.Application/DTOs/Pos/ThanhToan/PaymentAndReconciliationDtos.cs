using System.Text.Json.Serialization;

namespace CafePos.Application.DTOs.Pos.ThanhToan;

public record VietQrSessionDto(
    long Id,
    int Version,
    string ReferenceCode,
    long AmountVnd,
    string BankId,
    string AccountNo,
    string AccountName,
    string QrImageUrl,
    string Status,       // DangCho | DaThayThe | DaThuDu | DaHuy
    DateTimeOffset CreatedAt
);

public record PaymentTransactionDto(
    long Id,
    long OrderId,
    string OrderCode,
    string TableName,
    string Method,       // vietqr | cash
    string? BankTransactionId,
    string? Gateway,
    string? MatchedReferenceCode,
    string? TransferContent,
    long AmountVnd,
    bool NeedsReconciliation,
    string ReconciliationStatus, // KhongCan | ChoXuLy | DaXuLy
    string? ReconciliationNote,
    DateTimeOffset RecordedAt,
    DateTimeOffset? ReconciledAt
);

public record OrderPaymentStateDto(
    long OrderId,
    string OrderCode,
    string TableName,
    string OrderStatus,
    long OrderTotalVnd,
    long TotalPaidVnd,
    long RemainingVnd,
    long OverpaidVnd,
    bool HasPendingReconciliation,
    VietQrSessionDto? ActiveQr,
    IReadOnlyList<VietQrSessionDto> QrHistory,
    IReadOnlyList<PaymentTransactionDto> Transactions
);

public record RecordCashPaymentRequestDto(
    long? ReceivedAmountVnd = null,
    string? Note = null
);

/// <summary>
/// Payload Webhook chuẩn SePay (https://docs.sepay.vn/tich-hop-webhooks.html)
/// </summary>
public class SePayWebhookRequestDto
{
    [JsonPropertyName("id")]
    public object? Id { get; set; }

    [JsonPropertyName("gateway")]
    public string? Gateway { get; set; }

    [JsonPropertyName("transactionDate")]
    public string? TransactionDate { get; set; }

    [JsonPropertyName("accountNumber")]
    public string? AccountNumber { get; set; }

    [JsonPropertyName("code")]
    public string? Code { get; set; }

    [JsonPropertyName("content")]
    public string? Content { get; set; }

    [JsonPropertyName("transferType")]
    public string? TransferType { get; set; } = "in";

    [JsonPropertyName("transferAmount")]
    public long TransferAmount { get; set; }

    [JsonPropertyName("referenceCode")]
    public string? ReferenceCode { get; set; }
}

public record SimulateWebhookRequestDto(
    string ReferenceCode,
    long AmountVnd,
    string? BankTransactionId = null,
    string? Gateway = "MBBank (Demo)"
);

public record WebhookProcessResultDto(
    bool AlreadyProcessed,
    long? OrderId,
    string? OrderCode,
    string? MatchedReferenceCode,
    long AmountVnd,
    bool NeedsReconciliation,
    string OrderStatus,
    string Summary
);

public record ReconciliationSummaryDto(
    int PendingCount,
    int ResolvedCount,
    long PendingOverpaidTotalVnd,
    IReadOnlyList<PaymentTransactionDto> Items
);

public record ResolveReconciliationRequestDto(
    string ResolutionNote
);
