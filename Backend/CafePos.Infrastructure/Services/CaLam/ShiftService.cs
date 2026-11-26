using System.Data;
using CafePos.Application.Constants;
using CafePos.Application.DTOs.CaLam;
using CafePos.Application.DTOs.DungChung;
using CafePos.Application.Entities;
using CafePos.Application.Interfaces.CaLam;
using CafePos.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace CafePos.Infrastructure.Services.CaLam;

public class ShiftService : IShiftService
{
    private readonly CafePosDbContext _db;

    public ShiftService(CafePosDbContext db)
    {
        _db = db;
    }

    public async Task<ShiftDto?> GetActiveShiftAsync(
        Guid userId,
        CancellationToken ct = default)
    {
        var activeShift = await _db.CaLamViecs
            .AsNoTracking()
            .Where(s => s.IdNguoiDung == userId && s.TrangThai == ShiftStatuses.DangMo)
            .OrderByDescending(s => s.BatDauLuc)
            .FirstOrDefaultAsync(ct);

        return activeShift is null ? null : MapToDto(activeShift);
    }

    public async Task<ServiceResult<ShiftDto>> StartShiftAsync(
        Guid userId,
        StartShiftRequestDto request,
        CancellationToken ct = default)
    {
        // Kiểm tra nhanh nếu nhân viên đã có ca đang mở thì trả về luôn (Idempotent, chống tạo trùng khi bấm 2 lần)
        var existingOpenShift = await GetActiveShiftAsync(userId, ct);
        if (existingOpenShift is not null)
        {
            return ServiceResult<ShiftDto>.Success(
                existingOpenShift,
                "Bạn đang có một ca làm việc đang mở. Hệ thống tiếp tục ca hiện tại.");
        }

        await using var tx = await _db.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted, ct);
        try
        {
            var currentOpen = await _db.CaLamViecs
                .FirstOrDefaultAsync(
                    s => s.IdNguoiDung == userId && s.TrangThai == ShiftStatuses.DangMo,
                    ct);

            if (currentOpen is not null)
            {
                await tx.CommitAsync(ct);
                return ServiceResult<ShiftDto>.Success(
                    MapToDto(currentOpen),
                    "Ca làm việc đang mở đã được khôi phục.");
            }

            var newShift = new CaLamViec
            {
                Id = Guid.NewGuid(),
                IdNguoiDung = userId,
                TrangThai = ShiftStatuses.DangMo,
                BatDauLuc = DateTimeOffset.UtcNow,
                GhiChuMoCa = string.IsNullOrWhiteSpace(request.Note)
                    ? "Bắt đầu ca tại quầy POS"
                    : request.Note.Trim()
            };

            _db.CaLamViecs.Add(newShift);
            await _db.SaveChangesAsync(ct);
            await tx.CommitAsync(ct);

            return ServiceResult<ShiftDto>.Success(
                MapToDto(newShift),
                "Bắt đầu ca làm việc thành công.",
                201);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            // Nếu 2 request đồng thời chạm Unique Filtered Index UqCaLamViecDangMoMoiNguoi
            await tx.RollbackAsync(ct);
            _db.ChangeTracker.Clear();

            var active = await GetActiveShiftAsync(userId, ct);
            if (active is not null)
            {
                return ServiceResult<ShiftDto>.Success(
                    active,
                    "Ca làm việc đã được mở trước đó.");
            }

            return ServiceResult<ShiftDto>.Failure(
                "Không thể tạo trùng ca làm việc đang mở.",
                "SHIFT_ALREADY_OPEN",
                409);
        }
    }

    public async Task<ServiceResult<ShiftDto>> EndShiftAsync(
        Guid userId,
        EndShiftRequestDto request,
        CancellationToken ct = default)
    {
        await using var tx = await _db.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted, ct);

        var openShift = await _db.CaLamViecs
            .FirstOrDefaultAsync(
                s => s.IdNguoiDung == userId && s.TrangThai == ShiftStatuses.DangMo,
                ct);

        if (openShift is null)
        {
            return ServiceResult<ShiftDto>.Failure(
                "Hiện không có ca làm việc nào đang mở để kết thúc.",
                "NO_OPEN_SHIFT",
                404);
        }

        openShift.TrangThai = ShiftStatuses.DaDong;
        openShift.KetThucLuc = DateTimeOffset.UtcNow;
        openShift.GhiChuKetCa = string.IsNullOrWhiteSpace(request.Note)
            ? "Kết thúc ca làm việc tại quầy POS"
            : request.Note.Trim();

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        return ServiceResult<ShiftDto>.Success(
            MapToDto(openShift),
            "Kết thúc ca làm việc thành công.");
    }

    private static ShiftDto MapToDto(CaLamViec entity) =>
        new(
            entity.Id,
            entity.IdNguoiDung,
            entity.TrangThai,
            entity.BatDauLuc,
            entity.KetThucLuc,
            entity.GhiChuMoCa,
            entity.GhiChuKetCa);
}
