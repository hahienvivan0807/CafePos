namespace CafePos.Application.DTOs.CaLam;

public record ShiftDto(
    Guid ShiftId,
    Guid UserId,
    string Status,
    DateTimeOffset StartedAt,
    DateTimeOffset? EndedAt,
    string? OpenNote,
    string? CloseNote
);

public record StartShiftRequestDto(string? Note = null);

public record EndShiftRequestDto(string? Note = null);
