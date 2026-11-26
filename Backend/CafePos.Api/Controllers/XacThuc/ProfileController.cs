using System.Security.Claims;
using CafePos.Api.Filters;
using CafePos.Application.Constants;
using CafePos.Application.DTOs.XacThuc;
using CafePos.Application.Interfaces.XacThuc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CafePos.Api.Controllers.XacThuc;

[ApiController]
[Route("api/profile")]
[Authorize(Roles = RoleNames.StaffOrManager)]
public class ProfileController : ControllerBase
{
    private readonly IAuthService _authService;

    public ProfileController(IAuthService authService)
    {
        _authService = authService;
    }

    /// <summary>
    /// Cập nhật hồ sơ người dùng (có kiểm tra Antiforgery CSRF Token).
    /// </summary>
    [HttpPut]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> UpdateProfile(
        [FromBody] UpdateProfileRequestDto request,
        CancellationToken ct)
    {
        var raw = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(raw, out var userId))
        {
            return Unauthorized();
        }

        var result = await _authService.UpdateProfileAsync(userId, request, ct);
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
}
