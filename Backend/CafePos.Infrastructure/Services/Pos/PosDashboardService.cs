using System.Data;
using CafePos.Application.Constants;
using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.Pos;
using CafePos.Application.Entities;
using CafePos.Application.Interfaces.Pos;
using CafePos.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace CafePos.Infrastructure.Services.Pos;

public class PosDashboardService : IPosDashboardService
{
    private readonly CafePosDbContext _db;

    public PosDashboardService(CafePosDbContext db)
    {
        _db = db;
    }

    public async Task<ServiceResult<DashboardOverviewDto>> GetDashboardOverviewAsync(
        CancellationToken ct = default)
    {
        // 1. Đọc danh sách bàn thật từ pos."Ban"
        var tables = await _db.Bans
            .AsNoTracking()
            .Where(b => b.DangHoatDong)
            .OrderBy(b => b.Id)
            .ToListAsync(ct);

        // 2. Đọc toàn bộ các lượt bàn đang mở (TraBanLuc IS NULL) kèm Đơn hàng, Dòng món và Yêu cầu hủy món từ DB
        var activeSessions = await _db.LuotBans
            .AsNoTracking()
            .Where(l => l.TraBanLuc == null)
            .Include(l => l.DanhSachDonHang)
                .ThenInclude(d => d.DanhSachDongMon)
                    .ThenInclude(dm => dm.DanhSachYeuCauHuy)
            .ToListAsync(ct);

        var activeSessionByTableId = activeSessions
            .GroupBy(l => l.IdBan)
            .ToDictionary(g => g.Key, g => g.OrderByDescending(x => x.MoLuc).First());

        // 3. Đọc danh mục món và món từ pos."DanhMucMon" & pos."Mon"
        var categories = await _db.DanhMucMons
            .AsNoTracking()
            .OrderBy(c => c.Id)
            .ToListAsync(ct);

        var menuItems = await _db.Mons
            .AsNoTracking()
            .Include(m => m.DanhMuc)
            .Where(m => m.DangHoatDong)
            .OrderBy(m => m.IdDanhMuc)
            .ThenBy(m => m.Id)
            .ToListAsync(ct);

        var now = DateTimeOffset.UtcNow;
        var tableCards = new List<TableCardDto>(tables.Count);

        int emptyCount = 0;
        int occupiedCount = 0;
        int awaitingQrCount = 0;
        int addOnCount = 0;

        foreach (var table in tables)
        {
            activeSessionByTableId.TryGetValue(table.Id, out var activeSession);
            var card = BuildTableCardDto(table, activeSession, now);
            tableCards.Add(card);

            switch (card.VisualStatus)
            {
                case TableVisualStatuses.Empty:
                    emptyCount++;
                    break;
                case TableVisualStatuses.AwaitingQr:
                    awaitingQrCount++;
                    break;
                case TableVisualStatuses.AddOn:
                    addOnCount++;
                    occupiedCount++;
                    break;
                default:
                    occupiedCount++;
                    break;
            }
        }

        // Nhóm khu vực động dựa trên dữ liệu bàn thật trong DB
        var areas = tableCards
            .GroupBy(t => t.AreaName)
            .Select(g => new AreaSummaryDto(g.Key, g.Count()))
            .ToList();

        var categoryDtos = categories
            .Select(c => new MenuCategoryDto(
                c.Id,
                c.Ma,
                c.Ten,
                menuItems.Count(m => m.IdDanhMuc == c.Id)))
            .ToList();

        var menuItemDtos = menuItems
            .Select(m => new MenuItemDto(
                m.Id,
                m.IdDanhMuc,
                m.DanhMuc?.Ma ?? string.Empty,
                m.DanhMuc?.Ten ?? string.Empty,
                m.Ma,
                m.Ten,
                m.GiaVnd,
                m.DangHoatDong))
            .ToList();

        var overview = new DashboardOverviewDto(
            TotalTables: tableCards.Count,
            EmptyTables: emptyCount,
            OccupiedTables: occupiedCount,
            AwaitingQrTables: awaitingQrCount,
            AddOnTables: addOnCount,
            Areas: areas,
            Tables: tableCards,
            Categories: categoryDtos,
            MenuItems: menuItemDtos,
            SyncedAt: now);

        return ServiceResult<DashboardOverviewDto>.Success(overview);
    }

