using CafePos.Application.Constants;
using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.XacThuc;
using CafePos.Application.Interfaces.CaLam;
using CafePos.Application.Interfaces.XacThuc;
using CafePos.Infrastructure.Data;
using CafePos.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace CafePos.Infrastructure.Services.XacThuc;

public class AuthService : IAuthService
{
    private readonly CafePosDbContext _db;
    private readonly UserManager<AppIdentityUser> _userManager;
    private readonly SignInManager<AppIdentityUser> _signInManager;
    private readonly IShiftService _shiftService;

    public AuthService(
        CafePosDbContext db,
        UserManager<AppIdentityUser> userManager,
        SignInManager<AppIdentityUser> signInManager,
        IShiftService shiftService)
    {
        _db = db;
        _userManager = userManager;
        _signInManager = signInManager;
        _shiftService = shiftService;
    }

    public async Task<ServiceResult<UserSessionData>> AuthenticateAsync(
        LoginRequestDto request,
        CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.Identifier) || string.IsNullOrEmpty(request.Password))
        {
            return ServiceResult<UserSessionData>.Failure(
                "Vui lòng nhập đầy đủ mã nhân viên/tên đăng nhập và mật khẩu.",
                "INVALID_INPUT",
                400);
        }

        var normalizedInput = request.Identifier.Trim().ToUpperInvariant();

        // Tìm tài khoản trong bảng pos."NguoiDung" theo TenDangNhapChuanHoa (hoặc EmailChuanHoa)
        var user = await _db.Users
            .Include(u => u.HoSo)
            .FirstOrDefaultAsync(
                u => u.NormalizedUserName == normalizedInput ||
                     u.NormalizedEmail == normalizedInput,
                ct);

        if (user is null)
        {
            return ServiceResult<UserSessionData>.Failure(
                "Tên đăng nhập hoặc mật khẩu không chính xác.",
                "INVALID_CREDENTIALS",
                401);
        }

        // Quy tắc nghiệp vụ (CafePos.Application): Chỉ cho phép tài khoản đang hoạt động đăng nhập
        if (!user.DangHoatDong)
        {
            return ServiceResult<UserSessionData>.Failure(
                "Tài khoản đã ngừng hoạt động. Vui lòng liên hệ Quản lý.",
                "ACCOUNT_INACTIVE",
                403);
        }

        // Kiểm tra mật khẩu băm + đếm lần nhập sai (SoLanDangNhapThatBai) + khóa tạm (KhoaDen) qua ASP.NET Core Identity
        var signInResult = await _signInManager.CheckPasswordSignInAsync(
            user,
            request.Password,
            lockoutOnFailure: true);

        if (signInResult.IsLockedOut)
        {
            var lockoutEnd = await _userManager.GetLockoutEndDateAsync(user);
            var remainingMinutes = lockoutEnd.HasValue
                ? Math.Max(1, (int)Math.Ceiling((lockoutEnd.Value - DateTimeOffset.UtcNow).TotalMinutes))
                : 15;

            return ServiceResult<UserSessionData>.Failure(
                $"Tài khoản đang tạm khóa do nhập sai mật khẩu quá nhiều lần. Vui lòng thử lại sau {remainingMinutes} phút hoặc liên hệ Quản lý.",
                "ACCOUNT_LOCKED_OUT",
                423);
        }

        if (!signInResult.Succeeded)
        {
            var failedCount = await _userManager.GetAccessFailedCountAsync(user);
            var maxAttempts = _userManager.Options.Lockout.MaxFailedAccessAttempts;
            var remainingAttempts = Math.Max(0, maxAttempts - failedCount);

            var msg = remainingAttempts <= 2 && remainingAttempts > 0
                ? $"Tên đăng nhập hoặc mật khẩu không chính xác (còn {remainingAttempts} lần thử trước khi khóa tạm)."
                : "Tên đăng nhập hoặc mật khẩu không chính xác.";

            return ServiceResult<UserSessionData>.Failure(
                msg,
                "INVALID_CREDENTIALS",
                401);
        }

        var sessionResult = await BuildUserSessionDataAsync(user, ct);
        return ServiceResult<UserSessionData>.Success(
            sessionResult,
            "Đăng nhập thành công.");
    }

    public async Task<ServiceResult<UserSessionData>> GetCurrentSessionAsync(
        Guid userId,
        CancellationToken ct = default)
    {
        var user = await _db.Users
            .Include(u => u.HoSo)
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user is null || !user.DangHoatDong)
        {
            return ServiceResult<UserSessionData>.Failure(
                "Phiên đăng nhập không còn hợp lệ hoặc tài khoản đã bị khóa.",
                "SESSION_INVALID",
                401);
        }

        if (await _userManager.IsLockedOutAsync(user))
        {
            return ServiceResult<UserSessionData>.Failure(
                "Tài khoản đang bị tạm khóa.",
                "ACCOUNT_LOCKED_OUT",
                423);
        }

        var sessionData = await BuildUserSessionDataAsync(user, ct);
        return ServiceResult<UserSessionData>.Success(sessionData);
    }

    public async Task<bool> IsSessionStillValidAsync(
        Guid userId,
        string? cookieSecurityStamp,
        CancellationToken ct = default)
    {
        var user = await _db.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user is null || !user.DangHoatDong)
        {
            return false;
        }

        if (user.LockoutEnabled && user.LockoutEnd.HasValue && user.LockoutEnd.Value > DateTimeOffset.UtcNow)
        {
            return false;
        }

        if (!string.IsNullOrEmpty(cookieSecurityStamp) &&
            !string.Equals(user.SecurityStamp, cookieSecurityStamp, StringComparison.Ordinal))
        {
            return false;
        }

        return true;
    }

    public async Task<ServiceResult<UserProfileDto>> UpdateProfileAsync(
        Guid userId,
        UpdateProfileRequestDto request,
        CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.FullName))
        {
            return ServiceResult<UserProfileDto>.Failure(
                "Họ tên không được để trống.",
                "INVALID_FULLNAME",
                400);
        }

        await using var tx = await _db.Database.BeginTransactionAsync(ct);

        var user = await _db.Users
            .Include(u => u.HoSo)
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user is null || !user.DangHoatDong)
        {
            return ServiceResult<UserProfileDto>.Failure(
                "Không tìm thấy tài khoản hợp lệ.",
                "USER_NOT_FOUND",
                404);
        }

        if (user.HoSo is null)
        {
            user.HoSo = new Application.Entities.HoSoNguoiDung
            {
                IdNguoiDung = user.Id,
                HoTen = request.FullName.Trim(),
                SoDienThoaiLienHe = request.PhoneNumber?.Trim(),
                CapNhatLuc = DateTimeOffset.UtcNow
            };
            _db.HoSoNguoiDungs.Add(user.HoSo);
        }
        else
        {
            user.HoSo.HoTen = request.FullName.Trim();
            user.HoSo.SoDienThoaiLienHe = request.PhoneNumber?.Trim();
            user.HoSo.CapNhatLuc = DateTimeOffset.UtcNow;
        }

        user.PhoneNumber = request.PhoneNumber?.Trim();
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        var roles = await _userManager.GetRolesAsync(user);
        var roleTitle = roles.Contains(RoleNames.Manager) ? "Quản lý cửa hàng" : "Nhân viên POS";
        var profile = new UserProfileDto(
            user.Id,
            user.UserName ?? string.Empty,
            (user.UserName ?? "POS").ToUpperInvariant(),
            user.HoSo.HoTen,
            roleTitle,
            user.HoSo.SoDienThoaiLienHe ?? user.PhoneNumber,
            roles.ToList());

        return ServiceResult<UserProfileDto>.Success(profile, "Cập nhật hồ sơ thành công.");
    }

    private async Task<UserSessionData> BuildUserSessionDataAsync(
        AppIdentityUser user,
        CancellationToken ct)
    {
        var roles = await _userManager.GetRolesAsync(user);
        var activeShift = await _shiftService.GetActiveShiftAsync(user.Id, ct);
        var roleTitle = roles.Contains(RoleNames.Manager)
            ? "Quản lý cửa hàng"
            : "Nhân viên Quầy & Phục vụ";

        var profile = new UserProfileDto(
            user.Id,
            user.UserName ?? string.Empty,
            (user.UserName ?? "POS").ToUpperInvariant(),
            user.HoSo?.HoTen ?? (user.UserName ?? "Nhân viên"),
            roleTitle,
            user.HoSo?.SoDienThoaiLienHe ?? user.PhoneNumber,
            roles.ToList());

        return new UserSessionData(
            profile,
            activeShift,
            user.SecurityStamp ?? string.Empty);
    }
}
