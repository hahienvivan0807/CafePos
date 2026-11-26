using CafePos.Application.DTOs.CaLam;

namespace CafePos.Application.DTOs.XacThuc;

public record LoginRequestDto(
    string Identifier,
    string Password,
    bool RememberMe = false
);

public record UserProfileDto(
    Guid UserId,
    string Username,
    string StaffCode,
    string FullName,
    string Title,
    string? PhoneNumber,
    IReadOnlyList<string> Roles
);

public record UserSessionData(
    UserProfileDto User,
    ShiftDto? ActiveShift,
    string SecurityStamp
);

public record AuthSessionResponseDto(
    UserProfileDto User,
    ShiftDto? ActiveShift,
    string CsrfToken,
    string NextAction // "START_SHIFT" | "CONTINUE_SHIFT" | "ENTER_MANAGER"
);

public record UpdateProfileRequestDto(
    string FullName,
    string? PhoneNumber
);
