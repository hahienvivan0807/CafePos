using System.Security.Cryptography;
using System.Text;
using CafePos.Application.Constants;
using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.Pos.ThanhToan;
using CafePos.Application.Entities;
using CafePos.Application.Interfaces.Pos.ThanhToan;
using CafePos.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace CafePos.Infrastructure.Services.Pos.ThanhToan;

/// <summary>
/// Nghiệp vụ Thanh toán VietQR, Webhook chuẩn SePay (chống trùng Idempotency) và Đối soát thu dư.
/// </summary>
public class PaymentService : IPaymentService
{
    private readonly CafePosDbContext _db;
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<PaymentService> _logger;

    public PaymentService(
        CafePosDbContext db,
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory,
        ILogger<PaymentService> logger)
    {
        _db = db;
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    private string BankId => (_configuration["VietQr:BankId"] ?? "MB").Trim();
    private string AccountNo => (_configuration["VietQr:AccountNo"] ?? "DEMO000123456").Trim();
    private string AccountName => (_configuration["VietQr:AccountName"] ?? "PINVUTRU CAFE").Trim();
    private string QrTemplate => (_configuration["VietQr:Template"] ?? "compact2").Trim();
    private string? WebhookApiKey => _configuration["VietQr:WebhookApiKey"]?.Trim();

    public async Task<ServiceResult<OrderPaymentStateDto>> GetOrderPaymentStateAsync(
        long orderId,
        CancellationToken ct = default)
    {
        var order = await LoadOrderGraphAsync(orderId, ct);
        if (order is null)
        {
            return ServiceResult<OrderPaymentStateDto>.Failure(
                "Không tìm thấy đơn hàng.",
                "ORDER_NOT_FOUND",
                404);
        }

        return ServiceResult<OrderPaymentStateDto>.Success(BuildOrderPaymentState(order));
    }

    public async Task<ServiceResult<OrderPaymentStateDto>> GenerateOrRefreshVietQrAsync(
        long orderId,
        CancellationToken ct = default)
    {
        var order = await LoadOrderGraphAsync(orderId, ct);
        if (order is null)
        {
            return ServiceResult<OrderPaymentStateDto>.Failure(
                "Không tìm thấy đơn hàng cần tạo mã VietQR.",
                "ORDER_NOT_FOUND",
                404);
        }

        if (order.TrangThai == OrderStatuses.Cancelled)
        {
            return ServiceResult<OrderPaymentStateDto>.Failure(
                "Đơn hàng đã hủy nên không thể tạo mã VietQR.",
                "ORDER_CANCELLED",
                409);
        }

        var orderTotal = ComputeOrderTotal(order);
        if (orderTotal <= 0)
        {
            return ServiceResult<OrderPaymentStateDto>.Failure(
                "Đơn hàng chưa có món hợp lệ để tạo mã thanh toán.",
                "EMPTY_ORDER",
                400);
        }

        var totalPaid = order.DanhSachGiaoDich.Sum(t => t.SoTienVnd);
        var remaining = Math.Max(0L, orderTotal - totalPaid);
        if (remaining == 0)
        {
            if (order.TrangThai != OrderStatuses.Paid)
            {
                order.TrangThai = OrderStatuses.Paid;
                order.ThanhToanLuc ??= DateTimeOffset.UtcNow;
                await _db.SaveChangesAsync(ct);
            }
            return ServiceResult<OrderPaymentStateDto>.Success(
                BuildOrderPaymentState(order),
                "Đơn hàng đã thu đủ tiền.");
        }

        var activePending = order.DanhSachYeuCauQr
            .Where(q => q.TrangThai == "DangCho")
            .OrderByDescending(q => q.PhienBan)
            .FirstOrDefault();

        // Nếu mã QR đang chờ đã khớp chính xác số tiền còn phải thu thì tái sử dụng
        if (activePending is not null && activePending.SoTienVnd == remaining)
        {
            if (order.TrangThai == OrderStatuses.Open)
            {
                order.TrangThai = OrderStatuses.AwaitingPayment;
                await _db.SaveChangesAsync(ct);
            }
            return ServiceResult<OrderPaymentStateDto>.Success(
                BuildOrderPaymentState(order),
                $"Mã VietQR {activePending.MaThamChieu} đang sẵn sàng cho số tiền {remaining:N0}đ.");
        }

        // Nếu tổng đơn thay đổi (ví dụ gọi thêm món 65k -> 90k), đánh dấu QR cũ 'DaThayThe' nhưng giữ nguyên MaThamChieu để đối soát
        var now = DateTimeOffset.UtcNow;
        foreach (var oldQr in order.DanhSachYeuCauQr.Where(q => q.TrangThai == "DangCho"))
        {
            oldQr.TrangThai = "DaThayThe";
            oldQr.CapNhatLuc = now;
        }

        var nextVersion = order.DanhSachYeuCauQr.Count == 0
            ? 1
            : order.DanhSachYeuCauQr.Max(q => q.PhienBan) + 1;
        var refCode = $"POS{order.Id}V{nextVersion}";
        var qrImageUrl =
            $"https://img.vietqr.io/image/{Uri.EscapeDataString(BankId)}-{Uri.EscapeDataString(AccountNo)}-{Uri.EscapeDataString(QrTemplate)}.png" +
            $"?amount={remaining}&addInfo={Uri.EscapeDataString(refCode)}&accountName={Uri.EscapeDataString(AccountName)}";

        var newQr = new YeuCauQrThanhToan
        {
            IdDonHang = order.Id,
            PhienBan = nextVersion,
            MaThamChieu = refCode,
            SoTienVnd = remaining,
            MaNganHang = BankId,
            SoTaiKhoan = AccountNo,
            TenTaiKhoan = AccountName,
            DuongDanAnhQr = qrImageUrl,
            TrangThai = "DangCho",
            TaoLuc = now
        };

        order.DanhSachYeuCauQr.Add(newQr);
        order.TrangThai = OrderStatuses.AwaitingPayment;
        await _db.SaveChangesAsync(ct);

        var msg = nextVersion == 1
            ? $"Đã tạo mã VietQR {refCode} cho số tiền {remaining:N0}đ."
            : $"Tổng đơn thay đổi — đã ngừng mã QR cũ và tạo mã mới {refCode} cho số tiền còn phải thu {remaining:N0}đ.";

        return ServiceResult<OrderPaymentStateDto>.Success(BuildOrderPaymentState(order), msg);
    }

    public async Task<ServiceResult<OrderPaymentStateDto>> RecordCashPaymentAsync(
        long orderId,
        Guid staffUserId,
        RecordCashPaymentRequestDto request,
        CancellationToken ct = default)
    {
        var order = await LoadOrderGraphAsync(orderId, ct);
        if (order is null)
        {
            return ServiceResult<OrderPaymentStateDto>.Failure(
                "Không tìm thấy đơn hàng.",
                "ORDER_NOT_FOUND",
                404);
        }

        var orderTotal = ComputeOrderTotal(order);
        var totalPaid = order.DanhSachGiaoDich.Sum(t => t.SoTienVnd);
        var remaining = Math.Max(0L, orderTotal - totalPaid);

        if (remaining <= 0)
        {
            return ServiceResult<OrderPaymentStateDto>.Failure(
                "Đơn hàng này đã được thanh toán đủ.",
                "ALREADY_PAID",
                409);
        }

        var amount = request.ReceivedAmountVnd.HasValue && request.ReceivedAmountVnd.Value > 0
            ? Math.Min(request.ReceivedAmountVnd.Value, remaining)
            : remaining;

        var now = DateTimeOffset.UtcNow;
        var tx = new GiaoDichThanhToan
        {
            IdDonHang = order.Id,
            PhuongThuc = "cash",
            CongThanhToan = "Cash",
            NoiDungChuyenKhoan = string.IsNullOrWhiteSpace(request.Note)
                ? $"Thu tiền mặt tại quầy cho đơn {order.Ma}"
                : request.Note.Trim(),
            SoTienVnd = amount,
            CanDoiSoat = false,
            TrangThaiDoiSoat = "KhongCan",
            IdNguoiXacNhan = staffUserId,
            GhiNhanLuc = now
        };

        order.DanhSachGiaoDich.Add(tx);
        var newTotalPaid = totalPaid + amount;
        if (newTotalPaid >= orderTotal)
        {
            order.TrangThai = OrderStatuses.Paid;
            order.ThanhToanLuc = now;
            foreach (var qr in order.DanhSachYeuCauQr.Where(q => q.TrangThai == "DangCho"))
            {
                qr.TrangThai = "DaHuy";
                qr.CapNhatLuc = now;
            }
        }

        await _db.SaveChangesAsync(ct);

        return ServiceResult<OrderPaymentStateDto>.Success(
            BuildOrderPaymentState(order),
            $"Đã ghi nhận thu tiền mặt {amount:N0}đ cho đơn {order.Ma}.");
    }

    public async Task<ServiceResult<WebhookProcessResultDto>> ProcessSePayWebhookAsync(
        SePayWebhookRequestDto payload,
        string? authorizationHeader,
        bool bypassAuthForDemo = false,
        CancellationToken ct = default)
    {
        // 1. Xác thực Apikey (chống Webhook Spoofing)
        if (!bypassAuthForDemo)
        {
            var expectedKey = WebhookApiKey;
            if (string.IsNullOrWhiteSpace(expectedKey))
            {
                return ServiceResult<WebhookProcessResultDto>.Failure(
                    "Chưa cấu hình VietQr:WebhookApiKey trong User Secrets.",
                    "WEBHOOK_NOT_CONFIGURED",
                    503);
            }

            if (!ValidateSePayApiKey(authorizationHeader, expectedKey))
            {
                _logger.LogWarning("Từ chối VietQR webhook do sai hoặc thiếu Authorization Apikey.");
                return ServiceResult<WebhookProcessResultDto>.Failure(
                    "Xác thực Webhook Apikey không hợp lệ.",
                    "INVALID_WEBHOOK_APIKEY",
                    401);
            }
        }

        // 2. Chỉ ghi nhận giao dịch tiền vào
        if (!string.IsNullOrWhiteSpace(payload.TransferType) &&
            !string.Equals(payload.TransferType.Trim(), "in", StringComparison.OrdinalIgnoreCase))
        {
            return ServiceResult<WebhookProcessResultDto>.Success(
                new WebhookProcessResultDto(false, null, null, null, payload.TransferAmount, false, "ignored", "Bỏ qua giao dịch tiền ra."),
                "Bỏ qua giao dịch tiền ra.");
        }

        if (payload.TransferAmount <= 0)
        {
            return ServiceResult<WebhookProcessResultDto>.Failure(
                "Số tiền giao dịch phải lớn hơn 0.",
                "INVALID_AMOUNT",
                400);
        }

        // 3. Kiểm tra khớp số tài khoản nhận (khi có gửi accountNumber và không ở chế độ demo)
        if (!bypassAuthForDemo &&
            !string.IsNullOrWhiteSpace(payload.AccountNumber) &&
            !string.Equals(payload.AccountNumber.Trim(), AccountNo, StringComparison.OrdinalIgnoreCase))
        {
            return ServiceResult<WebhookProcessResultDto>.Failure(
                "Số tài khoản nhận tiền không khớp cấu hình cửa hàng.",
                "ACCOUNT_MISMATCH",
                400);
        }

        // 4. Chống ghi trùng (Idempotency) theo MaGiaoDichNganHang
        var bankTxId = ResolveBankTxId(payload);
        if (!string.IsNullOrWhiteSpace(bankTxId))
        {
            var existing = await _db.GiaoDichThanhToans
                .AsNoTracking()
                .Include(t => t.DonHang)
                .FirstOrDefaultAsync(t => t.MaGiaoDichNganHang == bankTxId, ct);

            if (existing is not null)
            {
                return ServiceResult<WebhookProcessResultDto>.Success(
                    new WebhookProcessResultDto(
                        true,
                        existing.IdDonHang,
                        existing.DonHang?.Ma,
                        existing.MaThamChieuKhop,
                        existing.SoTienVnd,
                        existing.CanDoiSoat,
                        existing.DonHang?.TrangThai ?? "unknown",
                        $"Giao dịch {bankTxId} đã được ghi nhận trước đó — bỏ qua để chống cộng trùng."),
                    $"Giao dịch {bankTxId} đã được ghi nhận trước đó (Idempotent).");
            }
        }

        // 5. Đối chiếu mã tham chiếu trong nội dung chuyển khoản (kể cả mã QR cũ 'DaThayThe'!)
        var content = (payload.Content ?? payload.Code ?? string.Empty).Trim();
        var matchedQr = await FindMatchingQrSessionAsync(content, ct);
        if (matchedQr is null)
        {
            return ServiceResult<WebhookProcessResultDto>.Failure(
                $"Không tìm thấy mã tham chiếu VietQR khớp với nội dung '{content}'.",
                "REFERENCE_NOT_FOUND",
                404);
        }

        var order = await LoadOrderGraphAsync(matchedQr.IdDonHang, ct);
        if (order is null)
        {
            return ServiceResult<WebhookProcessResultDto>.Failure(
                "Không tìm thấy đơn hàng tương ứng với mã QR.",
                "ORDER_NOT_FOUND",
                404);
        }

        var orderTotal = ComputeOrderTotal(order);
        var paidBefore = order.DanhSachGiaoDich.Sum(t => t.SoTienVnd);
        var paidAfter = paidBefore + payload.TransferAmount;
        var isLateOldQr = matchedQr.TrangThai == "DaThayThe";
        var isOverpaid = paidAfter > orderTotal;
        var needsReconciliation = isOverpaid || (isLateOldQr && paidBefore >= orderTotal);

        string? reconcileNote = null;
        if (needsReconciliation)
        {
            var overAmount = Math.Max(0L, paidAfter - orderTotal);
            reconcileNote = isLateOldQr
                ? $"Khách chuyển muộn vào mã QR cũ {matchedQr.MaThamChieu} ({payload.TransferAmount:N0}đ). Tổng đã thu {paidAfter:N0}đ / Tổng đơn {orderTotal:N0}đ → Thu dư {overAmount:N0}đ cần hoàn trả."
                : $"Thu dư {overAmount:N0}đ cho đơn {order.Ma} qua mã {matchedQr.MaThamChieu} (Tổng thu {paidAfter:N0}đ / Tổng đơn {orderTotal:N0}đ).";
        }

        var now = DateTimeOffset.UtcNow;
        var tx = new GiaoDichThanhToan
        {
            IdDonHang = order.Id,
            IdYeuCauQr = matchedQr.Id,
            PhuongThuc = "vietqr",
            MaGiaoDichNganHang = bankTxId,
            CongThanhToan = string.IsNullOrWhiteSpace(payload.Gateway) ? "VietQR" : payload.Gateway.Trim(),
            MaThamChieuKhop = matchedQr.MaThamChieu,
            NoiDungChuyenKhoan = content,
            SoTienVnd = payload.TransferAmount,
            CanDoiSoat = needsReconciliation,
            TrangThaiDoiSoat = needsReconciliation ? "ChoXuLy" : "KhongCan",
            GhiChuDoiSoat = reconcileNote,
            GhiNhanLuc = now
        };

        order.DanhSachGiaoDich.Add(tx);

        if (matchedQr.TrangThai == "DangCho")
        {
            matchedQr.TrangThai = "DaThuDu";
            matchedQr.CapNhatLuc = now;
        }

        if (paidAfter >= orderTotal && order.TrangThai != OrderStatuses.Paid)
        {
            order.TrangThai = OrderStatuses.Paid;
            order.ThanhToanLuc = now;
            foreach (var pendingQr in order.DanhSachYeuCauQr.Where(q => q.TrangThai == "DangCho"))
            {
                pendingQr.TrangThai = "DaThuDu";
                pendingQr.CapNhatLuc = now;
            }
        }

        await _db.SaveChangesAsync(ct);

        var summary = needsReconciliation
            ? $"Đã ghi nhận {payload.TransferAmount:N0}đ ({matchedQr.MaThamChieu}) và tự động đưa khoản thu dư vào mục Cần đối soát!"
            : paidAfter >= orderTotal
                ? $"Đã nhận đủ {payload.TransferAmount:N0}đ qua mã {matchedQr.MaThamChieu} — Đơn {order.Ma} chuyển sang Đã thanh toán."
                : $"Đã nhận một phần {payload.TransferAmount:N0}đ qua mã {matchedQr.MaThamChieu} — còn thiếu {(orderTotal - paidAfter):N0}đ.";

        return ServiceResult<WebhookProcessResultDto>.Success(
            new WebhookProcessResultDto(
                false,
                order.Id,
                order.Ma,
                matchedQr.MaThamChieu,
                payload.TransferAmount,
                needsReconciliation,
                order.TrangThai,
                summary),
            summary);
    }

    public async Task<ServiceResult<ReconciliationSummaryDto>> GetReconciliationAsync(
        string? filter = "all",
        CancellationToken ct = default)
    {
        var query = _db.GiaoDichThanhToans
            .AsNoTracking()
            .Include(t => t.DonHang)
            .ThenInclude(d => d!.LuotBan)
            .ThenInclude(l => l!.Ban)
            .AsQueryable();

        var normalized = (filter ?? "all").Trim().ToLowerInvariant();
        if (normalized == "pending")
        {
            query = query.Where(t => t.CanDoiSoat && t.TrangThaiDoiSoat == "ChoXuLy");
        }
        else if (normalized == "resolved")
        {
            query = query.Where(t => t.CanDoiSoat && t.TrangThaiDoiSoat == "DaXuLy");
        }
        else if (normalized == "flagged")
        {
            query = query.Where(t => t.CanDoiSoat);
        }

        var rows = await query
            .OrderByDescending(t => t.CanDoiSoat && t.TrangThaiDoiSoat == "ChoXuLy")
            .ThenByDescending(t => t.GhiNhanLuc)
            .Take(100)
            .ToListAsync(ct);

        var allFlagged = await _db.GiaoDichThanhToans
            .AsNoTracking()
            .Where(t => t.CanDoiSoat)
            .Select(t => new { t.TrangThaiDoiSoat, t.SoTienVnd })
            .ToListAsync(ct);

        var pendingCount = allFlagged.Count(x => x.TrangThaiDoiSoat == "ChoXuLy");
        var resolvedCount = allFlagged.Count(x => x.TrangThaiDoiSoat == "DaXuLy");
        var pendingTotal = allFlagged.Where(x => x.TrangThaiDoiSoat == "ChoXuLy").Sum(x => x.SoTienVnd);

        var items = rows.Select(t => ToTransactionDto(t)).ToList();
        return ServiceResult<ReconciliationSummaryDto>.Success(
            new ReconciliationSummaryDto(pendingCount, resolvedCount, pendingTotal, items));
    }

    public async Task<ServiceResult<PaymentTransactionDto>> ResolveReconciliationAsync(
        long transactionId,
        Guid managerUserId,
        ResolveReconciliationRequestDto request,
        CancellationToken ct = default)
    {
        var tx = await _db.GiaoDichThanhToans
            .Include(t => t.DonHang)
            .ThenInclude(d => d!.LuotBan)
            .ThenInclude(l => l!.Ban)
            .FirstOrDefaultAsync(t => t.Id == transactionId, ct);

        if (tx is null)
        {
            return ServiceResult<PaymentTransactionDto>.Failure(
                "Không tìm thấy giao dịch cần đối soát.",
                "TRANSACTION_NOT_FOUND",
                404);
        }

        if (!tx.CanDoiSoat)
        {
            return ServiceResult<PaymentTransactionDto>.Failure(
                "Giao dịch này không nằm trong danh sách cần đối soát.",
                "NOT_FLAGGED",
                400);
        }

        var note = (request.ResolutionNote ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(note))
        {
            note = "Quản lý xác nhận đã đối soát & hoàn tiền cho khách.";
        }

        tx.TrangThaiDoiSoat = "DaXuLy";
        tx.GhiChuDoiSoat = string.IsNullOrWhiteSpace(tx.GhiChuDoiSoat)
            ? $"[Đã xử lý]: {note}"
            : $"{tx.GhiChuDoiSoat}\n[Đã xử lý]: {note}";
        tx.IdNguoiXacNhan = managerUserId;
        tx.DoiSoatLuc = DateTimeOffset.UtcNow;

        await _db.SaveChangesAsync(ct);

        return ServiceResult<PaymentTransactionDto>.Success(
            ToTransactionDto(tx),
            "Đã đánh dấu giao dịch hoàn tất đối soát.");
    }

    public async Task<ServiceResult<byte[]>> GetQrImageBytesAsync(
        long qrId,
        CancellationToken ct = default)
    {
        var qr = await _db.YeuCauQrThanhToans
            .AsNoTracking()
            .FirstOrDefaultAsync(q => q.Id == qrId, ct);

        if (qr is null)
        {
            return ServiceResult<byte[]>.Failure("Không tìm thấy mã QR.", "QR_NOT_FOUND", 404);
        }

        var client = _httpClientFactory.CreateClient();
        client.Timeout = TimeSpan.FromSeconds(15);

        // Ưu tiên SePay QR (chuẩn NAPAS 247 tốc độ cao), fallback sang img.vietqr.io
        var sePayUrl =
            $"https://qr.sepay.vn/img?acc={Uri.EscapeDataString(qr.SoTaiKhoan)}&bank={Uri.EscapeDataString(qr.MaNganHang)}&amount={qr.SoTienVnd}&des={Uri.EscapeDataString(qr.MaThamChieu)}&template=compact";

        foreach (var url in new[] { sePayUrl, qr.DuongDanAnhQr })
        {
            try
            {
                using var resp = await client.GetAsync(url, ct);
                if (resp.IsSuccessStatusCode)
                {
                    var bytes = await resp.Content.ReadAsByteArrayAsync(ct);
                    if (bytes.Length > 100)
                    {
                        return ServiceResult<byte[]>.Success(bytes);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Không tải được ảnh QR từ {Url}", url);
            }
        }

        return ServiceResult<byte[]>.Failure(
            "Không thể tải ảnh VietQR từ máy chủ ngân hàng.",
            "QR_IMAGE_FETCH_FAILED",
            502);
    }

    private async Task<DonHang?> LoadOrderGraphAsync(long orderId, CancellationToken ct)
    {
        return await _db.DonHangs
            .Include(d => d.LuotBan)
            .ThenInclude(l => l!.Ban)
            .Include(d => d.DanhSachDongMon)
            .ThenInclude(m => m.DanhSachYeuCauHuy)
            .Include(d => d.DanhSachYeuCauQr)
            .Include(d => d.DanhSachGiaoDich)
            .FirstOrDefaultAsync(d => d.Id == orderId, ct);
    }

    private async Task<YeuCauQrThanhToan?> FindMatchingQrSessionAsync(string content, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(content)) return null;
        var upper = content.ToUpperInvariant();

        // Tìm trong các mã QR gần nhất (bao gồm cả mã cũ DaThayThe để bắt giao dịch chuyển muộn)
        var recentQrs = await _db.YeuCauQrThanhToans
            .OrderByDescending(q => q.TaoLuc)
            .Take(200)
            .ToListAsync(ct);

        return recentQrs.FirstOrDefault(q =>
            upper.Contains(q.MaThamChieu.ToUpperInvariant(), StringComparison.Ordinal));
    }

    private static long ComputeOrderTotal(DonHang order)
    {
        long total = 0;
        foreach (var line in order.DanhSachDongMon)
        {
            var isApprovedCancel = line.DanhSachYeuCauHuy.Any(c => c.TrangThai == "approved");
            if (!isApprovedCancel)
            {
                total += line.DonGiaLucBanVnd * line.SoLuong;
            }
        }
        return total;
    }

    private static OrderPaymentStateDto BuildOrderPaymentState(DonHang order)
    {
        var orderTotal = ComputeOrderTotal(order);
        var totalPaid = order.DanhSachGiaoDich.Sum(t => t.SoTienVnd);
        var remaining = Math.Max(0L, orderTotal - totalPaid);
        var overpaid = Math.Max(0L, totalPaid - orderTotal);
        var hasPendingRec = order.DanhSachGiaoDich.Any(t => t.CanDoiSoat && t.TrangThaiDoiSoat == "ChoXuLy");

        var qrList = order.DanhSachYeuCauQr
            .OrderByDescending(q => q.PhienBan)
            .Select(q => new VietQrSessionDto(
                q.Id,
                q.PhienBan,
                q.MaThamChieu,
                q.SoTienVnd,
                q.MaNganHang,
                q.SoTaiKhoan,
                q.TenTaiKhoan,
                q.DuongDanAnhQr,
                q.TrangThai,
                q.TaoLuc))
            .ToList();

        var activeQr = qrList.FirstOrDefault(q => q.Status == "DangCho");
        var txList = order.DanhSachGiaoDich
            .OrderByDescending(t => t.GhiNhanLuc)
            .Select(t => ToTransactionDto(t, order))
            .ToList();

        var tableName = order.LuotBan?.Ban?.Ten ?? $"Bàn #{order.IdLuotBan}";
        return new OrderPaymentStateDto(
            order.Id,
            order.Ma,
            tableName,
            order.TrangThai,
            orderTotal,
            totalPaid,
            remaining,
            overpaid,
            hasPendingRec,
            activeQr,
            qrList,
            txList);
    }

    private static PaymentTransactionDto ToTransactionDto(GiaoDichThanhToan t, DonHang? orderOverride = null)
    {
        var d = orderOverride ?? t.DonHang;
        return new PaymentTransactionDto(
            t.Id,
            t.IdDonHang,
            d?.Ma ?? $"#{t.IdDonHang}",
            d?.LuotBan?.Ban?.Ten ?? "—",
            t.PhuongThuc,
            t.MaGiaoDichNganHang,
            t.CongThanhToan,
            t.MaThamChieuKhop,
            t.NoiDungChuyenKhoan,
            t.SoTienVnd,
            t.CanDoiSoat,
            t.TrangThaiDoiSoat,
            t.GhiChuDoiSoat,
            t.GhiNhanLuc,
            t.DoiSoatLuc);
    }

    private static bool ValidateSePayApiKey(string? authHeader, string expectedKey)
    {
        if (string.IsNullOrWhiteSpace(authHeader)) return false;
        var trimmed = authHeader.Trim();
        var token = trimmed.StartsWith("Apikey ", StringComparison.OrdinalIgnoreCase)
            ? trimmed[7..].Trim()
            : trimmed.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
                ? trimmed[7..].Trim()
                : trimmed;

        var a = Encoding.UTF8.GetBytes(token);
        var b = Encoding.UTF8.GetBytes(expectedKey);
        return a.Length == b.Length && CryptographicOperations.FixedTimeEquals(a, b);
    }

    private static string? ResolveBankTxId(SePayWebhookRequestDto payload)
    {
        if (payload.Id is not null)
        {
            var s = payload.Id.ToString()?.Trim();
            if (!string.IsNullOrWhiteSpace(s)) return s;
        }
        return string.IsNullOrWhiteSpace(payload.ReferenceCode) ? null : payload.ReferenceCode.Trim();
    }
}
