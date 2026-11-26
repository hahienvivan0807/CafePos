using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace CafePos.Api.Filters;

/// <summary>
/// Bộ lọc kiểm tra mã chống CSRF (ASP.NET Core Antiforgery) cho các thao tác
/// thay đổi dữ liệu bằng cookie như bắt đầu ca, kết thúc ca, cập nhật hồ sơ và đăng xuất.
/// </summary>
public class ValidatePosAntiforgeryFilter : IAsyncActionFilter
{
    private readonly IAntiforgery _antiforgery;

    public ValidatePosAntiforgeryFilter(IAntiforgery antiforgery)
    {
        _antiforgery = antiforgery;
    }

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        try
        {
            await _antiforgery.ValidateRequestAsync(context.HttpContext);
        }
        catch (AntiforgeryValidationException)
        {
            context.Result = new ObjectResult(new
            {
                isSuccess = false,
                errorCode = "INVALID_CSRF_TOKEN",
                message = "Mã bảo mật chống giả mạo (CSRF Token) không hợp lệ hoặc đã hết hạn. Vui lòng tải lại phiên."
            })
            {
                StatusCode = StatusCodes.Status400BadRequest
            };
            return;
        }

        await next();
    }
}
