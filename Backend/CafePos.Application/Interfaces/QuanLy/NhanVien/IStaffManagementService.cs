using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.QuanLy.NhanVien;

namespace CafePos.Application.Interfaces.QuanLy.NhanVien;

public interface IStaffManagementService
{
    Task<ServiceResult<IReadOnlyList<StaffMemberDto>>> GetStaffListAsync(
        string? search = null,
        string? role = null,
        string? status = null,
        CancellationToken ct = default);

    Task<ServiceResult<StaffMemberDto>> CreateStaffAsync(
        CreateStaffRequestDto request,
        CancellationToken ct = default);

    Task<ServiceResult<StaffMemberDto>> UpdateStaffAsync(
        Guid staffUserId,
        Guid currentManagerId,
        UpdateStaffRequestDto request,
        CancellationToken ct = default);

    Task<ServiceResult<bool>> DeleteStaffAsync(
        Guid staffUserId,
        Guid currentManagerId,
        CancellationToken ct = default);

    Task<ServiceResult<bool>> ResetStaffPasswordAsync(
        Guid staffUserId,
        Guid currentManagerId,
        ResetStaffPasswordRequestDto request,
        CancellationToken ct = default);
}
