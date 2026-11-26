using System.Globalization;
using CafePos.Application.Constants;
using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.QuanLy.PhanCa;
using CafePos.Application.Entities;
using CafePos.Application.Interfaces.QuanLy.PhanCa;
using CafePos.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace CafePos.Infrastructure.Services.QuanLy.PhanCa;

public class ShiftScheduleService : IShiftScheduleService
{
    private static readonly TimeSpan VietnamOffset = TimeSpan.FromHours(7);
    private readonly CafePosDbContext _db;

    public ShiftScheduleService(CafePosDbContext db)
    {
        _db = db;
    }

    public async Task<ServiceResult<IReadOnlyList<ShiftTemplateDto>>> GetTemplatesAsync(
        string? search = null,
        string? status = null,
        CancellationToken ct = default)
    {
        var templates = await _db.KhungCaLams
            .AsNoTracking()
            .OrderBy(k => k.ThuTu)
            .ThenBy(k => k.GioBatDau)
            .ToListAsync(ct);

        var usedInOrders = await _db.DonHangs
            .AsNoTracking()
            .Where(d => d.MaKhungCa != null)
            .Select(d => d.MaKhungCa!)
            .Distinct()
            .ToListAsync(ct);

        var usedInAssignments = await _db.PhanCaNhanViens
            .AsNoTracking()
            .Select(p => p.MaKhungCa)
            .Distinct()
            .ToListAsync(ct);

        var usedSet = new HashSet<string>(
            usedInOrders.Concat(usedInAssignments),
            StringComparer.OrdinalIgnoreCase);

        var keyword = search?.Trim().ToLowerInvariant();
        var statusFilter = status?.Trim().ToLowerInvariant();

        var result = new List<ShiftTemplateDto>(templates.Count);
        foreach (var k in templates)
        {
            if (statusFilter is "active" or "dang-ap-dung" && !k.DangApDung) continue;
            if (statusFilter is "inactive" or "ngung-su-dung" && k.DangApDung) continue;
            if (!string.IsNullOrEmpty(keyword) &&
                !k.Ma.ToLowerInvariant().Contains(keyword) &&
                !k.TenCa.ToLowerInvariant().Contains(keyword))
            {
                continue;
            }

            result.Add(ToTemplateDto(k, usedSet.Contains(k.Ma)));
        }

        return ServiceResult<IReadOnlyList<ShiftTemplateDto>>.Success(
            result,
            "Tải danh mục khung ca thành công.");
    }