    public async Task<ServiceResult<OrderDetailsViewDto>> GetOrderDetailsAsync(
        long orderId,
        CancellationToken ct = default)
    {
        var order = await _db.DonHangs
            .AsNoTracking()
            .Include(o => o.LuotBan)
                .ThenInclude(l => l!.Ban)
            .Include(o => o.DanhSachDongMon)
                .ThenInclude(l => l.DanhSachYeuCauHuy)
            .FirstOrDefaultAsync(o => o.Id == orderId, ct);

        if (order?.LuotBan is not { Ban: { } table } session)
        {
            return ServiceResult<OrderDetailsViewDto>.Failure(
                "Không tìm thấy đơn hàng.", "ORDER_NOT_FOUND", 404);
        }

        var earlierOrders = await _db.DonHangs.CountAsync(o =>
            o.IdLuotBan == order.IdLuotBan && o.TrangThai != OrderStatuses.Cancelled &&
            (o.TaoLuc < order.TaoLuc || (o.TaoLuc == order.TaoLuc && o.Id < order.Id)), ct);
        var staffName = await _db.Users
            .Where(user => user.Id == order.IdNguoiTao)
            .Select(user => user.HoSo != null && user.HoSo.HoTen != ""
                ? user.HoSo.HoTen
                : user.UserName)
            .FirstOrDefaultAsync(ct);

        var details = BuildOrderDetailDto(order, earlierOrders + 1);
        var isActive = session.TraBanLuc is null
            && order.TrangThai is OrderStatuses.Open or OrderStatuses.AwaitingPayment;
        var paidAmount = order.TrangThai == OrderStatuses.Paid ? details.TotalAmountVnd : 0;
        var remainingAmount = order.TrangThai == OrderStatuses.Cancelled
            ? 0
            : details.TotalAmountVnd - paidAmount;

        return ServiceResult<OrderDetailsViewDto>.Success(new(
            table.Id, table.Ma, table.Ten, staffName, paidAmount, remainingAmount,
            isActive && table.DangHoatDong, isActive && remainingAmount > 0, details));
    }

    public async Task<ServiceResult<TableCardDto>> OpenTableOrAddItemsAsync(
        Guid staffUserId,
        OpenTableOrAddItemsRequestDto request,
        CancellationToken ct = default)
    {
        var table = await _db.Bans
            .FirstOrDefaultAsync(b => b.Id == request.TableId && b.DangHoatDong, ct);

        if (table is null)
        {
            return ServiceResult<TableCardDto>.Failure(
                "Không tìm thấy bàn phục vụ trong cơ sở dữ liệu.",
                "TABLE_NOT_FOUND",
                404);
        }

        await using var tx = await _db.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted, ct);
        await LockTableAsync(table.Id, ct);

        // 1. Tìm lượt bàn đang mở (TraBanLuc IS NULL) hoặc mở lượt bàn mới
        var session = await _db.LuotBans
            .Include(l => l.DanhSachDonHang)
                .ThenInclude(d => d.DanhSachDongMon)
                    .ThenInclude(dm => dm.DanhSachYeuCauHuy)
            .FirstOrDefaultAsync(l => l.IdBan == table.Id && l.TraBanLuc == null, ct);

        var activeOrder = session is null ? null : FindUnpaidOrder(session);
        if (request.OrderId is long orderId && activeOrder?.Id != orderId)
        {
            return OrderChanged();
        }

        if (session is null)
        {
            session = new LuotBan
            {
                IdBan = table.Id,
                IdNguoiMo = staffUserId,
                MoLuc = DateTimeOffset.UtcNow
            };
            _db.LuotBans.Add(session);
            await _db.SaveChangesAsync(ct);
        }

        // 2. Nếu có danh sách món cần ghi vào đơn
        var validItems = request.Items?
            .Where(i => i.Quantity > 0)
            .ToList() ?? new List<OrderItemInputDto>();

