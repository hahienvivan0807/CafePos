using CafePos.Api.Filters;
using CafePos.Application.DTOs.QuanLy.PhanCa;
using CafePos.Application.Interfaces.QuanLy.PhanCa;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CafePos.Api.Controllers.QuanLy.PhanCa;

/// <summary>
/// Controller quản lý Khung ca (Màn 28, 29, 33) & Lịch phân ca tuần (Màn 30, 31, 32) cho Quản lý.
/// </summary>
[ApiController]
[Route("api/manager/shift-schedule")]
[Authorize(Policy = "ManagerOnly")]
public class ShiftScheduleController : ControllerBase
{
    private readonly IShiftScheduleService _service;

    public ShiftScheduleController(IShiftScheduleService service)
    {
        _service = service;
    }

    [HttpGet("templates")]
    public async Task<IActionResult> GetTemplates(
        [FromQuery] string? search,
        [FromQuery] string? status,
        CancellationToken ct)
    {
        var result = await _service.GetTemplatesAsync(search, status, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    [HttpPost("templates")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> CreateTemplate(
        [FromBody] UpsertShiftTemplateRequestDto request,
        CancellationToken ct)
    {
        var result = await _service.CreateTemplateAsync(request, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    [HttpPut("templates/{code}")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> UpdateTemplate(
        string code,
        [FromBody] UpsertShiftTemplateRequestDto request,
        CancellationToken ct)
    {
        var result = await _service.UpdateTemplateAsync(code, request, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    [HttpDelete("templates/{code}")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> DeleteTemplate(
        string code,
        [FromQuery] string? reason,
        CancellationToken ct)
    {
        var result = await _service.DeleteOrDisableTemplateAsync(
            code,
            new DeleteShiftTemplateRequestDto(reason),
            ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    [HttpGet("week")]
    public async Task<IActionResult> GetWeeklySchedule(
        [FromQuery] DateOnly? weekStart,
        CancellationToken ct)
    {
        var result = await _service.GetWeeklyScheduleAsync(weekStart, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    [HttpPost("assignments")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> AssignStaff(
        [FromBody] CreateShiftAssignmentRequestDto request,
        CancellationToken ct)
    {
        var result = await _service.AssignStaffAsync(request, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    [HttpDelete("assignments/{id:long}")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> CancelAssignment(
        long id,
        [FromQuery] string? reason,
        CancellationToken ct)
    {
        var result = await _service.CancelAssignmentAsync(
            id,
            new CancelShiftAssignmentRequestDto(reason),
            ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    [HttpPost("week/publish")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> PublishWeek(
        [FromBody] WeekActionRequestDto request,
        CancellationToken ct)
    {
        var result = await _service.PublishWeekAsync(request.WeekStart, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    [HttpPost("week/copy-previous")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> CopyPreviousWeek(
        [FromBody] WeekActionRequestDto request,
        CancellationToken ct)
    {
        var result = await _service.CopyPreviousWeekAsync(request.WeekStart, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }
}
