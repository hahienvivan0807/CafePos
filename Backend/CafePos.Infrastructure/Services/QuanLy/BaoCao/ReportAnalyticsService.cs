using CafePos.Application.Constants;
using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.QuanLy.BaoCao;
using CafePos.Application.Interfaces.QuanLy.BaoCao;
using CafePos.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace CafePos.Infrastructure.Services.QuanLy.BaoCao;

public class ReportAnalyticsService : IReportAnalyticsService
{
    private static readonly TimeSpan VietnamOffset = TimeSpan.FromHours(7);
    private const int MinimumHistoricalDaysForForecast = 7;

    private readonly CafePosDbContext _db;

    public ReportAnalyticsService(CafePosDbContext db)
    {
        _db = db;
    }

    public async Task<ServiceResult<RevenueAnalyticsResponseDto>> GetRevenueAnalyticsAsync(
        DateOnly? fromDate,
        DateOnly? toDate,
        CancellationToken ct = default)
    {
        var todayLocal = DateOnly.FromDateTime(DateTimeOffset.UtcNow.ToOffset(VietnamOffset).DateTime);
        var effectiveTo = toDate ?? todayLocal;
        var effectiveFrom = fromDate ?? effectiveTo.AddDays(-6);

        if (effectiveFrom > effectiveTo)
        {
            return ServiceResult<RevenueAnalyticsResponseDto>.Failure(
                "Ngày bắt đầu không được lớn hơn ngày kết thúc.",
                "INVALID_DATE_RANGE",
                400);
        }

        var rangeStartUtc = new DateTimeOffset(effectiveFrom.ToDateTime(TimeOnly.MinValue), VietnamOffset).ToUniversalTime();
        var rangeEndExclusiveUtc = new DateTimeOffset(effectiveTo.AddDays(1).ToDateTime(TimeOnly.MinValue), VietnamOffset).ToUniversalTime();

        var sessions = await _db.LuotBans
            .AsNoTracking()
            .Where(l => l.MoLuc >= rangeStartUtc && l.MoLuc < rangeEndExclusiveUtc)
            .ToListAsync(ct);

        var orders = await _db.DonHangs
            .AsNoTracking()
            .Where(d => d.TaoLuc >= rangeStartUtc && d.TaoLuc < rangeEndExclusiveUtc)
            .Include(d => d.DanhSachDongMon)
                .ThenInclude(dm => dm.DanhSachYeuCauHuy)
            .Include(d => d.DanhSachDongMon)
                .ThenInclude(dm => dm.Mon)
                    .ThenInclude(m => m!.DanhMuc)
            .ToListAsync(ct);

        var activeOrders = orders
            .Where(o => !string.Equals(o.TrangThai, OrderStatuses.Cancelled, StringComparison.OrdinalIgnoreCase))
            .ToList();

        long totalOrderValueVnd = 0;
        long actualCollectedVnd = 0;
        int paidOrders = 0;
        int awaitingPaymentOrders = 0;
        int openOrders = 0;

        var shifts = await _db.KhungCaLams
            .AsNoTracking()
            .OrderBy(k => k.ThuTu)
            .ToListAsync(ct);

        var slotGov = shifts.ToDictionary(s => s.Ma, _ => 0L, StringComparer.OrdinalIgnoreCase);
        var slotCollected = shifts.ToDictionary(s => s.Ma, _ => 0L, StringComparer.OrdinalIgnoreCase);
        var slotCount = shifts.ToDictionary(s => s.Ma, _ => 0, StringComparer.OrdinalIgnoreCase);

        var itemStats = new Dictionary<long, (string Code, string Name, string Category, int Qty, long Rev)>();

        foreach (var order in activeOrders)
        {
            var validLines = order.DanhSachDongMon
                .Where(l => !l.DanhSachYeuCauHuy.Any(y =>
                    string.Equals(y.TrangThai, "approved", StringComparison.OrdinalIgnoreCase)))
                .ToList();

            var orderTotal = validLines.Sum(l => l.DonGiaLucBanVnd * l.SoLuong);
            var isPaid = string.Equals(order.TrangThai, OrderStatuses.Paid, StringComparison.OrdinalIgnoreCase);
            var isAwaiting = string.Equals(order.TrangThai, OrderStatuses.AwaitingPayment, StringComparison.OrdinalIgnoreCase);

            totalOrderValueVnd += orderTotal;
            if (isPaid)
            {
                actualCollectedVnd += orderTotal;
                paidOrders++;
            }
            else if (isAwaiting)
            {
                awaitingPaymentOrders++;
            }
            else
            {
                openOrders++;
            }

            var localTime = order.TaoLuc.ToOffset(VietnamOffset);
            var slotKey = !string.IsNullOrWhiteSpace(order.MaKhungCa) && slotGov.ContainsKey(order.MaKhungCa)
                ? order.MaKhungCa
                : ResolveShiftCode(localTime.Hour);
            if (slotGov.ContainsKey(slotKey))
            {
                slotGov[slotKey] += orderTotal;
                if (isPaid)
                {
                    slotCollected[slotKey] += orderTotal;
                }
                slotCount[slotKey]++;
            }

            foreach (var line in validLines)
            {
                var lineRev = line.DonGiaLucBanVnd * line.SoLuong;
                var code = line.Mon?.Ma ?? $"M{line.IdMon}";
                var name = string.IsNullOrWhiteSpace(line.TenMonLucBan) ? (line.Mon?.Ten ?? "Món POS") : line.TenMonLucBan;
                var category = line.Mon?.DanhMuc?.Ten ?? "Khác";

                if (itemStats.TryGetValue(line.IdMon, out var cur))
                {
                    itemStats[line.IdMon] = (cur.Code, cur.Name, cur.Category, cur.Qty + line.SoLuong, cur.Rev + lineRev);
                }
                else
                {
                    itemStats[line.IdMon] = (code, name, category, line.SoLuong, lineRev);
                }
            }
        }

        var totalSessions = sessions.Count;
        var completedSessions = sessions.Count(s => s.TraBanLuc.HasValue);
        var completionRate = totalSessions > 0
            ? Math.Round((double)completedSessions * 100.0 / totalSessions, 1)
            : 0.0;

        var timeSlots = shifts.Select(s => new TimeSlotRevenueDto(
            s.Ma,
            $"{s.TenCa} ({s.GioBatDau:HH\\:mm} - {s.GioKetThuc:HH\\:mm})",
            slotGov[s.Ma],
            slotCollected[s.Ma],
            slotCount[s.Ma])).ToList();

        // Hiện tại schema pos."DonHang" thanh toán chuẩn qua VietQR (100% đơn paid xác nhận qua VietQR)
        var paymentBreakdown = new List<PaymentBreakdownItemDto>
        {
            new("vietqr", "Chuyển khoản VietQR", actualCollectedVnd, actualCollectedVnd > 0 ? 100.0 : 0.0),
            new("cash", "Tiền mặt tại quầy", 0, 0.0)
        };

        var totalItemRevenue = itemStats.Values.Sum(v => v.Rev);
        var topItems = itemStats
            .OrderByDescending(kv => kv.Value.Qty)
            .ThenByDescending(kv => kv.Value.Rev)
            .Select((kv, idx) => new TopMenuItemReportDto(
                idx + 1,
                kv.Key,
                kv.Value.Code,
                kv.Value.Name,
                kv.Value.Category,
                kv.Value.Qty,
                kv.Value.Rev,
                totalItemRevenue > 0 ? Math.Round((double)kv.Value.Rev * 100.0 / totalItemRevenue, 1) : 0.0))
            .ToList();

        var categories = topItems
            .Select(i => i.CategoryName)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(c => c)
            .ToList();

        var bestSeller = topItems.FirstOrDefault();

        var response = new RevenueAnalyticsResponseDto(
            effectiveFrom,
            effectiveTo,
            totalOrderValueVnd,
            actualCollectedVnd,
            totalSessions,
            completedSessions,
            completionRate,
            activeOrders.Count,
            paidOrders,
            awaitingPaymentOrders,
            openOrders,
            bestSeller?.ItemName,
            bestSeller?.QuantitySold ?? 0,
            timeSlots,
            paymentBreakdown,
            topItems,
            categories,
            DateTimeOffset.UtcNow);

        return ServiceResult<RevenueAnalyticsResponseDto>.Success(
            response,
            "Tổng hợp báo cáo vận hành thành công.");
    }

