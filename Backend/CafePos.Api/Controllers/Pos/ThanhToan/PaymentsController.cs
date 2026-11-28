using System.Security.Claims;
using CafePos.Api.Filters;
using CafePos.Application.DTOs.Pos.ThanhToan;
using CafePos.Application.Interfaces.Pos.ThanhToan;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CafePos.Api.Controllers.Pos.ThanhToan;

/// <summary>
/// Controller Thanh toán VietQR, Tiền mặt & Webhook chuẩn SePay.
/// </summary>
[ApiController]
[Route("api/payments")]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentService _service;
    private readonly IWebHostEnvironment _env;

    public PaymentsController(IPaymentService service, IWebHostEnvironment env)
    {
        _service = service;
        _env = env;
    }

    [HttpGet("orders/{orderId:long}")]
    [Authorize]
    public async Task<IActionResult> GetOrderPaymentState(long orderId, CancellationToken ct)
    {
        var res = await _service.GetOrderPaymentStateAsync(orderId, ct);
        return StatusCode(res.StatusCode, new
        {
            isSuccess = res.IsSuccess,
            errorCode = res.ErrorCode,
            message = res.Message,
            data = res.Data
        });
    }

    [HttpGet("qr-image/{qrId:long}")]
    [Authorize]
    public async Task<IActionResult> GetQrImage(long qrId, CancellationToken ct)
    {
        var res = await _service.GetQrImageBytesAsync(qrId, ct);
        if (!res.IsSuccess || res.Data is null)
        {
            return StatusCode(res.StatusCode, new
            {
                isSuccess = false,
                errorCode = res.ErrorCode,
                message = res.Message
            });
        }
        return File(res.Data, "image/png");
    }

    [HttpPost("orders/{orderId:long}/vietqr")]
    [Authorize]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> GenerateVietQr(long orderId, CancellationToken ct)
    {
        var res = await _service.GenerateOrRefreshVietQrAsync(orderId, ct);
        return StatusCode(res.StatusCode, new
        {
            isSuccess = res.IsSuccess,
            errorCode = res.ErrorCode,
            message = res.Message,
            data = res.Data
        });
    }

    [HttpPost("orders/{orderId:long}/cash")]
    [Authorize]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> RecordCashPayment(
        long orderId,
        [FromBody] RecordCashPaymentRequestDto? request,
        CancellationToken ct)
    {
        var userId = GetCurrentUserId();
        var res = await _service.RecordCashPaymentAsync(
            orderId,
            userId,
            request ?? new RecordCashPaymentRequestDto(),
            ct);
        return StatusCode(res.StatusCode, new
        {
            isSuccess = res.IsSuccess,
            errorCode = res.ErrorCode,
            message = res.Message,
            data = res.Data
        });
    }

    /// <summary>
    /// Webhook nhận biến động số dư chuẩn SePay (xác thực bằng header Authorization: Apikey &lt;secret&gt;).
    /// </summary>
    [HttpPost("vietqr-webhook")]
    [AllowAnonymous]
    public async Task<IActionResult> ReceiveSePayWebhook(
        [FromBody] SePayWebhookRequestDto payload,
        CancellationToken ct)
    {
        var authHeader = Request.Headers.Authorization.FirstOrDefault();
        var res = await _service.ProcessSePayWebhookAsync(payload, authHeader, bypassAuthForDemo: false, ct);
        return StatusCode(res.StatusCode, new
        {
            success = res.IsSuccess,
            isSuccess = res.IsSuccess,
            errorCode = res.ErrorCode,
            message = res.Message,
            data = res.Data
        });
    }

    /// <summary>
    /// Endpoint giả lập ngân hàng báo nhận tiền (chỉ bật ở môi trường Development cho Quản lý test luồng B07).
    /// </summary>
    [HttpPost("demo/simulate-webhook")]
    [Authorize(Policy = "ManagerOnly")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> SimulateWebhook(
        [FromBody] SimulateWebhookRequestDto request,
        CancellationToken ct)
    {
        if (!_env.IsDevelopment())
        {
            return Forbid();
        }

        var bankTxId = string.IsNullOrWhiteSpace(request.BankTransactionId)
            ? $"DEMO-{DateTimeOffset.UtcNow:yyyyMMddHHmmssfff}"
            : request.BankTransactionId.Trim();

        var payload = new SePayWebhookRequestDto
        {
            Id = bankTxId,
            Gateway = string.IsNullOrWhiteSpace(request.Gateway) ? "MBBank (Demo)" : request.Gateway,
            TransferType = "in",
            TransferAmount = request.AmountVnd,
            Content = $"MBVCB.DEMO.{request.ReferenceCode}.CHUYEN KHOAN"
        };

        var res = await _service.ProcessSePayWebhookAsync(payload, null, bypassAuthForDemo: true, ct);
        return StatusCode(res.StatusCode, new
        {
            isSuccess = res.IsSuccess,
            errorCode = res.ErrorCode,
            message = res.Message,
            data = res.Data
        });
    }

    private Guid GetCurrentUserId()
    {
        var raw = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(raw, out var id) ? id : Guid.Empty;
    }
}