        if (validItems.Count > 0)
        {
            var menuIds = validItems.Select(i => i.MenuItemId).Distinct().ToList();
            var dbMenuMap = await _db.Mons
                .Where(m => menuIds.Contains(m.Id) && m.DangHoatDong)
                .ToDictionaryAsync(m => m.Id, ct);

            if (dbMenuMap.Count != menuIds.Count)
            {
                return ServiceResult<TableCardDto>.Failure(
                    "Có món đã ngừng bán. Hãy tải lại thực đơn trước khi ghi món.",
                    "MENU_ITEM_UNAVAILABLE", 409);
            }

            if (activeOrder is null)
            {
                // Tạo đơn mới trong lượt (Đơn #A nếu chưa có đơn nào, hoặc Đơn #B nếu đơn trước đã 'paid')
                var orderSeq = session.DanhSachDonHang.Count + 1;
                var orderSuffix = GetOrderLetter(orderSeq);
                var orderCode = $"DH-{table.Ma}-{session.Id}-{orderSuffix}-{DateTimeOffset.UtcNow.ToUnixTimeSeconds() % 10000}";

                var vnNowHour = DateTimeOffset.UtcNow.ToOffset(TimeSpan.FromHours(7)).Hour;
                var maKhungCa = vnNowHour switch
                {
                    < 11 => "CA_SANG",
                    < 14 => "CA_TRUA",
                    < 18 => "CA_CHIEU",
                    _ => "CA_TOI"
                };

                activeOrder = new DonHang
                {
                    IdLuotBan = session.Id,
                    Ma = orderCode,
                    TrangThai = OrderStatuses.Open,
                    IdNguoiTao = staffUserId,
                    MaKhungCa = maKhungCa,
                    TaoLuc = DateTimeOffset.UtcNow
                };

                _db.DonHangs.Add(activeOrder);
                await _db.SaveChangesAsync(ct);
                session.DanhSachDonHang.Add(activeOrder);
            }
            else if (activeOrder.TrangThai == OrderStatuses.AwaitingPayment)
            {
                // Quy tắc nghiệp vụ mục 6 PROJECT.md: Nếu đang chờ QR mà khách gọi thêm món,
                // ngừng hiển thị QR cũ để tạo lại QR mới theo tổng tiền mới
                activeOrder.TrangThai = OrderStatuses.Open;
            }

            foreach (var itemInput in validItems)
            {
                var menuEntity = dbMenuMap[itemInput.MenuItemId];

                var newLine = new DongMon
                {
                    IdDonHang = activeOrder.Id,
                    IdMon = menuEntity.Id,
                    TenMonLucBan = menuEntity.Ten,
                    DonGiaLucBanVnd = menuEntity.GiaVnd,
                    SoLuong = itemInput.Quantity,
                    GhiChu = string.IsNullOrWhiteSpace(itemInput.Note) ? null : itemInput.Note.Trim(),
                    IdNguoiGhiMon = staffUserId,
                    GhiMonLuc = DateTimeOffset.UtcNow
                };

                _db.DongMons.Add(newLine);
                activeOrder.DanhSachDongMon.Add(newLine);
            }

            await _db.SaveChangesAsync(ct);
        }

        await tx.CommitAsync(ct);

