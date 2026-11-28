using System.Security.Claims;
using CafePos.Api.Filters;
using CafePos.Application.DTOs.Pos.ThanhToan;
using CafePos.Application.Interfaces.Pos.ThanhToan;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CafePos.Api.Controllers.QuanLy.DoiSoat;

/// <summary>
/// Controller Đối soát giao dịch thu dư / QR cũ đến muộn cho Quản lý.
/// </summary>
[ApiController]
[Route("api/manager/reconciliation")]
[Authorize(Policy = "ManagerOnly")]
public class ReconciliationController : ControllerBase
{
    private readonly IPaymentService _service;

    public ReconciliationController(IPaymentService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<IActionResult> GetReconciliation(
        [FromQuery] string? filter,
        CancellationToken ct)
    {
        var res = await _service.GetReconciliationAsync(filter, ct);
        return StatusCode(res.StatusCode, new
        {
            isSuccess = res.IsSuccess,
            errorCode = res.ErrorCode,
            message = res.Message,
            data = res.Data
        });
    }

    [HttpPost("{transactionId:long}/resolve")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> Resolve(
        long transactionId,
        [FromBody] ResolveReconciliationRequestDto request,
        CancellationToken ct)
    {
        var raw = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var managerId = Guid.TryParse(raw, out var id) ? id : Guid.Empty;

        var res = await _service.ResolveReconciliationAsync(transactionId, managerId, request, ct);
        return StatusCode(res.StatusCode, new
        {
            isSuccess = res.IsSuccess,
            errorCode = res.ErrorCode,
            message = res.Message,
            data = res.Data
        });
    }
}
