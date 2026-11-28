using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.Pos.ThanhToan;

namespace CafePos.Application.Interfaces.Pos.ThanhToan;

public interface IPaymentService
{
    Task<ServiceResult<OrderPaymentStateDto>> GetOrderPaymentStateAsync(
        long orderId,
        CancellationToken ct = default);

    Task<ServiceResult<OrderPaymentStateDto>> GenerateOrRefreshVietQrAsync(
        long orderId,
        CancellationToken ct = default);

    Task<ServiceResult<OrderPaymentStateDto>> RecordCashPaymentAsync(
        long orderId,
        Guid staffUserId,
        RecordCashPaymentRequestDto request,
        CancellationToken ct = default);

    Task<ServiceResult<WebhookProcessResultDto>> ProcessSePayWebhookAsync(
        SePayWebhookRequestDto payload,
        string? authorizationHeader,
        bool bypassAuthForDemo = false,
        CancellationToken ct = default);

    Task<ServiceResult<ReconciliationSummaryDto>> GetReconciliationAsync(
        string? filter = "all",
        CancellationToken ct = default);

    Task<ServiceResult<PaymentTransactionDto>> ResolveReconciliationAsync(
        long transactionId,
        Guid managerUserId,
        ResolveReconciliationRequestDto request,
        CancellationToken ct = default);

    Task<ServiceResult<byte[]>> GetQrImageBytesAsync(
        long qrId,
        CancellationToken ct = default);
}
