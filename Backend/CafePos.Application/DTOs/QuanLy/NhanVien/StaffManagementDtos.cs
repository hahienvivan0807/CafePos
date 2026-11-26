namespace CafePos.Application.DTOs.QuanLy.NhanVien;

public record StaffMemberDto(
    Guid Id,
    string StaffCode,
    string FullName,
    string PhoneNumber,
    string Username,
    string Role,        // "Staff" | "Manager"
    bool IsActive
);

public record CreateStaffRequestDto(
    string? StaffCode,
    string FullName,
    string PhoneNumber,
    string Username,
    string Role,        // "Staff" | "Manager" | "nhan-vien" | "quan-ly"
    bool IsActive = true
);

public record UpdateStaffRequestDto(
    string FullName,
    string PhoneNumber,
    string Role,        // "Staff" | "Manager" | "nhan-vien" | "quan-ly"
    bool IsActive
);

public record ResetStaffPasswordRequestDto(
    string NewPassword,
    string ConfirmPassword
);