    public async Task<ServiceResult<ShiftTemplateDto>> CreateTemplateAsync(
        UpsertShiftTemplateRequestDto request,
        CancellationToken ct = default)
    {
        var code = (request.Code ?? string.Empty).Trim().ToUpperInvariant().Replace(' ', '_');
        var name = (request.Name ?? string.Empty).Trim();

        if (string.IsNullOrWhiteSpace(code) || code.Length > 24)
        {
            return ServiceResult<ShiftTemplateDto>.Failure(
                "Vui lòng nhập mã khung ca hợp lệ (tối đa 24 ký tự).",
                "INVALID_CODE",
                400);
        }

        if (string.IsNullOrWhiteSpace(name))
        {
            return ServiceResult<ShiftTemplateDto>.Failure(
                "Vui lòng nhập tên khung ca.",
                "INVALID_NAME",
                400);
        }

        if (!TryParseTime(request.StartTime, out var start) ||
            !TryParseTime(request.EndTime, out var end))
        {
            return ServiceResult<ShiftTemplateDto>.Failure(
                "Định dạng giờ không hợp lệ (cần dạng HH:mm).",
                "INVALID_TIME",
                400);
        }

        if (!request.IsOvernight && end <= start)
        {
            return ServiceResult<ShiftTemplateDto>.Failure(
                "Giờ kết thúc phải lớn hơn giờ bắt đầu (hoặc chọn 'Ca kết thúc vào ngày hôm sau' đối với ca qua đêm).",
                "INVALID_TIME_RANGE",
                400);
        }

        if (await _db.KhungCaLams.AnyAsync(k => k.Ma == code, ct))
        {
            return ServiceResult<ShiftTemplateDto>.Failure(
                $"Mã khung ca '{code}' đã tồn tại trong hệ thống.",
                "TEMPLATE_EXISTS",
                409);
        }

        if (request.IsActive)
        {
            var overlap = await FindOverlappingActiveTemplateAsync(null, start, end, request.IsOvernight, ct);
            if (overlap is not null)
            {
                return ServiceResult<ShiftTemplateDto>.Failure(
                    $"Giờ ca bị trùng với [{overlap.TenCa}: {overlap.GioBatDau:HH\\:mm} - {overlap.GioKetThuc:HH\\:mm}]. Vui lòng điều chỉnh để không chồng chéo.",
                    "SHIFT_TIME_OVERLAP",
                    409);
            }
        }

        var maxOrder = await _db.KhungCaLams.AnyAsync(ct)
            ? await _db.KhungCaLams.MaxAsync(k => k.ThuTu, ct)
            : 0;

        var entity = new KhungCaLam
        {
            Ma = code,
            TenCa = name,
            GioBatDau = start,
            GioKetThuc = end,
            QuaDem = request.IsOvernight,
            NghiGiuaCaPhut = Math.Max(0, request.BreakMinutes),
            DinhBienPhaChe = Math.Max(0, request.BaristaQuota),
            DinhBienThuNgan = Math.Max(0, request.CashierQuota),
            DinhBienPhucVu = Math.Max(0, request.FloorQuota),
            DangApDung = request.IsActive,
            GhiChuBanGiao = string.IsNullOrWhiteSpace(request.HandoverNote) ? null : request.HandoverNote.Trim(),
            ThuTu = maxOrder + 1,
            CapNhatLuc = DateTimeOffset.UtcNow
        };

        _db.KhungCaLams.Add(entity);
        await _db.SaveChangesAsync(ct);

        return ServiceResult<ShiftTemplateDto>.Success(
            ToTemplateDto(entity, false),
            $"Đã tạo khung ca '{name}' thành công.",
            201);
    }

    public async Task<ServiceResult<ShiftTemplateDto>> UpdateTemplateAsync(
        string code,
        UpsertShiftTemplateRequestDto request,
        CancellationToken ct = default)
    {
        var normalizedCode = (code ?? string.Empty).Trim().ToUpperInvariant();
        var entity = await _db.KhungCaLams.FirstOrDefaultAsync(k => k.Ma == normalizedCode, ct);
        if (entity is null)
        {
            return ServiceResult<ShiftTemplateDto>.Failure(
                "Không tìm thấy khung ca cần chỉnh sửa.",
                "TEMPLATE_NOT_FOUND",
                404);
        }

        var name = (request.Name ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(name))
        {
            return ServiceResult<ShiftTemplateDto>.Failure(
                "Tên khung ca không được để trống.",
                "INVALID_NAME",
                400);
        }

        if (!TryParseTime(request.StartTime, out var start) ||
            !TryParseTime(request.EndTime, out var end))
        {
            return ServiceResult<ShiftTemplateDto>.Failure(
                "Định dạng giờ không hợp lệ (cần dạng HH:mm).",
                "INVALID_TIME",
                400);
        }

        if (!request.IsOvernight && end <= start)
        {
            return ServiceResult<ShiftTemplateDto>.Failure(
                "Giờ kết thúc phải lớn hơn giờ bắt đầu (hoặc chọn 'Ca kết thúc vào ngày hôm sau' đối với ca qua đêm).",
                "INVALID_TIME_RANGE",
                400);
        }

        if (request.IsActive)
        {
            var overlap = await FindOverlappingActiveTemplateAsync(normalizedCode, start, end, request.IsOvernight, ct);
            if (overlap is not null)
            {
                return ServiceResult<ShiftTemplateDto>.Failure(
                    $"Giờ ca bị trùng với [{overlap.TenCa}: {overlap.GioBatDau:HH\\:mm} - {overlap.GioKetThuc:HH\\:mm}]. Vui lòng điều chỉnh để không chồng chéo.",
                    "SHIFT_TIME_OVERLAP",
                    409);
            }
        }

        entity.TenCa = name;
        entity.GioBatDau = start;
        entity.GioKetThuc = end;
        entity.QuaDem = request.IsOvernight;
        entity.NghiGiuaCaPhut = Math.Max(0, request.BreakMinutes);
        entity.DinhBienPhaChe = Math.Max(0, request.BaristaQuota);
        entity.DinhBienThuNgan = Math.Max(0, request.CashierQuota);
        entity.DinhBienPhucVu = Math.Max(0, request.FloorQuota);
        entity.DangApDung = request.IsActive;
        entity.GhiChuBanGiao = string.IsNullOrWhiteSpace(request.HandoverNote) ? null : request.HandoverNote.Trim();
        entity.CapNhatLuc = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(ct);

        var hasUsage = await _db.DonHangs.AnyAsync(d => d.MaKhungCa == normalizedCode, ct) ||
                       await _db.PhanCaNhanViens.AnyAsync(p => p.MaKhungCa == normalizedCode, ct);

        return ServiceResult<ShiftTemplateDto>.Success(
            ToTemplateDto(entity, hasUsage),
            $"Đã cập nhật khung ca '{entity.TenCa}' thành công.");
    }

