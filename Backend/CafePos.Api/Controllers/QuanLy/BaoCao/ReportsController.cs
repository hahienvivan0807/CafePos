using CafePos.Application.Interfaces.QuanLy.BaoCao;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CafePos.Api.Controllers.QuanLy.BaoCao;

/// <summary>
/// Controller Báo cáo kinh doanh & Dự báo vận hành (Daylight AI) dành riêng cho Quản lý (ManagerOnly).
/// </summary>
[ApiController]
[Route("api/manager/reports")]
[Authorize(Policy = "ManagerOnly")]
public class ReportsController : ControllerBase
{
    private readonly IReportAnalyticsService _reportService;

    public ReportsController(IReportAnalyticsService reportService)
    {
        _reportService = reportService;
    }

    /// <summary>
    /// Báo cáo kết quả vận hành: tách biệt tổng giá trị đơn hàng (GOV) và thực tế tiền đã thu (Paid).
    /// </summary>
    [HttpGet("revenue-analytics")]
    public async Task<IActionResult> GetRevenueAnalytics(
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to,
        CancellationToken ct)
    {
        var result = await _reportService.GetRevenueAnalyticsAsync(from, to, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    /// <summary>
    /// Phân tích xu hướng thực tế & dự báo 7 ngày tới (Daylight AI).
    /// </summary>
    [HttpGet("ai-forecast")]
    public async Task<IActionResult> GetAiForecast(
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to,
        CancellationToken ct)
    {
        var result = await _reportService.GetAiForecastAsync(from, to, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }

    /// <summary>
    /// Lấy danh sách hóa đơn thuộc một khung ca cụ thể (CA_SANG, CA_TRUA, CA_CHIEU, CA_TOI).
    /// </summary>
    [HttpGet("shift-orders")]
    public async Task<IActionResult> GetShiftOrders(
        [FromQuery] string slot,
        [FromQuery] DateOnly? from,
        [FromQuery] DateOnly? to,
        CancellationToken ct)
    {
        var result = await _reportService.GetShiftOrdersAsync(slot, from, to, ct);
        return StatusCode(result.StatusCode, new
        {
            isSuccess = result.IsSuccess,
            errorCode = result.ErrorCode,
            message = result.Message,
            data = result.Data
        });
    }
}
