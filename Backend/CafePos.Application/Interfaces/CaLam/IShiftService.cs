using CafePos.Application.DTOs.CaLam;
using CafePos.Application.DTOs.DungChung;

namespace CafePos.Application.Interfaces.CaLam;

public interface IShiftService
{
    Task<ShiftDto?> GetActiveShiftAsync(
        Guid userId,
        CancellationToken ct = default);

    Task<ServiceResult<ShiftDto>> StartShiftAsync(
        Guid userId,
        StartShiftRequestDto request,
        CancellationToken ct = default);

    Task<ServiceResult<ShiftDto>> EndShiftAsync(
        Guid userId,
        EndShiftRequestDto request,
        CancellationToken ct = default);
}