    public async Task<ServiceResult<bool>> DeleteOrDisableTemplateAsync(
        string code,
        DeleteShiftTemplateRequestDto? request = null,
        CancellationToken ct = default)
    {
        var normalizedCode = (code ?? string.Empty).Trim().ToUpperInvariant();
        var entity = await _db.KhungCaLams.FirstOrDefaultAsync(k => k.Ma == normalizedCode, ct);
        if (entity is null)
        {
            return ServiceResult<bool>.Failure(
                "Không tìm thấy khung ca cần xử lý.",
                "TEMPLATE_NOT_FOUND",
                404);
        }

        var hasUsage = await _db.DonHangs.AnyAsync(d => d.MaKhungCa == normalizedCode, ct) ||
                       await _db.PhanCaNhanViens.AnyAsync(p => p.MaKhungCa == normalizedCode, ct);

        if (hasUsage)
        {
            entity.DangApDung = false;
            if (!string.IsNullOrWhiteSpace(request?.Reason))
            {
                entity.GhiChuBanGiao = string.IsNullOrWhiteSpace(entity.GhiChuBanGiao)
                    ? $"[Ngừng sử dụng]: {request.Reason.Trim()}"
                    : $"{entity.GhiChuBanGiao}\n[Ngừng sử dụng]: {request.Reason.Trim()}";
            }
            entity.CapNhatLuc = DateTimeOffset.UtcNow;
            await _db.SaveChangesAsync(ct);

            return ServiceResult<bool>.Success(
                true,
                $"Khung ca '{entity.TenCa}' đã phát sinh hóa đơn hoặc lịch trực nên được chuyển sang Ngừng sử dụng để bảo toàn dữ liệu.");
        }

        _db.KhungCaLams.Remove(entity);
        await _db.SaveChangesAsync(ct);

        return ServiceResult<bool>.Success(
            true,
            $"Đã xóa khung ca '{entity.TenCa}' thành công.");
    }

