using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.QuanLy.BaoCao;

namespace CafePos.Application.Interfaces.QuanLy.BaoCao;

public interface IReportAnalyticsService
{
    Task<ServiceResult<RevenueAnalyticsResponseDto>> GetRevenueAnalyticsAsync(
        DateOnly? fromDate,
        DateOnly? toDate,
        CancellationToken ct = default);

    Task<ServiceResult<AiForecastResponseDto>> GetAiForecastAsync(
        DateOnly? fromDate,
        DateOnly? toDate,
        CancellationToken ct = default);

    Task<ServiceResult<ShiftOrdersResponseDto>> GetShiftOrdersAsync(
        string shiftCode,
        DateOnly? fromDate,
        DateOnly? toDate,
        CancellationToken ct = default);
}