        var updatedCard = await ReloadTableCardAsync(table.Id, ct);
        return ServiceResult<TableCardDto>.Success(
            updatedCard!,
            validItems.Count > 0
                ? $"Đã mở bàn {table.Ma} và ghi món thành công."
                : $"Đã mở lượt sử dụng cho bàn {table.Ma}.");
    }

    public async Task<ServiceResult<TableCardDto>> RequestVietQrAsync(
        Guid staffUserId,
        long tableId,
        CancellationToken ct = default,
        long? orderId = null)
    {
        await using var tx = await _db.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted, ct);
        await LockTableAsync(tableId, ct);

        var session = await _db.LuotBans
            .Include(l => l.Ban)
            .Include(l => l.DanhSachDonHang)
                .ThenInclude(d => d.DanhSachDongMon)
                    .ThenInclude(dm => dm.DanhSachYeuCauHuy)
            .FirstOrDefaultAsync(l => l.IdBan == tableId && l.TraBanLuc == null, ct);

        if (session is null)
        {
            return ServiceResult<TableCardDto>.Failure(
                "Bàn hiện chưa có lượt sử dụng nào đang mở.",
                "NO_ACTIVE_SESSION",
                404);
        }

        var activeOrder = FindUnpaidOrder(session);
        if (orderId.HasValue && activeOrder?.Id != orderId)
        {
            return OrderChanged();
        }

        if (activeOrder is null || CalculateOrderTotal(activeOrder) <= 0)
        {
            return ServiceResult<TableCardDto>.Failure(
                "Chưa có đơn hàng nào có món cần thanh toán để tạo VietQR.",
                "EMPTY_ORDER",
                400);
        }

        activeOrder.TrangThai = OrderStatuses.AwaitingPayment;
        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        var updatedCard = await ReloadTableCardAsync(tableId, ct);
        return ServiceResult<TableCardDto>.Success(
            updatedCard!,
            $"Đã phát hành mã thanh toán VietQR cho đơn {activeOrder.Ma}.");
    }

    public async Task<ServiceResult<TableCardDto>> ConfirmVietQrPaidAsync(
        Guid staffUserId,
        long tableId,
        CancellationToken ct = default,
        long? orderId = null)
    {
        await using var tx = await _db.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted, ct);
        await LockTableAsync(tableId, ct);

        var session = await _db.LuotBans
            .Include(l => l.DanhSachDonHang)
                .ThenInclude(d => d.DanhSachDongMon)
                    .ThenInclude(dm => dm.DanhSachYeuCauHuy)
            .FirstOrDefaultAsync(l => l.IdBan == tableId && l.TraBanLuc == null, ct);

        if (session is null)
        {
            return ServiceResult<TableCardDto>.Failure(
                "Bàn hiện chưa có lượt sử dụng nào đang mở.",
                "NO_ACTIVE_SESSION",
                404);
        }

        var activeOrder = FindUnpaidOrder(session);
        if (orderId.HasValue && (activeOrder?.Id != orderId ||
            activeOrder?.TrangThai != OrderStatuses.AwaitingPayment))
        {
            return OrderChanged();
        }

        if (activeOrder is null)
        {
            return ServiceResult<TableCardDto>.Failure(
                "Không có đơn hàng nào đang chờ thanh toán.",
                "NO_UNPAID_ORDER",
                400);
        }

        activeOrder.TrangThai = OrderStatuses.Paid;
        activeOrder.ThanhToanLuc = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        var updatedCard = await ReloadTableCardAsync(tableId, ct);
        return ServiceResult<TableCardDto>.Success(
            updatedCard!,
            $"Đã xác nhận thanh toán VietQR cho đơn {activeOrder.Ma}. Bàn vẫn đang có khách.");
    }

    public async Task<ServiceResult<TableCardDto>> CloseTableSessionAsync(
        Guid staffUserId,
        long tableId,
        CancellationToken ct = default)
    {
        await using var tx = await _db.Database.BeginTransactionAsync(IsolationLevel.ReadCommitted, ct);
        await LockTableAsync(tableId, ct);

        var session = await _db.LuotBans
            .Include(l => l.Ban)
            .Include(l => l.DanhSachDonHang)
                .ThenInclude(d => d.DanhSachDongMon)
                    .ThenInclude(dm => dm.DanhSachYeuCauHuy)
            .FirstOrDefaultAsync(l => l.IdBan == tableId && l.TraBanLuc == null, ct);

        if (session is null)
        {
            return ServiceResult<TableCardDto>.Failure(
                "Bàn này hiện đang trống.",
                "TABLE_ALREADY_EMPTY",
                400);
        }

        // Quy tắc nghiệp vụ (CafePos.Application): Chỉ cho trả bàn khi mọi đơn có món trong lượt đã được xử lý ('paid' hoặc 'cancelled')
        foreach (var order in session.DanhSachDonHang)
        {
            if (order.TrangThai == OrderStatuses.Open || order.TrangThai == OrderStatuses.AwaitingPayment)
            {
                var orderTotal = CalculateOrderTotal(order);
                if (orderTotal > 0)
                {
                    return ServiceResult<TableCardDto>.Failure(
                        $"Chưa thể trả bàn vì đơn {order.Ma} còn {orderTotal:N0}đ chưa thanh toán.",
                        "UNPAID_ORDER_REMAINING",
                        400);
                }

                // Nếu đơn mở nhưng chưa ghi món nào thì hủy đơn rỗng khi trả bàn
                order.TrangThai = OrderStatuses.Cancelled;
                order.ThanhToanLuc = null;
            }
        }

        session.IdNguoiTraBan = staffUserId;
        session.TraBanLuc = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);

        var updatedCard = await ReloadTableCardAsync(tableId, ct);
        return ServiceResult<TableCardDto>.Success(
            updatedCard!,
            $"Đã trả bàn {session.Ban?.Ma} thành công. Bàn sẵn sàng đón khách mới.");
    }

    private Task<int> LockTableAsync(long tableId, CancellationToken ct) =>
        _db.Database.ExecuteSqlInterpolatedAsync(
            $"SELECT 1 FROM pos.\"Ban\" WHERE \"Id\" = {tableId} FOR UPDATE", ct);

    private static DonHang? FindUnpaidOrder(LuotBan session) =>
        session.DanhSachDonHang
            .Where(order => order.TrangThai is OrderStatuses.Open or OrderStatuses.AwaitingPayment)
            .OrderBy(order => order.TaoLuc)
            .ThenBy(order => order.Id)
            .FirstOrDefault();

    private static ServiceResult<TableCardDto> OrderChanged() =>
        ServiceResult<TableCardDto>.Failure(
            "Đơn hàng đã thay đổi. Hãy tải lại chi tiết đơn.", "ORDER_CHANGED", 409);

    private async Task<TableCardDto?> ReloadTableCardAsync(long tableId, CancellationToken ct)
    {
        var table = await _db.Bans
            .AsNoTracking()
            .FirstOrDefaultAsync(b => b.Id == tableId, ct);

        if (table is null)
        {
            return null;
        }

        var activeSession = await _db.LuotBans
            .AsNoTracking()
            .Where(l => l.IdBan == tableId && l.TraBanLuc == null)
            .Include(l => l.DanhSachDonHang)
                .ThenInclude(d => d.DanhSachDongMon)
                    .ThenInclude(dm => dm.DanhSachYeuCauHuy)
            .OrderByDescending(l => l.MoLuc)
            .FirstOrDefaultAsync(ct);

        return BuildTableCardDto(table, activeSession, DateTimeOffset.UtcNow);
    }

    private static TableCardDto BuildTableCardDto(
        Ban table,
        LuotBan? activeSession,
        DateTimeOffset now)
    {
        var areaName = ResolveAreaName(table.Ma, table.Ten);

        if (activeSession is null)
        {
            return new TableCardDto(
                TableId: table.Id,
                TableCode: table.Ma,
                TableName: table.Ten,
                AreaName: areaName,
                VisualStatus: TableVisualStatuses.Empty,
                BadgeText: "Bàn trống",
                DisplayAmountVnd: 0,
                TotalItemsCount: 0,
                SeatedMinutes: null,
                ActiveSessionId: null,
                ActiveOrderLabel: null,
                ActiveOrderStatus: null,
                SessionDetail: null);
        }

        var seatedMinutes = Math.Max(1, (int)Math.Floor((now - activeSession.MoLuc).TotalMinutes));
        var sortedOrders = activeSession.DanhSachDonHang
            .Where(o => o.TrangThai != OrderStatuses.Cancelled)
            .OrderBy(o => o.TaoLuc)
            .ThenBy(o => o.Id)
            .ToList();

        var orderDtos = new List<OrderDetailDto>(sortedOrders.Count);
        long totalAllOrdersVnd = 0;
        long paidAmountVnd = 0;
        int totalAllItemsCount = 0;
        bool hasPaidOrder = false;

        for (int i = 0; i < sortedOrders.Count; i++)
        {
            var order = sortedOrders[i];
            var orderDto = BuildOrderDetailDto(order, i + 1);

            if (order.TrangThai == OrderStatuses.Paid)
            {
                hasPaidOrder = true;
                paidAmountVnd += orderDto.TotalAmountVnd;
            }

            totalAllOrdersVnd += orderDto.TotalAmountVnd;
            totalAllItemsCount += orderDto.TotalItemsCount;
            orderDtos.Add(orderDto);
        }

        var remainingAmountVnd = Math.Max(0, totalAllOrdersVnd - paidAmountVnd);
        var activeUnpaidOrder = orderDtos.FirstOrDefault(o =>
            o.Status == OrderStatuses.Open || o.Status == OrderStatuses.AwaitingPayment);

        var canCloseTable = activeUnpaidOrder is null || activeUnpaidOrder.TotalAmountVnd == 0;

        string visualStatus;
        string badgeText;
        long displayAmountVnd;

        if (activeUnpaidOrder is not null && activeUnpaidOrder.Status == OrderStatuses.AwaitingPayment)
        {
            visualStatus = TableVisualStatuses.AwaitingQr;
            badgeText = "Chờ VietQR";
            displayAmountVnd = activeUnpaidOrder.TotalAmountVnd;
        }
        else if (hasPaidOrder && activeUnpaidOrder is not null && activeUnpaidOrder.TotalAmountVnd > 0)
        {
            visualStatus = TableVisualStatuses.AddOn;
            badgeText = $"Gọi thêm ({activeUnpaidOrder.TotalItemsCount})";
            displayAmountVnd = activeUnpaidOrder.TotalAmountVnd;
        }
        else
        {
            visualStatus = TableVisualStatuses.Occupied;
            badgeText = "Có khách";
            displayAmountVnd = remainingAmountVnd > 0 ? remainingAmountVnd : totalAllOrdersVnd;
        }

        var sessionDetail = new TableSessionDetailDto(
            SessionId: activeSession.Id,
            TableId: table.Id,
            TableCode: table.Ma,
            TableName: table.Ten,
            OpenedAt: activeSession.MoLuc,
            SeatedMinutes: seatedMinutes,
            TotalAllOrdersVnd: totalAllOrdersVnd,
            PaidAmountVnd: paidAmountVnd,
            RemainingAmountVnd: remainingAmountVnd,
            ActiveUnpaidOrderId: activeUnpaidOrder?.Id,
            ActiveUnpaidOrderCode: activeUnpaidOrder?.Code,
            ActiveUnpaidOrderStatus: activeUnpaidOrder?.Status,
            CanCloseTable: canCloseTable,
            Orders: orderDtos);

        return new TableCardDto(
            TableId: table.Id,
            TableCode: table.Ma,
            TableName: table.Ten,
            AreaName: areaName,
            VisualStatus: visualStatus,
            BadgeText: badgeText,
            DisplayAmountVnd: displayAmountVnd,
            TotalItemsCount: totalAllItemsCount,
            SeatedMinutes: seatedMinutes,
            ActiveSessionId: activeSession.Id,
            ActiveOrderLabel: activeUnpaidOrder?.DisplayLabel,
            ActiveOrderStatus: activeUnpaidOrder?.Status,
            SessionDetail: sessionDetail);
    }

    private static OrderDetailDto BuildOrderDetailDto(DonHang order, int orderNumber)
    {
        var lines = new List<OrderLineDto>(order.DanhSachDongMon.Count);
        long total = 0;
        int itemCount = 0;

        foreach (var line in order.DanhSachDongMon.OrderBy(l => l.GhiMonLuc).ThenBy(l => l.Id))
        {
            var cancelStatus = line.DanhSachYeuCauHuy
                .OrderByDescending(request => request.YeuCauLuc)
                .FirstOrDefault()?.TrangThai;
            var wasCancelled = string.Equals(cancelStatus, "approved", StringComparison.OrdinalIgnoreCase);
            var lineTotal = wasCancelled ? 0 : line.DonGiaLucBanVnd * line.SoLuong;
            total += lineTotal;
            if (!wasCancelled) itemCount += line.SoLuong;

            lines.Add(new(
                line.Id, line.IdMon, line.TenMonLucBan, line.DonGiaLucBanVnd,
                line.SoLuong, lineTotal, line.GhiChu, line.GhiMonLuc, cancelStatus));
        }

        return new(
            order.Id, order.Ma, $"#{GetOrderLetter(orderNumber)}", order.TrangThai,
            order.TaoLuc, order.ThanhToanLuc, total, itemCount,
            orderNumber > 1 && order.TrangThai is OrderStatuses.Open or OrderStatuses.AwaitingPayment, lines);
    }

    private static long CalculateOrderTotal(DonHang order)
    {
        long sum = 0;
        foreach (var line in order.DanhSachDongMon)
        {
            var isCancelled = line.DanhSachYeuCauHuy.Any(y =>
                string.Equals(y.TrangThai, "approved", StringComparison.OrdinalIgnoreCase));
            if (!isCancelled)
            {
                sum += line.DonGiaLucBanVnd * line.SoLuong;
            }
        }
        return sum;
    }

    private static string GetOrderLetter(int index)
    {
        if (index <= 0) return "A";
        return ((char)('A' + ((index - 1) % 26))).ToString();
    }

    private static string ResolveAreaName(string code, string name)
    {
        if (name.Contains('·'))
        {
            return name.Split('·')[0].Trim();
        }
        var upper = code.ToUpperInvariant();
        if (upper.StartsWith("SV")) return "Sân vườn";
        if (upper.StartsWith("M")) return "Tầng 2 - Workshop & Nhóm";
        return "Tầng 1 - Khu phục vụ";
    }
}