    public async Task<ServiceResult<WeeklyScheduleResponseDto>> GetWeeklyScheduleAsync(
        DateOnly? weekStart = null,
        CancellationToken ct = default)
    {
        var todayLocal = DateOnly.FromDateTime(DateTimeOffset.UtcNow.ToOffset(VietnamOffset).DateTime);
        var anchor = weekStart ?? todayLocal;
        var diffToMonday = ((int)anchor.DayOfWeek + 6) % 7;
        var monday = anchor.AddDays(-diffToMonday);
        var sunday = monday.AddDays(6);

        var templates = await _db.KhungCaLams
            .AsNoTracking()
            .Where(k => k.DangApDung)
            .OrderBy(k => k.ThuTu)
            .ThenBy(k => k.GioBatDau)
            .ToListAsync(ct);

        var rawAssignments = await _db.PhanCaNhanViens
            .AsNoTracking()
            .Where(p => p.NgayLam >= monday && p.NgayLam <= sunday && p.TrangThai == "HoatDong")
            .OrderBy(p => p.NgayLam)
            .ThenBy(p => p.GioVao)
            .ToListAsync(ct);

        var users = await _db.Users
            .AsNoTracking()
            .Include(u => u.HoSo)
            .OrderBy(u => u.UserName)
            .ToListAsync(ct);

        var userRoles = await _db.UserRoles.AsNoTracking().ToListAsync(ct);
        var rolesMap = await _db.Roles.AsNoTracking().ToDictionaryAsync(r => r.Id, r => r.Name ?? RoleNames.Staff, ct);

        var userLookup = users.ToDictionary(u => u.Id);
        var activeStaff = users
            .Where(u => u.DangHoatDong)
            .Select(u =>
            {
                var rNames = userRoles.Where(ur => ur.UserId == u.Id && rolesMap.ContainsKey(ur.RoleId))
                    .Select(ur => rolesMap[ur.RoleId]).ToList();
                var role = rNames.Contains(RoleNames.Manager, StringComparer.OrdinalIgnoreCase)
                    ? RoleNames.Manager
                    : RoleNames.Staff;
                var username = u.UserName ?? string.Empty;
                var fullName = string.IsNullOrWhiteSpace(u.HoSo?.HoTen) ? username : u.HoSo.HoTen;
                return new StaffOptionDto(u.Id, username.ToUpperInvariant(), fullName, role);
            })
            .ToList();

        var assignments = rawAssignments.Select(p =>
        {
            userLookup.TryGetValue(p.IdNguoiDung, out var u);
            var staffCode = (u?.UserName ?? "NV").ToUpperInvariant();
            var staffName = string.IsNullOrWhiteSpace(u?.HoSo?.HoTen) ? staffCode : u!.HoSo!.HoTen;
            var hrs = ComputeHours(p.GioVao, p.GioRa, p.GioRa <= p.GioVao);
            return new ShiftAssignmentDto(
                p.Id,
                p.NgayLam,
                p.MaKhungCa,
                p.IdNguoiDung,
                staffCode,
                staffName,
                p.ViTri,
                FormatPositionLabel(p.ViTri),
                p.GioVao.ToString("HH:mm"),
                p.GioRa.ToString("HH:mm"),
                hrs,
                p.TrangThaiTuan,
                p.TrangThai);
        }).ToList();

        var totalHours = Math.Round(assignments.Sum(a => a.DurationHours), 1);
        var weekStatus = assignments.Count > 0 && assignments.All(a => a.WeekStatus == "DaCongBo")
            ? "DaCongBo"
            : "Nhap";

        var understaffed = 0;
        for (var i = 0; i < 7; i++)
        {
            var day = monday.AddDays(i);
            foreach (var t in templates)
            {
                var requiredTotal = t.DinhBienPhaChe + t.DinhBienThuNgan + t.DinhBienPhucVu;
                if (requiredTotal <= 0) continue;
                var assignedCount = assignments.Count(a => a.WorkDate == day && a.ShiftCode == t.Ma);
                if (assignedCount < requiredTotal) understaffed++;
            }
        }

        var templateDtos = templates.Select(t => ToTemplateDto(t, true)).ToList();

        return ServiceResult<WeeklyScheduleResponseDto>.Success(
            new WeeklyScheduleResponseDto(
                monday,
                sunday,
                weekStatus,
                totalHours,
                understaffed,
                templateDtos,
                assignments,
                activeStaff),
            "Tải lịch phân ca tuần thành công.");
    }

