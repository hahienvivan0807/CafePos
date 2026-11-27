using CafePos.Api.Filters;
using CafePos.Application.DTOs.QuanLy.TroLyAi;
using CafePos.Application.Interfaces.QuanLy.TroLyAi;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CafePos.Api.Controllers.QuanLy.TroLyAi;

/// <summary>
/// Controller Trợ lý AI tiếng Việt (Daylight AI) kết nối Ollama local cho Quản lý.
/// </summary>
[ApiController]
[Route("api/manager/ai-assistant")]
[Authorize(Policy = "ManagerOnly")]
public class AiAssistantController : ControllerBase
{
    private readonly IAiAssistantService _service;

    public AiAssistantController(IAiAssistantService service)
    {
        _service = service;
    }

    [HttpGet("status")]
    public async Task<IActionResult> GetStatus(CancellationToken ct)
    {
        var result = await _service.GetStatusAsync(ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    [HttpPost("chat")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> Chat(
        [FromBody] AiChatRequestDto request,
        CancellationToken ct)
    {
        var result = await _service.ChatAsync(request, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    [HttpPost("confirm")]
    [ServiceFilter(typeof(ValidatePosAntiforgeryFilter))]
    public async Task<IActionResult> ConfirmAction(
        [FromBody] AiConfirmActionRequestDto request,
        CancellationToken ct)
    {
        var result = await _service.ConfirmActionAsync(request, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }
}
