using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.QuanLy.PhanCa;

namespace CafePos.Application.Interfaces.QuanLy.PhanCa;

public interface IShiftScheduleService
{
    Task<ServiceResult<IReadOnlyList<ShiftTemplateDto>>> GetTemplatesAsync(
        string? search = null,
        string? status = null,
        CancellationToken ct = default);

    Task<ServiceResult<ShiftTemplateDto>> CreateTemplateAsync(
        UpsertShiftTemplateRequestDto request,
        CancellationToken ct = default);

    Task<ServiceResult<ShiftTemplateDto>> UpdateTemplateAsync(
        string code,
        UpsertShiftTemplateRequestDto request,
        CancellationToken ct = default);

    Task<ServiceResult<bool>> DeleteOrDisableTemplateAsync(
        string code,
        DeleteShiftTemplateRequestDto? request = null,
        CancellationToken ct = default);

    Task<ServiceResult<WeeklyScheduleResponseDto>> GetWeeklyScheduleAsync(
        DateOnly? weekStart = null,
        CancellationToken ct = default);

    Task<ServiceResult<ShiftAssignmentDto>> AssignStaffAsync(
        CreateShiftAssignmentRequestDto request,
        CancellationToken ct = default);

    Task<ServiceResult<bool>> CancelAssignmentAsync(
        long assignmentId,
        CancelShiftAssignmentRequestDto? request = null,
        CancellationToken ct = default);

    Task<ServiceResult<bool>> PublishWeekAsync(
        DateOnly weekStart,
        CancellationToken ct = default);

    Task<ServiceResult<int>> CopyPreviousWeekAsync(
        DateOnly targetWeekStart,
        CancellationToken ct = default);
}