    public async Task<ServiceResult<ShiftAssignmentDto>> AssignStaffAsync(
        CreateShiftAssignmentRequestDto request,
        CancellationToken ct = default)
    {
        var code = (request.ShiftCode ?? string.Empty).Trim().ToUpperInvariant();
        var template = await _db.KhungCaLams.AsNoTracking().FirstOrDefaultAsync(k => k.Ma == code, ct);
        if (template is null || !template.DangApDung)
        {
            return ServiceResult<ShiftAssignmentDto>.Failure(
                "Khung ca không tồn tại hoặc đã ngừng sử dụng.",
                "TEMPLATE_INVALID",
                400);
        }

        var user = await _db.Users.AsNoTracking().Include(u => u.HoSo)
            .FirstOrDefaultAsync(u => u.Id == request.StaffUserId, ct);
        if (user is null || !user.DangHoatDong)
        {
            return ServiceResult<ShiftAssignmentDto>.Failure(
                "Nhân viên không tồn tại hoặc tài khoản đang bị khóa.",
                "STAFF_INACTIVE",
                400);
        }

        var start = TryParseTime(request.StartTime, out var parsedStart) ? parsedStart : template.GioBatDau;
        var end = TryParseTime(request.EndTime, out var parsedEnd) ? parsedEnd : template.GioKetThuc;
        var isOvernight = template.QuaDem || end <= start;

        // Kiểm tra trùng giờ ca làm trong cùng ngày cho cùng nhân viên
        var sameDayAssignments = await _db.PhanCaNhanViens
            .AsNoTracking()
            .Where(p => p.IdNguoiDung == request.StaffUserId &&
                        p.NgayLam == request.WorkDate &&
                        p.TrangThai == "HoatDong")
            .ToListAsync(ct);

        foreach (var existing in sameDayAssignments)
        {
            if (existing.MaKhungCa == code)
            {
                return ServiceResult<ShiftAssignmentDto>.Failure(
                    $"Nhân viên đã được phân công vào {template.TenCa} ngày {request.WorkDate:dd/MM/yyyy}.",
                    "DUPLICATE_ASSIGNMENT",
                    409);
            }

            if (TimesOverlap(start, end, isOvernight, existing.GioVao, existing.GioRa, existing.GioRa <= existing.GioVao))
            {
                return ServiceResult<ShiftAssignmentDto>.Failure(
                    $"Trùng giờ làm việc trong ngày {request.WorkDate:dd/MM/yyyy} với ca {existing.MaKhungCa} ({existing.GioVao:HH\\:mm} - {existing.GioRa:HH\\:mm}).",
                    "STAFF_TIME_CONFLICT",
                    409);
            }
        }

        var position = NormalizePosition(request.Position);
        var entity = new PhanCaNhanVien
        {
            NgayLam = request.WorkDate,
            MaKhungCa = code,
            IdNguoiDung = request.StaffUserId,
            ViTri = position,
            GioVao = start,
            GioRa = end,
            TrangThaiTuan = "Nhap",
            TrangThai = "HoatDong",
            TaoLuc = DateTimeOffset.UtcNow,
            CapNhatLuc = DateTimeOffset.UtcNow
        };

        _db.PhanCaNhanViens.Add(entity);
        await _db.SaveChangesAsync(ct);

        var staffCode = (user.UserName ?? "NV").ToUpperInvariant();
        var staffName = string.IsNullOrWhiteSpace(user.HoSo?.HoTen) ? staffCode : user.HoSo.HoTen;

        return ServiceResult<ShiftAssignmentDto>.Success(
            new ShiftAssignmentDto(
                entity.Id,
                entity.NgayLam,
                entity.MaKhungCa,
                entity.IdNguoiDung,
                staffCode,
                staffName,
                entity.ViTri,
                FormatPositionLabel(entity.ViTri),
                entity.GioVao.ToString("HH:mm"),
                entity.GioRa.ToString("HH:mm"),
                ComputeHours(entity.GioVao, entity.GioRa, isOvernight),
                entity.TrangThaiTuan,
                entity.TrangThai),
            $"Đã phân công '{staffName}' vào {template.TenCa}.",
            201);
    }

