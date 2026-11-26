using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.XacThuc;

namespace CafePos.Application.Interfaces.XacThuc;

public interface IAuthService
{
    Task<ServiceResult<UserSessionData>> AuthenticateAsync(
        LoginRequestDto request,
        CancellationToken ct = default);

    Task<ServiceResult<UserSessionData>> GetCurrentSessionAsync(
        Guid userId,
        CancellationToken ct = default);

    Task<bool> IsSessionStillValidAsync(
        Guid userId,
        string? cookieSecurityStamp,
        CancellationToken ct = default);

    Task<ServiceResult<UserProfileDto>> UpdateProfileAsync(
        Guid userId,
        UpdateProfileRequestDto request,
        CancellationToken ct = default);
}