    public async Task<ServiceResult<AiForecastResponseDto>> GetAiForecastAsync(
        DateOnly? fromDate,
        DateOnly? toDate,
        CancellationToken ct = default)
    {
        var todayLocal = DateOnly.FromDateTime(DateTimeOffset.UtcNow.ToOffset(VietnamOffset).DateTime);
        var effectiveTo = toDate ?? todayLocal;
        var effectiveFrom = fromDate ?? effectiveTo.AddDays(-13);

        if (effectiveFrom > effectiveTo)
        {
            return ServiceResult<AiForecastResponseDto>.Failure(
                "Ngày bắt đầu không được lớn hơn ngày kết thúc.",
                "INVALID_DATE_RANGE",
                400);
        }

        var rangeStartUtc = new DateTimeOffset(effectiveFrom.ToDateTime(TimeOnly.MinValue), VietnamOffset).ToUniversalTime();
        var rangeEndExclusiveUtc = new DateTimeOffset(effectiveTo.AddDays(1).ToDateTime(TimeOnly.MinValue), VietnamOffset).ToUniversalTime();

        var paidOrders = await _db.DonHangs
            .AsNoTracking()
            .Where(d => d.TrangThai == OrderStatuses.Paid &&
                        d.TaoLuc >= rangeStartUtc &&
                        d.TaoLuc < rangeEndExclusiveUtc)
            .Include(d => d.DanhSachDongMon)
                .ThenInclude(dm => dm.DanhSachYeuCauHuy)
            .ToListAsync(ct);

        var dailyMap = new Dictionary<DateOnly, (long Revenue, int Orders)>();
        var hourLoad = new Dictionary<string, int>
        {
            ["07:00 - 11:00"] = 0,
            ["11:00 - 14:00"] = 0,
            ["14:00 - 18:00"] = 0,
            ["18:00 - 22:30"] = 0
        };

        foreach (var order in paidOrders)
        {
            var localDt = order.TaoLuc.ToOffset(VietnamOffset);
            var day = DateOnly.FromDateTime(localDt.DateTime);
            var orderTotal = order.DanhSachDongMon
                .Where(l => !l.DanhSachYeuCauHuy.Any(y =>
                    string.Equals(y.TrangThai, "approved", StringComparison.OrdinalIgnoreCase)))
                .Sum(l => l.DonGiaLucBanVnd * l.SoLuong);

            if (dailyMap.TryGetValue(day, out var cur))
            {
                dailyMap[day] = (cur.Revenue + orderTotal, cur.Orders + 1);
            }
            else
            {
                dailyMap[day] = (orderTotal, 1);
            }

            var window = localDt.Hour switch
            {
                < 11 => "07:00 - 11:00",
                < 14 => "11:00 - 14:00",
                < 18 => "14:00 - 18:00",
                _ => "18:00 - 22:30"
            };
            hourLoad[window]++;
        }

        var historicalDaysAvailable = dailyMap.Count(kv => kv.Value.Revenue > 0);
        var hasEnoughData = historicalDaysAvailable >= MinimumHistoricalDaysForForecast;
        var coveragePercent = Math.Min(
            100.0,
            Math.Round((double)historicalDaysAvailable * 100.0 / MinimumHistoricalDaysForForecast, 1));

        var series = new List<ForecastDataPointDto>();
        for (var d = effectiveFrom; d <= effectiveTo; d = d.AddDays(1))
        {
            var hasVal = dailyMap.TryGetValue(d, out var stats);
            series.Add(new ForecastDataPointDto(
                d,
                d.ToString("dd/MM"),
                hasVal ? stats.Revenue : 0,
                null,
                hasVal ? stats.Orders : 0,
                null));
        }

        long projectedNext7Days = 0;
        double trendPercent = 0;
        var peakWindow = hourLoad.OrderByDescending(kv => kv.Value).First().Key;
        var suggestions = new List<IngredientSuggestionDto>();

        if (hasEnoughData)
        {
            var nonZeroDays = dailyMap
                .OrderBy(kv => kv.Key)
                .Select(kv => kv.Value)
                .ToList();

            var recentWindow = nonZeroDays.TakeLast(Math.Min(7, nonZeroDays.Count)).ToList();
            var earlierWindow = nonZeroDays.Take(Math.Max(1, nonZeroDays.Count - recentWindow.Count)).ToList();

            var avgRecentRev = recentWindow.Average(x => (double)x.Revenue);
            var avgRecentOrders = recentWindow.Average(x => (double)x.Orders);
            var avgEarlierRev = earlierWindow.Average(x => (double)x.Revenue);

            if (avgEarlierRev > 0)
            {
                trendPercent = Math.Round((avgRecentRev - avgEarlierRev) * 100.0 / avgEarlierRev, 1);
            }

            // Hệ số tăng trưởng nhẹ theo xu hướng (giới hạn trong [-15%, +20%] để dự báo ổn định)
            var growthFactor = 1.0 + Math.Clamp(trendPercent / 100.0, -0.15, 0.20) * 0.4;

            // Điểm nối giữa đường thực tế và đường dự báo
            if (series.Count > 0)
            {
                var lastActual = series[^1];
                series[^1] = lastActual with
                {
                    ForecastRevenueVnd = lastActual.ActualRevenueVnd,
                    ForecastOrderCount = lastActual.ActualOrderCount
                };
            }

            for (var i = 1; i <= 7; i++)
            {
                var nextDate = effectiveTo.AddDays(i);
                var weekendBoost = nextDate.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday ? 1.15 : 1.0;
                var forecastRev = (long)Math.Round(avgRecentRev * growthFactor * weekendBoost / 1000.0) * 1000;
                var forecastOrders = Math.Max(1, (int)Math.Round(avgRecentOrders * growthFactor * weekendBoost));

                projectedNext7Days += forecastRev;
                series.Add(new ForecastDataPointDto(
                    nextDate,
                    nextDate.ToString("dd/MM"),
                    null,
                    forecastRev,
                    null,
                    forecastOrders));
            }

            // Gợi ý chuẩn bị vận hành dựa trên tổng sản lượng đơn dự báo 7 ngày tới
            var projectedOrders7Days = series.Where(s => s.ActualRevenueVnd is null).Sum(s => s.ForecastOrderCount ?? 0);
            var coffeeKg = Math.Max(1.0, Math.Round(projectedOrders7Days * 0.045, 1));
            var milkLiters = Math.Max(2.0, Math.Round(projectedOrders7Days * 0.18, 1));

            suggestions.Add(new IngredientSuggestionDto(
                "Cà phê hạt rang mộc",
                "Nguyên vật liệu pha chế chính",
                "Chưa tích hợp kho",
                $"~{coffeeKg:0.0} kg / 7 ngày",
                "Ưu tiên cao"));
            suggestions.Add(new IngredientSuggestionDto(
                "Sữa tươi thanh trùng",
                "Bảo quản lạnh 4°C",
                "Chưa tích hợp kho",
                $"~{milkLiters:0.0} lít / 7 ngày",
                "Ổn định"));
            suggestions.Add(new IngredientSuggestionDto(
                $"Bố trí nhân sự khung {peakWindow}",
                "Khuyến nghị tải trọng giờ cao điểm",
                $"{historicalDaysAvailable} ngày dữ liệu",
                projectedOrders7Days >= 35 ? "+1 nhân sự hỗ trợ" : "Giữ đội hình chuẩn",
                projectedOrders7Days >= 35 ? "Tải cao" : "Bình thường"));
        }

        var statusTitle = hasEnoughData
            ? "Mô hình Daylight AI sẵn sàng"
            : "Chưa đủ dữ liệu dự báo";
        var statusDescription = hasEnoughData
            ? $"Đã phân tích {historicalDaysAvailable} ngày giao dịch thực tế trong khoảng {effectiveFrom:dd/MM} – {effectiveTo:dd/MM} để dự báo xu hướng 7 ngày tiếp theo."
            : $"Hệ thống Daylight AI cần tối thiểu {MinimumHistoricalDaysForForecast} ngày có giao dịch thực tế (hiện có {historicalDaysAvailable}/{MinimumHistoricalDaysForForecast} ngày) để tổng hợp mô hình dự báo.";

        var dto = new AiForecastResponseDto(
            effectiveFrom,
            effectiveTo,
            hasEnoughData,
            historicalDaysAvailable,
            MinimumHistoricalDaysForForecast,
            coveragePercent,
            statusTitle,
            statusDescription,
            projectedNext7Days,
            trendPercent,
            peakWindow,
            series,
            suggestions,
            DateTimeOffset.UtcNow);

        return ServiceResult<AiForecastResponseDto>.Success(dto, "Tổng hợp dự báo Daylight AI thành công.");
    }

