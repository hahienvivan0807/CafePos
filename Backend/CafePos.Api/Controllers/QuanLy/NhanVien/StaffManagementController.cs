using System.Security.Claims;
using CafePos.Api.Filters;
using CafePos.Application.DTOs.QuanLy.NhanVien;
using CafePos.Application.Interfaces.QuanLy.NhanVien;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CafePos.Api.Controllers.QuanLy.NhanVien;

/// <summary>
/// Controller CRUD quản lý nhân viên dành riêng cho Quản lý (ManagerOnly).
/// Các thao tác ghi (POST / PUT / DELETE) đều được bảo vệ bằng Antiforgery CSRF Token.
/// </summary>
[ApiController]
[Route("api/manager/staff")]
[Authorize(Policy = "ManagerOnly")]
public class StaffManagementController : ControllerBase
{
    private readonly IStaffManagementService _staffService;

    public StaffManagementController(IStaffManagementService staffService)
    {
        _staffService = staffService;
    }

    /// <summary>
    /// Lấy danh sách nhân sự từ bảng pos."NguoiDung" & pos."HoSoNguoiDung" (hỗ trợ lọc search, role, status).
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetList(
        [FromQuery] string? search,
        [FromQuery] string? role,
        [FromQuery] string? status,
        CancellationToken ct)
    {
        var result = await _staffService.GetStaffListAsync(search, role, status, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    /// <summary>
    /// Thêm mới tài khoản nhân viên & hồ sơ (Modal 25).
    /// </summary>
    [HttpPost]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> Create(
        [FromBody] CreateStaffRequestDto request,
        CancellationToken ct)
    {
        var result = await _staffService.CreateStaffAsync(request, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    /// <summary>
    /// Chỉnh sửa hồ sơ, vai trò và trạng thái hoạt động của nhân viên (Modal 26).
    /// </summary>
    [HttpPut("{staffUserId:guid}")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> Update(
        Guid staffUserId,
        [FromBody] UpdateStaffRequestDto request,
        CancellationToken ct)
    {
        if (!TryGetCurrentUserId(out var currentManagerId))
        {
            return Unauthorized();
        }

        var result = await _staffService.UpdateStaffAsync(
            staffUserId,
            currentManagerId,
            request,
            ct);

        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    /// <summary>
    /// Xóa tài khoản nhân viên (hoặc tự động chuyển sang khóa nếu đã phát sinh lịch sử ca/đơn hàng).
    /// </summary>
    [HttpDelete("{staffUserId:guid}")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> Delete(
        Guid staffUserId,
        CancellationToken ct)
    {
        if (!TryGetCurrentUserId(out var currentManagerId))
        {
            return Unauthorized();
        }

        var result = await _staffService.DeleteStaffAsync(
            staffUserId,
            currentManagerId,
            ct);

        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    /// <summary>
    /// Đặt lại mật khẩu mới ngay lập tức cho nhân viên (Modal 26).
    /// </summary>
    [HttpPost("{staffUserId:guid}/reset-password")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> ResetPassword(
        Guid staffUserId,
        [FromBody] ResetStaffPasswordRequestDto request,
        CancellationToken ct)
    {
        if (!TryGetCurrentUserId(out var currentManagerId))
        {
            return Unauthorized();
        }

        var result = await _staffService.ResetStaffPasswordAsync(
            staffUserId,
            currentManagerId,
            request,
            ct);

        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    private bool TryGetCurrentUserId(out Guid userId)
    {
        var raw = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(raw, out userId);
    }
}