    public async Task<ServiceResult<bool>> CancelAssignmentAsync(
        long assignmentId,
        CancelShiftAssignmentRequestDto? request = null,
        CancellationToken ct = default)
    {
        var entity = await _db.PhanCaNhanViens.FirstOrDefaultAsync(p => p.Id == assignmentId, ct);
        if (entity is null)
        {
            return ServiceResult<bool>.Failure(
                "Không tìm thấy phân công ca cần hủy.",
                "ASSIGNMENT_NOT_FOUND",
                404);
        }

        var reason = request?.Reason?.Trim();
        if (entity.TrangThaiTuan == "DaCongBo" && string.IsNullOrWhiteSpace(reason))
        {
            return ServiceResult<bool>.Failure(
                "Ca đã công bố bắt buộc phải nhập lý do hủy để lưu vết kiểm toán.",
                "REASON_REQUIRED",
                400);
        }

        if (entity.TrangThaiTuan == "DaCongBo")
        {
            entity.TrangThai = "DaHuy";
            entity.LyDoHuy = reason;
            entity.CapNhatLuc = DateTimeOffset.UtcNow;
        }
        else
        {
            _db.PhanCaNhanViens.Remove(entity);
        }

        await _db.SaveChangesAsync(ct);
        return ServiceResult<bool>.Success(true, "Đã hủy phân công ca thành công.");
    }

    public async Task<ServiceResult<bool>> PublishWeekAsync(
        DateOnly weekStart,
        CancellationToken ct = default)
    {
        var diffToMonday = ((int)weekStart.DayOfWeek + 6) % 7;
        var monday = weekStart.AddDays(-diffToMonday);
        var sunday = monday.AddDays(6);

        var items = await _db.PhanCaNhanViens
            .Where(p => p.NgayLam >= monday && p.NgayLam <= sunday && p.TrangThai == "HoatDong")
            .ToListAsync(ct);

        if (items.Count == 0)
        {
            return ServiceResult<bool>.Failure(
                "Chưa có phân công nhân viên nào trong tuần để công bố.",
                "EMPTY_WEEK",
                400);
        }

        foreach (var item in items)
        {
            item.TrangThaiTuan = "DaCongBo";
            item.CapNhatLuc = DateTimeOffset.UtcNow;
        }

        await _db.SaveChangesAsync(ct);
        return ServiceResult<bool>.Success(
            true,
            $"Đã công bố lịch phân ca tuần ({monday:dd/MM} – {sunday:dd/MM}) cho {items.Count} lượt trực.");
    }

    public async Task<ServiceResult<int>> CopyPreviousWeekAsync(
        DateOnly targetWeekStart,
        CancellationToken ct = default)
    {
        var diffToMonday = ((int)targetWeekStart.DayOfWeek + 6) % 7;
        var targetMonday = targetWeekStart.AddDays(-diffToMonday);
        var prevMonday = targetMonday.AddDays(-7);
        var prevSunday = prevMonday.AddDays(6);

        var prevItems = await _db.PhanCaNhanViens
            .AsNoTracking()
            .Where(p => p.NgayLam >= prevMonday && p.NgayLam <= prevSunday && p.TrangThai == "HoatDong")
            .ToListAsync(ct);

        if (prevItems.Count == 0)
        {
            return ServiceResult<int>.Failure(
                "Tuần trước chưa có lịch phân ca để sao chép.",
                "NO_PREVIOUS_SCHEDULE",
                404);
        }

        var targetSunday = targetMonday.AddDays(6);
        var existingTarget = await _db.PhanCaNhanViens
            .AsNoTracking()
            .Where(p => p.NgayLam >= targetMonday && p.NgayLam <= targetSunday && p.TrangThai == "HoatDong")
            .Select(p => new { p.NgayLam, p.MaKhungCa, p.IdNguoiDung })
            .ToListAsync(ct);

        var existingKeys = new HashSet<string>(
            existingTarget.Select(x => $"{x.NgayLam:yyyyMMdd}|{x.MaKhungCa}|{x.IdNguoiDung}"));

        var copied = 0;
        foreach (var prev in prevItems)
        {
            var nextDate = prev.NgayLam.AddDays(7);
            var key = $"{nextDate:yyyyMMdd}|{prev.MaKhungCa}|{prev.IdNguoiDung}";
            if (existingKeys.Contains(key)) continue;

            _db.PhanCaNhanViens.Add(new PhanCaNhanVien
            {
                NgayLam = nextDate,
                MaKhungCa = prev.MaKhungCa,
                IdNguoiDung = prev.IdNguoiDung,
                ViTri = prev.ViTri,
                GioVao = prev.GioVao,
                GioRa = prev.GioRa,
                TrangThaiTuan = "Nhap",
                TrangThai = "HoatDong",
                TaoLuc = DateTimeOffset.UtcNow,
                CapNhatLuc = DateTimeOffset.UtcNow
            });
            copied++;
        }

        await _db.SaveChangesAsync(ct);
        return ServiceResult<int>.Success(
            copied,
            copied > 0
                ? $"Đã sao chép {copied} lượt phân công từ tuần trước (trạng thái Bản nháp)."
                : "Toàn bộ lịch tuần trước đã tồn tại trong tuần hiện tại.");
    }

