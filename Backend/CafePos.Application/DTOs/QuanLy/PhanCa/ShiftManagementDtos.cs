namespace CafePos.Application.DTOs.QuanLy.PhanCa;

public record ShiftTemplateDto(
    string Code,
    string Name,
    string StartTime,          // "HH:mm"
    string EndTime,            // "HH:mm"
    bool IsOvernight,
    int BreakMinutes,
    int BaristaQuota,
    int CashierQuota,
    int FloorQuota,
    bool IsActive,
    string? HandoverNote,
    int SortOrder,
    double DurationHours,
    bool HasUsageHistory,
    DateTimeOffset UpdatedAt
);

public record UpsertShiftTemplateRequestDto(
    string Code,
    string Name,
    string StartTime,          // "HH:mm"
    string EndTime,            // "HH:mm"
    bool IsOvernight = false,
    int BreakMinutes = 0,
    int BaristaQuota = 1,
    int CashierQuota = 1,
    int FloorQuota = 1,
    bool IsActive = true,
    string? HandoverNote = null
);

public record DeleteShiftTemplateRequestDto(
    string? Reason = null
);

public record ShiftAssignmentDto(
    long Id,
    DateOnly WorkDate,
    string ShiftCode,
    Guid StaffUserId,
    string StaffCode,
    string StaffName,
    string Position,           // "PhaChe" | "ThuNgan" | "PhucVu" | "TruongCa"
    string PositionLabel,
    string StartTime,          // "HH:mm"
    string EndTime,            // "HH:mm"
    double DurationHours,
    string WeekStatus,         // "Nhap" | "DaCongBo"
    string Status              // "HoatDong" | "DaHuy"
);

public record StaffOptionDto(
    Guid UserId,
    string StaffCode,
    string FullName,
    string Role
);

public record WeeklyScheduleResponseDto(
    DateOnly WeekStart,
    DateOnly WeekEnd,
    string WeekStatus,         // "Nhap" | "DaCongBo"
    double TotalPlannedHours,
    int UnderstaffedSlotsCount,
    IReadOnlyList<ShiftTemplateDto> Templates,
    IReadOnlyList<ShiftAssignmentDto> Assignments,
    IReadOnlyList<StaffOptionDto> ActiveStaff
);

public record CreateShiftAssignmentRequestDto(
    DateOnly WorkDate,
    string ShiftCode,
    Guid StaffUserId,
    string Position,
    string? StartTime = null,
    string? EndTime = null
);

public record CancelShiftAssignmentRequestDto(
    string? Reason = null
);

public record WeekActionRequestDto(
    DateOnly WeekStart
);
