using System.Security.Claims;
using CafePos.Api.Filters;
using CafePos.Application.Constants;
using CafePos.Application.DTOs.CaLam;
using CafePos.Application.Interfaces.CaLam;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CafePos.Api.Controllers.CaLam;

[ApiController]
[Route("api/shifts")]
[Authorize(Roles = RoleNames.StaffOrManager)]
public class ShiftsController : ControllerBase
{
    private readonly IShiftService _shiftService;

    public ShiftsController(IShiftService shiftService)
    {
        _shiftService = shiftService;
    }

    [HttpGet("current")]
    public async Task<IActionResult> GetCurrentShift(CancellationToken ct)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized();
        }

        var shift = await _shiftService.GetActiveShiftAsync(userId, ct);
        return Ok(new
        {
            isSuccess = true,
            data = shift,
            nextAction = shift is null ? "START_SHIFT" : "CONTINUE_SHIFT"
        });
    }

    /// <summary>
    /// Bắt đầu ca làm việc mới (có kiểm tra Antiforgery CSRF Token và chống tạo trùng khi bấm 2 lần).
    /// </summary>
    [HttpPost("start")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> StartShift([FromBody] StartShiftRequestDto? request, CancellationToken ct)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized();
        }

        var result = await _shiftService.StartShiftAsync(
            userId,
            request ?? new StartShiftRequestDto(),
            ct);

        if (!result.IsSuccess)
        {
            return StatusCode(result.StatusCode, new
            {
                isSuccess = false,
                errorCode = result.ErrorCode,
                message = result.Message
            });
        }

        return StatusCode(result.StatusCode, new
        {
            isSuccess = true,
            message = result.Message,
            data = result.Data
        });
    }

    /// <summary>
    /// Kết thúc ca làm việc đang mở (có kiểm tra Antiforgery CSRF Token).
    /// </summary>
    [HttpPost("end")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> EndShift([FromBody] EndShiftRequestDto? request, CancellationToken ct)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized();
        }

        var result = await _shiftService.EndShiftAsync(
            userId,
            request ?? new EndShiftRequestDto(),
            ct);

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