    private async Task<KhungCaLam?> FindOverlappingActiveTemplateAsync(
        string? excludeCode,
        TimeOnly start,
        TimeOnly end,
        bool isOvernight,
        CancellationToken ct)
    {
        var activeTemplates = await _db.KhungCaLams
            .AsNoTracking()
            .Where(k => k.DangApDung && (excludeCode == null || k.Ma != excludeCode))
            .ToListAsync(ct);

        foreach (var other in activeTemplates)
        {
            if (TimesOverlap(start, end, isOvernight, other.GioBatDau, other.GioKetThuc, other.QuaDem))
            {
                return other;
            }
        }

        return null;
    }

    private static bool TimesOverlap(
        TimeOnly s1, TimeOnly e1, bool ov1,
        TimeOnly s2, TimeOnly e2, bool ov2)
    {
        var start1 = s1.Hour * 60 + s1.Minute;
        var end1 = e1.Hour * 60 + e1.Minute + (ov1 ? 1440 : 0);
        var start2 = s2.Hour * 60 + s2.Minute;
        var end2 = e2.Hour * 60 + e2.Minute + (ov2 ? 1440 : 0);

        return start1 < end2 && start2 < end1;
    }

    private static double ComputeHours(TimeOnly start, TimeOnly end, bool isOvernight)
    {
        var s = start.Hour * 60 + start.Minute;
        var e = end.Hour * 60 + end.Minute + (isOvernight ? 1440 : 0);
        return Math.Round(Math.Max(0, e - s) / 60.0, 1);
    }

    private static bool TryParseTime(string? raw, out TimeOnly time)
    {
        if (!string.IsNullOrWhiteSpace(raw) &&
            TimeOnly.TryParseExact(raw.Trim(), ["HH:mm", "H:mm", "HH:mm:ss"], CultureInfo.InvariantCulture, DateTimeStyles.None, out time))
        {
            return true;
        }
        time = default;
        return false;
    }

    private static string NormalizePosition(string? raw) => (raw ?? string.Empty).Trim().ToLowerInvariant() switch
    {
        "thungan" or "cashier" or "thu-ngan" => "ThuNgan",
        "phucvu" or "service" or "floor" or "phuc-vu" => "PhucVu",
        "truongca" or "shift_leader" or "truong-ca" => "TruongCa",
        _ => "PhaChe"
    };

    private static string FormatPositionLabel(string code) => code switch
    {
        "ThuNgan" => "Thu ngân",
        "PhucVu" => "Phục vụ",
        "TruongCa" => "Trưởng ca",
        _ => "Pha chế"
    };

    private static ShiftTemplateDto ToTemplateDto(KhungCaLam k, bool hasUsageHistory) =>
        new(
            k.Ma,
            k.TenCa,
            k.GioBatDau.ToString("HH:mm"),
            k.GioKetThuc.ToString("HH:mm"),
            k.QuaDem,
            k.NghiGiuaCaPhut,
            k.DinhBienPhaChe,
            k.DinhBienThuNgan,
            k.DinhBienPhucVu,
            k.DangApDung,
            k.GhiChuBanGiao,
            k.ThuTu,
            ComputeHours(k.GioBatDau, k.GioKetThuc, k.QuaDem),
            hasUsageHistory,
            k.CapNhatLuc);
}