    public async Task<ServiceResult<ShiftOrdersResponseDto>> GetShiftOrdersAsync(
        string shiftCode,
        DateOnly? fromDate,
        DateOnly? toDate,
        CancellationToken ct = default)
    {
        var normalizedCode = (shiftCode ?? string.Empty).Trim().ToUpperInvariant() switch
        {
            "MORNING" or "CA_SANG" => "CA_SANG",
            "NOON" or "CA_TRUA" => "CA_TRUA",
            "AFTERNOON" or "CA_CHIEU" => "CA_CHIEU",
            "EVENING" or "CA_TOI" => "CA_TOI",
            _ => string.Empty
        };

        if (string.IsNullOrEmpty(normalizedCode))
        {
            return ServiceResult<ShiftOrdersResponseDto>.Failure(
                "Mã khung ca không hợp lệ.",
                "INVALID_SHIFT_CODE",
                400);
        }

        var todayLocal = DateOnly.FromDateTime(DateTimeOffset.UtcNow.ToOffset(VietnamOffset).DateTime);
        var effectiveTo = toDate ?? todayLocal;
        var effectiveFrom = fromDate ?? effectiveTo.AddDays(-6);

        var shift = await _db.KhungCaLams
            .AsNoTracking()
            .FirstOrDefaultAsync(k => k.Ma == normalizedCode, ct);

        var shiftLabel = shift is not null
            ? $"{shift.TenCa} ({shift.GioBatDau:HH\\:mm} - {shift.GioKetThuc:HH\\:mm})"
            : normalizedCode;

        var rangeStartUtc = new DateTimeOffset(effectiveFrom.ToDateTime(TimeOnly.MinValue), VietnamOffset).ToUniversalTime();
        var rangeEndExclusiveUtc = new DateTimeOffset(effectiveTo.AddDays(1).ToDateTime(TimeOnly.MinValue), VietnamOffset).ToUniversalTime();

        var orders = await _db.DonHangs
            .AsNoTracking()
            .Where(d => d.TaoLuc >= rangeStartUtc &&
                        d.TaoLuc < rangeEndExclusiveUtc &&
                        d.TrangThai != OrderStatuses.Cancelled)
            .Include(d => d.LuotBan)
                .ThenInclude(l => l!.Ban)
            .Include(d => d.DanhSachDongMon)
                .ThenInclude(dm => dm.DanhSachYeuCauHuy)
            .OrderByDescending(d => d.TaoLuc)
            .ToListAsync(ct);

        var matchedOrders = orders.Where(o =>
        {
            var effectiveCode = !string.IsNullOrWhiteSpace(o.MaKhungCa)
                ? o.MaKhungCa
                : ResolveShiftCode(o.TaoLuc.ToOffset(VietnamOffset).Hour);
            return string.Equals(effectiveCode, normalizedCode, StringComparison.OrdinalIgnoreCase);
        }).ToList();

        var creatorIds = matchedOrders.Select(o => o.IdNguoiTao).Distinct().ToList();
        var staffNames = await _db.Users
            .AsNoTracking()
            .Include(u => u.HoSo)
            .Where(u => creatorIds.Contains(u.Id))
            .ToDictionaryAsync(
                u => u.Id,
                u => string.IsNullOrWhiteSpace(u.HoSo?.HoTen) ? (u.UserName ?? "Nhân viên") : u.HoSo.HoTen,
                ct);

        long totalGov = 0;
        long totalCollected = 0;
        var summaries = new List<ShiftOrderSummaryDto>(matchedOrders.Count);

        foreach (var order in matchedOrders)
        {
            var validLines = order.DanhSachDongMon
                .Where(l => !l.DanhSachYeuCauHuy.Any(y =>
                    string.Equals(y.TrangThai, "approved", StringComparison.OrdinalIgnoreCase)))
                .ToList();

            var orderTotal = validLines.Sum(l => l.DonGiaLucBanVnd * l.SoLuong);
            var itemsCount = validLines.Sum(l => l.SoLuong);
            totalGov += orderTotal;
            if (string.Equals(order.TrangThai, OrderStatuses.Paid, StringComparison.OrdinalIgnoreCase))
            {
                totalCollected += orderTotal;
            }

            summaries.Add(new ShiftOrderSummaryDto(
                order.Id,
                order.Ma,
                order.LuotBan?.Ban?.Ma ?? "BÀN",
                order.LuotBan?.Ban?.Ten ?? "Bàn POS",
                staffNames.TryGetValue(order.IdNguoiTao, out var name) ? name : "Nhân viên",
                order.TrangThai,
                order.TaoLuc,
                order.ThanhToanLuc,
                itemsCount,
                orderTotal));
        }

        return ServiceResult<ShiftOrdersResponseDto>.Success(
            new ShiftOrdersResponseDto(
                normalizedCode,
                shiftLabel,
                effectiveFrom,
                effectiveTo,
                totalGov,
                totalCollected,
                summaries),
            "Tải danh sách hóa đơn theo ca thành công.");
    }

    private static string ResolveShiftCode(int localHour) => localHour switch
    {
        < 11 => "CA_SANG",
        < 14 => "CA_TRUA",
        < 18 => "CA_CHIEU",
        _ => "CA_TOI"
    };
}
