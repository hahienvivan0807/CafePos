using System.Security.Cryptography;
using CafePos.Application.Constants;
using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.QuanLy.NhanVien;
using CafePos.Application.Entities;
using CafePos.Application.Interfaces.QuanLy.NhanVien;
using CafePos.Infrastructure.Data;
using CafePos.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace CafePos.Infrastructure.Services.QuanLy.NhanVien;

public class StaffManagementService : IStaffManagementService
{
    private readonly CafePosDbContext _db;
    private readonly UserManager<AppIdentityUser> _userManager;
    private readonly RoleManager<AppIdentityRole> _roleManager;

    public StaffManagementService(
        CafePosDbContext db,
        UserManager<AppIdentityUser> userManager,
        RoleManager<AppIdentityRole> roleManager)
    {
        _db = db;
        _userManager = userManager;
        _roleManager = roleManager;
    }

    public async Task<ServiceResult<IReadOnlyList<StaffMemberDto>>> GetStaffListAsync(
        string? search = null,
        string? role = null,
        string? status = null,
        CancellationToken ct = default)
    {
        var users = await _db.Users
            .AsNoTracking()
            .Include(u => u.HoSo)
            .OrderBy(u => u.UserName)
            .ToListAsync(ct);

        var userRoles = await _db.UserRoles.AsNoTracking().ToListAsync(ct);
        var rolesMap = await _db.Roles
            .AsNoTracking()
            .ToDictionaryAsync(r => r.Id, r => r.Name ?? RoleNames.Staff, ct);

        var normalizedRoleFilter = NormalizeRoleFilter(role);
        var normalizedStatusFilter = status?.Trim().ToLowerInvariant();
        var keyword = search?.Trim().ToLowerInvariant();

        var list = new List<StaffMemberDto>(users.Count);

        foreach (var user in users)
        {
            var assignedRoleIds = userRoles
                .Where(ur => ur.UserId == user.Id)
                .Select(ur => ur.RoleId)
                .ToList();

            var roleNames = assignedRoleIds
                .Where(rolesMap.ContainsKey)
                .Select(id => rolesMap[id])
                .ToList();

            var effectiveRole = roleNames.Contains(RoleNames.Manager, StringComparer.OrdinalIgnoreCase)
                ? RoleNames.Manager
                : RoleNames.Staff;

            var username = user.UserName ?? string.Empty;
            var staffCode = username.ToUpperInvariant();
            var fullName = string.IsNullOrWhiteSpace(user.HoSo?.HoTen) ? username : user.HoSo.HoTen;
            var phone = user.HoSo?.SoDienThoaiLienHe ?? user.PhoneNumber ?? string.Empty;

            if (normalizedRoleFilter is not null &&
                !string.Equals(effectiveRole, normalizedRoleFilter, StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            if (normalizedStatusFilter is "dang-hoat-dong" or "active" && !user.DangHoatDong)
            {
                continue;
            }

            if (normalizedStatusFilter is "da-khoa" or "locked" or "inactive" && user.DangHoatDong)
            {
                continue;
            }

            if (!string.IsNullOrEmpty(keyword))
            {
                var matches = fullName.ToLowerInvariant().Contains(keyword) ||
                              staffCode.ToLowerInvariant().Contains(keyword) ||
                              username.ToLowerInvariant().Contains(keyword) ||
                              phone.ToLowerInvariant().Contains(keyword);
                if (!matches)
                {
                    continue;
                }
            }

            list.Add(new StaffMemberDto(
                user.Id,
                staffCode,
                fullName,
                phone,
                username,
                effectiveRole,
                user.DangHoatDong));
        }

        return ServiceResult<IReadOnlyList<StaffMemberDto>>.Success(list);
    }

    public async Task<ServiceResult<StaffMemberDto>> CreateStaffAsync(
        CreateStaffRequestDto request,
        CancellationToken ct = default)
    {
        var fullName = request.FullName?.Trim() ?? string.Empty;
        var phone = request.PhoneNumber?.Trim() ?? string.Empty;
        var username = request.Username?.Trim() ?? string.Empty;

        if (string.IsNullOrWhiteSpace(fullName))
        {
            return ServiceResult<StaffMemberDto>.Failure(
                "Vui lòng nhập họ và tên nhân viên.", "INVALID_FULLNAME", 400);
        }

        if (string.IsNullOrWhiteSpace(phone))
        {
            return ServiceResult<StaffMemberDto>.Failure(
                "Vui lòng nhập số điện thoại di động.", "INVALID_PHONE", 400);
        }

        if (string.IsNullOrWhiteSpace(username))
        {
            return ServiceResult<StaffMemberDto>.Failure(
                "Vui lòng nhập tên đăng nhập POS.", "INVALID_USERNAME", 400);
        }

        var targetRole = NormalizeRoleInput(request.Role);
        if (targetRole is null)
        {
            return ServiceResult<StaffMemberDto>.Failure(
                "Vai trò không hợp lệ. Chỉ chấp nhận Nhân viên (Staff) hoặc Quản lý (Manager).",
                "INVALID_ROLE", 400);
        }

        var normalizedUserName = username.ToUpperInvariant();
        var exists = await _db.Users.AnyAsync(
            u => u.NormalizedUserName == normalizedUserName, ct);
        if (exists)
        {
            return ServiceResult<StaffMemberDto>.Failure(
                $"Tên đăng nhập '{username}' đã tồn tại trong hệ thống.",
                "USERNAME_EXISTS", 409);
        }

        if (!await _roleManager.RoleExistsAsync(targetRole))
        {
            await _roleManager.CreateAsync(new AppIdentityRole
            {
                Id = Guid.NewGuid(),
                Name = targetRole,
                NormalizedName = targetRole.ToUpperInvariant(),
                ConcurrencyStamp = Guid.NewGuid().ToString()
            });
        }

        await using var tx = await _db.Database.BeginTransactionAsync(ct);

        var newUser = new AppIdentityUser
        {
            Id = Guid.NewGuid(),
            UserName = username,
            NormalizedUserName = normalizedUserName,
            PhoneNumber = phone,
            DangHoatDong = request.IsActive,
            LockoutEnabled = true
        };

        // Sinh mật khẩu khởi tạo ngẫu nhiên đạt chuẩn độ dài >= 6 có chữ số (không lưu/log plaintext)
        var generatedTempPassword = GenerateSecureTempPassword();
        var createResult = await _userManager.CreateAsync(newUser, generatedTempPassword);
        if (!createResult.Succeeded)
        {
            await tx.RollbackAsync(ct);
            var errMsg = string.Join("; ", createResult.Errors.Select(e => e.Description));
            return ServiceResult<StaffMemberDto>.Failure(
                $"Không thể tạo tài khoản nhân viên: {errMsg}",
                "CREATE_USER_FAILED", 400);
        }

        var roleResult = await _userManager.AddToRoleAsync(newUser, targetRole);
        if (!roleResult.Succeeded)
        {
            await tx.RollbackAsync(ct);
            return ServiceResult<StaffMemberDto>.Failure(
                "Không thể gán vai trò cho tài khoản nhân viên.",
                "ASSIGN_ROLE_FAILED", 500);
        }

        var profile = new HoSoNguoiDung
        {
            IdNguoiDung = newUser.Id,
            HoTen = fullName,
            SoDienThoaiLienHe = phone,
            CapNhatLuc = DateTimeOffset.UtcNow
        };
        _db.HoSoNguoiDungs.Add(profile);
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        var dto = new StaffMemberDto(
            newUser.Id,
            username.ToUpperInvariant(),
            fullName,
            phone,
            username,
            targetRole,
            newUser.DangHoatDong);

        return ServiceResult<StaffMemberDto>.Success(
            dto,
            $"Đã thêm nhân viên '{fullName}' thành công.",
            201);
    }

    public async Task<ServiceResult<StaffMemberDto>> UpdateStaffAsync(
        Guid staffUserId,
        Guid currentManagerId,
        UpdateStaffRequestDto request,
        CancellationToken ct = default)
    {
        var fullName = request.FullName?.Trim() ?? string.Empty;
        var phone = request.PhoneNumber?.Trim() ?? string.Empty;

        if (string.IsNullOrWhiteSpace(fullName))
        {
            return ServiceResult<StaffMemberDto>.Failure(
                "Họ và tên không được để trống.", "INVALID_FULLNAME", 400);
        }

        if (string.IsNullOrWhiteSpace(phone))
        {
            return ServiceResult<StaffMemberDto>.Failure(
                "Số điện thoại không được để trống.", "INVALID_PHONE", 400);
        }

        var targetRole = NormalizeRoleInput(request.Role);
        if (targetRole is null)
        {
            return ServiceResult<StaffMemberDto>.Failure(
                "Vai trò không hợp lệ.", "INVALID_ROLE", 400);
        }

        if (staffUserId == currentManagerId)
        {
            if (!request.IsActive)
            {
                return ServiceResult<StaffMemberDto>.Failure(
                    "Bạn không thể tự khóa tài khoản Quản lý đang đăng nhập.",
                    "CANNOT_LOCK_SELF", 400);
            }

            if (!string.Equals(targetRole, RoleNames.Manager, StringComparison.OrdinalIgnoreCase))
            {
                return ServiceResult<StaffMemberDto>.Failure(
                    "Bạn không thể tự hạ quyền Manager của chính mình.",
                    "CANNOT_DEMOTE_SELF", 400);
            }
        }

        await using var tx = await _db.Database.BeginTransactionAsync(ct);

        var user = await _db.Users
            .Include(u => u.HoSo)
            .FirstOrDefaultAsync(u => u.Id == staffUserId, ct);

        if (user is null)
        {
            return ServiceResult<StaffMemberDto>.Failure(
                "Không tìm thấy nhân viên cần chỉnh sửa.", "STAFF_NOT_FOUND", 404);
        }

        var currentRoles = await _userManager.GetRolesAsync(user);
        var roleChanged = !currentRoles.Contains(targetRole, StringComparer.OrdinalIgnoreCase) ||
                          currentRoles.Count != 1;
        var statusChanged = user.DangHoatDong != request.IsActive;

        user.DangHoatDong = request.IsActive;
        user.PhoneNumber = phone;

        if (user.HoSo is null)
        {
            user.HoSo = new HoSoNguoiDung
            {
                IdNguoiDung = user.Id,
                HoTen = fullName,
                SoDienThoaiLienHe = phone,
                CapNhatLuc = DateTimeOffset.UtcNow
            };
            _db.HoSoNguoiDungs.Add(user.HoSo);
        }
        else
        {
            user.HoSo.HoTen = fullName;
            user.HoSo.SoDienThoaiLienHe = phone;
            user.HoSo.CapNhatLuc = DateTimeOffset.UtcNow;
        }

        if (roleChanged)
        {
            if (currentRoles.Count > 0)
            {
                await _userManager.RemoveFromRolesAsync(user, currentRoles);
            }
            if (!await _roleManager.RoleExistsAsync(targetRole))
            {
                await _roleManager.CreateAsync(new AppIdentityRole
                {
                    Id = Guid.NewGuid(),
                    Name = targetRole,
                    NormalizedName = targetRole.ToUpperInvariant(),
                    ConcurrencyStamp = Guid.NewGuid().ToString()
                });
            }
            await _userManager.AddToRoleAsync(user, targetRole);
        }

        // Thu hồi ngay phiên cookie cũ nếu tài khoản bị khóa hoặc thay đổi vai trò
        if (roleChanged || statusChanged)
        {
            await _userManager.UpdateSecurityStampAsync(user);
        }

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        var username = user.UserName ?? string.Empty;
        var dto = new StaffMemberDto(
            user.Id,
            username.ToUpperInvariant(),
            fullName,
            phone,
            username,
            targetRole,
            user.DangHoatDong);

        return ServiceResult<StaffMemberDto>.Success(
            dto,
            $"Đã cập nhật hồ sơ nhân viên '{fullName}' thành công.");
    }

    public async Task<ServiceResult<bool>> DeleteStaffAsync(
        Guid staffUserId,
        Guid currentManagerId,
        CancellationToken ct = default)
    {
        if (staffUserId == currentManagerId)
        {
            return ServiceResult<bool>.Failure(
                "Bạn không thể tự xóa tài khoản Quản lý đang đăng nhập.",
                "CANNOT_DELETE_SELF", 400);
        }

        var user = await _db.Users
            .Include(u => u.HoSo)
            .FirstOrDefaultAsync(u => u.Id == staffUserId, ct);

        if (user is null)
        {
            return ServiceResult<bool>.Failure(
                "Không tìm thấy tài khoản nhân viên cần xóa.", "STAFF_NOT_FOUND", 404);
        }

        // Kiểm tra ràng buộc lịch sử giao dịch POS để bảo vệ toàn vẹn dữ liệu
        var hasHistory =
            await _db.CaLamViecs.AnyAsync(c => c.IdNguoiDung == staffUserId, ct) ||
            await _db.LuotBans.AnyAsync(l => l.IdNguoiMo == staffUserId || l.IdNguoiTraBan == staffUserId, ct) ||
            await _db.DonHangs.AnyAsync(d => d.IdNguoiTao == staffUserId, ct) ||
            await _db.DongMons.AnyAsync(dm => dm.IdNguoiGhiMon == staffUserId, ct) ||
            await _db.YeuCauHuyMons.AnyAsync(y => y.IdNguoiYeuCau == staffUserId || y.IdNguoiXuLy == staffUserId, ct);

        if (hasHistory)
        {
            user.DangHoatDong = false;
            await _userManager.UpdateSecurityStampAsync(user);
            await _db.SaveChangesAsync(ct);

            return ServiceResult<bool>.Failure(
                "Nhân viên đã có lịch sử ca làm hoặc đơn hàng POS nên không thể xóa vật lý. Hệ thống đã chuyển tài khoản sang trạng thái Đã khóa để bảo toàn dữ liệu.",
                "STAFF_HAS_HISTORY_LOCKED", 409);
        }

        var deleteResult = await _userManager.DeleteAsync(user);
        if (!deleteResult.Succeeded)
        {
            return ServiceResult<bool>.Failure(
                "Không thể xóa tài khoản nhân viên.", "DELETE_STAFF_FAILED", 500);
        }

        return ServiceResult<bool>.Success(
            true,
            $"Đã xóa tài khoản nhân viên '{user.HoSo?.HoTen ?? user.UserName}' thành công.");
    }

    public async Task<ServiceResult<bool>> ResetStaffPasswordAsync(
        Guid staffUserId,
        Guid currentManagerId,
        ResetStaffPasswordRequestDto request,
        CancellationToken ct = default)
    {
        var newPassword = request.NewPassword ?? string.Empty;
        var confirmPassword = request.ConfirmPassword ?? string.Empty;

        if (string.IsNullOrWhiteSpace(newPassword))
        {
            return ServiceResult<bool>.Failure(
                "Vui lòng nhập mật khẩu mới.", "INVALID_PASSWORD", 400);
        }

        if (newPassword.Length < 6 || !newPassword.Any(char.IsDigit))
        {
            return ServiceResult<bool>.Failure(
                "Mật khẩu mới phải có tối thiểu 6 ký tự và chứa ít nhất 1 chữ số.",
                "WEAK_PASSWORD", 400);
        }

        if (!string.Equals(newPassword, confirmPassword, StringComparison.Ordinal))
        {
            return ServiceResult<bool>.Failure(
                "Mật khẩu xác nhận không khớp với mật khẩu mới.",
                "PASSWORD_MISMATCH", 400);
        }

        var user = await _db.Users
            .Include(u => u.HoSo)
            .FirstOrDefaultAsync(u => u.Id == staffUserId, ct);

        if (user is null)
        {
            return ServiceResult<bool>.Failure(
                "Không tìm thấy tài khoản nhân viên cần đặt lại mật khẩu.",
                "STAFF_NOT_FOUND", 404);
        }

        var resetToken = await _userManager.GeneratePasswordResetTokenAsync(user);
        var resetResult = await _userManager.ResetPasswordAsync(user, resetToken, newPassword);
        if (!resetResult.Succeeded)
        {
            var errMsg = string.Join("; ", resetResult.Errors.Select(e => e.Description));
            return ServiceResult<bool>.Failure(
                $"Không thể đặt lại mật khẩu: {errMsg}",
                "RESET_PASSWORD_FAILED", 400);
        }

        // Gỡ khóa tạm do nhập sai nhiều lần (nếu có) để nhân viên đăng nhập được ngay bằng mật khẩu mới
        await _userManager.SetLockoutEndDateAsync(user, null);
        await _userManager.ResetAccessFailedCountAsync(user);

        var displayName = user.HoSo?.HoTen ?? user.UserName ?? "nhân viên";
        var suffix = staffUserId == currentManagerId
            ? " Vui lòng đăng nhập lại bằng mật khẩu mới nếu phiên hiện tại kết thúc."
            : string.Empty;

        return ServiceResult<bool>.Success(
            true,
            $"Đã đặt lại mật khẩu cho '{displayName}' thành công.{suffix}");
    }

    private static string? NormalizeRoleInput(string? raw)
    {
        var v = raw?.Trim().ToLowerInvariant();
        return v switch
        {
            "staff" or "nhan-vien" => RoleNames.Staff,
            "manager" or "quan-ly" => RoleNames.Manager,
            _ => null
        };
    }

    private static string? NormalizeRoleFilter(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;
        return NormalizeRoleInput(raw);
    }

    private static string GenerateSecureTempPassword()
    {
        var pin = RandomNumberGenerator.GetInt32(1000, 9999);
        var suffix = RandomNumberGenerator.GetInt32(10, 99);
        return $"Pos{pin}{suffix}";
    }
}
