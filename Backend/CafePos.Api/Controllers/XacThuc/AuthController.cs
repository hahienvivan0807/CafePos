using System.Security.Claims;
using CafePos.Api.Filters;
using CafePos.Application.Constants;
using CafePos.Application.DTOs.XacThuc;
using CafePos.Application.Interfaces.XacThuc;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CafePos.Api.Controllers.XacThuc;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    public const string SecurityStampClaimType = "AspNet.Identity.SecurityStamp";

    private readonly IAuthService _authService;
    private readonly IAntiforgery _antiforgery;

    public AuthController(IAuthService authService, IAntiforgery antiforgery)
    {
        _authService = authService;
        _antiforgery = antiforgery;
    }

    /// <summary>
    /// Đăng nhập vào hệ thống POS bằng Mã nhân viên (VD: TN01, QL01) hoặc Tên đăng nhập.
    /// Cấp Cookie HttpOnly, Secure, SameSite=Lax (7 ngày nếu chọn Ghi nhớ, hoặc theo phiên trình duyệt).
    /// </summary>
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto request, CancellationToken ct)
    {
        var result = await _authService.AuthenticateAsync(request, ct);
        if (!result.IsSuccess || result.Data is null)
        {
            return StatusCode(result.StatusCode, new
            {
                isSuccess = false,
                errorCode = result.ErrorCode,
                message = result.Message
            });
        }

        var session = result.Data;
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, session.User.UserId.ToString()),
            new(ClaimTypes.Name, session.User.Username),
            new("staff_code", session.User.StaffCode),
            new("full_name", session.User.FullName),
            new(SecurityStampClaimType, session.SecurityStamp)
        };

        foreach (var role in session.User.Roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        var principal = new ClaimsPrincipal(identity);

        // Nếu chọn Ghi nhớ: cookie tồn tại tối đa 7 ngày. Nếu bỏ chọn: cookie theo phiên trình duyệt.
        var authProperties = new AuthenticationProperties
        {
            IsPersistent = request.RememberMe,
            AllowRefresh = true
        };

        if (request.RememberMe)
        {
            authProperties.ExpiresUtc = DateTimeOffset.UtcNow.AddDays(7);
        }

        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            principal,
            authProperties);

        // Gán HttpContext.User ngay trong request hiện tại để IAntiforgery sinh token khớp với người dùng vừa đăng nhập
        HttpContext.User = principal;
        var tokens = _antiforgery.GetAndStoreTokens(HttpContext);

        var isManager = session.User.Roles.Contains(RoleNames.Manager, StringComparer.OrdinalIgnoreCase);
        var nextAction = isManager
            ? "ENTER_MANAGER"
            : (session.ActiveShift is null ? "START_SHIFT" : "CONTINUE_SHIFT");
        var responseDto = new AuthSessionResponseDto(
            session.User,
            session.ActiveShift,
            tokens.RequestToken ?? string.Empty,
            nextAction);

        return Ok(new
        {
            isSuccess = true,
            message = result.Message,
            data = responseDto
        });
    }

    /// <summary>
    /// Khôi phục phiên đăng nhập khi mở lại Flutter Web (GET /api/auth/me).
    /// Trả về thông tin nhân viên, ca đang mở (nếu có) và hướng dẫn hiển thị Bắt đầu ca hoặc Tiếp tục ca.
    /// </summary>
    [HttpGet("me")]
    [Authorize(Roles = RoleNames.StaffOrManager)]
    public async Task<IActionResult> Me(CancellationToken ct)
    {
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdStr, out var userId))
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return Unauthorized(new
            {
                isSuccess = false,
                errorCode = "UNAUTHORIZED",
                message = "Phiên đăng nhập không hợp lệ."
            });
        }

        var result = await _authService.GetCurrentSessionAsync(userId, ct);
        if (!result.IsSuccess || result.Data is null)
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return StatusCode(result.StatusCode, new
            {
                isSuccess = false,
                errorCode = result.ErrorCode,
                message = result.Message
            });
        }

        var session = result.Data;
        var tokens = _antiforgery.GetAndStoreTokens(HttpContext);
        var isManager = session.User.Roles.Contains(RoleNames.Manager, StringComparer.OrdinalIgnoreCase);
        var nextAction = isManager
            ? "ENTER_MANAGER"
            : (session.ActiveShift is null ? "START_SHIFT" : "CONTINUE_SHIFT");

        return Ok(new
        {
            isSuccess = true,
            message = "Khôi phục phiên đăng nhập thành công.",
            data = new AuthSessionResponseDto(
                session.User,
                session.ActiveShift,
                tokens.RequestToken ?? string.Empty,
                nextAction)
        });
    }

    /// <summary>
    /// Lấy mới mã chống CSRF cho phiên hiện tại.
    /// </summary>
    [HttpGet("antiforgery")]
    [Authorize(Roles = RoleNames.StaffOrManager)]
    public IActionResult GetAntiforgeryToken()
    {
        var tokens = _antiforgery.GetAndStoreTokens(HttpContext);
        return Ok(new
        {
            isSuccess = true,
            csrfToken = tokens.RequestToken ?? string.Empty
        });
    }

    /// <summary>
    /// Đăng xuất và xóa Cookie phiên.
    /// </summary>
    [HttpPost("logout")]
    [Authorize]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return Ok(new
        {
            isSuccess = true,
            message = "Đã đăng xuất khỏi hệ thống POS."
        });
    }
}
