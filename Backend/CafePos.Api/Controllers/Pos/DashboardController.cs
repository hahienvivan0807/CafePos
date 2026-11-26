using System.Security.Claims;
using CafePos.Api.Filters;
using CafePos.Application.Constants;
using CafePos.Application.DTOs.Pos;
using CafePos.Application.Interfaces.Pos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CafePos.Api.Controllers.Pos;

[ApiController]
[Route("api/dashboard")]
[Authorize(Roles = RoleNames.StaffOrManager)]
public class DashboardController : ControllerBase
{
    private readonly IPosDashboardService _dashboardService;

    public DashboardController(IPosDashboardService dashboardService)
    {
        _dashboardService = dashboardService;
    }

    [HttpGet("orders/{orderId:long}")]
    public async Task<IActionResult> GetOrderDetails(long orderId, CancellationToken ct)
    {
        var result = await _dashboardService.GetOrderDetailsAsync(orderId, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    [HttpGet("manager-overview")]
    [Authorize(Policy = "ManagerOnly")]
    public async Task<IActionResult> GetManagerOverview(CancellationToken ct)
    {
        var result = await _dashboardService.GetDashboardOverviewAsync(ct);
        return Ok(new
        {
            isSuccess = result.IsSuccess,
            message = result.Message,
            data = result.Data
        });
    }

    /// <summary>
    /// Lấy toàn bộ sơ đồ bàn, bộ đếm trạng thái, chi tiết các lượt dùng bàn và thực đơn từ database cafe_pos.
    /// </summary>
    [HttpGet("overview")]
    public async Task<IActionResult> GetOverview(CancellationToken ct)
    {
        var result = await _dashboardService.GetDashboardOverviewAsync(ct);
        return Ok(new
        {
            isSuccess = result.IsSuccess,
            message = result.Message,
            data = result.Data
        });
    }

    /// <summary>
    /// Mở bàn mới hoặc ghi thêm món vào bàn từ Modal có sẵn (kiểm tra CSRF Token).
    /// </summary>
    [HttpPost("tables/open-or-order")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> OpenTableOrAddItems(
        [FromBody] OpenTableOrAddItemsRequestDto request,
        CancellationToken ct)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized();
        }

        var result = await _dashboardService.OpenTableOrAddItemsAsync(userId, request, ct);
        if (!result.IsSuccess)
        {
            return StatusCode(result.StatusCode, new
            {
                isSuccess = false,
                errorCode = result.ErrorCode,
                message = result.Message
            });
        }

        return Ok(new
        {
            isSuccess = true,
            message = result.Message,
            data = result.Data
        });
    }

    /// <summary>
    /// Phát hành mã VietQR cho đơn đang mở trên bàn (chuyển trạng thái sang 'awaiting_payment').
    /// </summary>
    [HttpPost("tables/{tableId:long}/request-vietqr")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> RequestVietQr(long tableId, [FromQuery] long? orderId, CancellationToken ct)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized();
        }

        var result = await _dashboardService.RequestVietQrAsync(userId, tableId, ct, orderId);
        if (!result.IsSuccess)
        {
            return StatusCode(result.StatusCode, new
            {
                isSuccess = false,
                errorCode = result.ErrorCode,
                message = result.Message
            });
        }

        return Ok(new
        {
            isSuccess = true,
            message = result.Message,
            data = result.Data
        });
    }

    /// <summary>
    /// Xác nhận đơn hàng đã thanh toán đủ qua VietQR ('paid').
    /// </summary>
    [HttpPost("tables/{tableId:long}/confirm-paid")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> ConfirmPaid(long tableId, [FromQuery] long? orderId, CancellationToken ct)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized();
        }

        var result = await _dashboardService.ConfirmVietQrPaidAsync(userId, tableId, ct, orderId);
        if (!result.IsSuccess)
        {
            return StatusCode(result.StatusCode, new
            {
                isSuccess = false,
                errorCode = result.ErrorCode,
                message = result.Message
            });
        }

        return Ok(new
        {
            isSuccess = true,
            message = result.Message,
            data = result.Data
        });
    }

    /// <summary>
    /// Trả bàn (đóng LuotBan) khi khách rời đi và tất cả các đơn trong lượt đã thanh toán.
    /// </summary>
    [HttpPost("tables/{tableId:long}/close-table")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> CloseTable(long tableId, CancellationToken ct)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized();
        }

        var result = await _dashboardService.CloseTableSessionAsync(userId, tableId, ct);
        if (!result.IsSuccess)
        {
            return StatusCode(result.StatusCode, new
            {
                isSuccess = false,
                errorCode = result.ErrorCode,
                message = result.Message
            });
        }

        return Ok(new
        {
            isSuccess = true,
            message = result.Message,
            data = result.Data
        });
    }

    private bool TryGetUserId(out Guid userId)
    {
        var raw = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(raw, out userId);
    }
}
