using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.Pos;

namespace CafePos.Application.Interfaces.Pos;

public interface IPosDashboardService
{
    /// <summary>
    /// Lấy toàn bộ dữ liệu sơ đồ bàn, lượt dùng bàn, đơn hàng, dòng món và thực đơn từ database cafe_pos.
    /// Tuyệt đối không chứa dữ liệu viết cứng.
    /// </summary>
    Task<ServiceResult<DashboardOverviewDto>> GetDashboardOverviewAsync(
        CancellationToken ct = default);

    Task<ServiceResult<OrderDetailsViewDto>> GetOrderDetailsAsync(
        long orderId,
        CancellationToken ct = default);

    /// <summary>
    /// Mở bàn mới (tạo LuotBan) hoặc ghi thêm món vào đơn đang mở / tạo đơn mới (Đơn #B) nếu đơn trước đã thanh toán.
    /// </summary>
    Task<ServiceResult<TableCardDto>> OpenTableOrAddItemsAsync(
        Guid staffUserId,
        OpenTableOrAddItemsRequestDto request,
        CancellationToken ct = default);

    /// <summary>
    /// Chuyển trạng thái đơn đang mở sang chờ thanh toán VietQR ('awaiting_payment').
    /// </summary>
    Task<ServiceResult<TableCardDto>> RequestVietQrAsync(
        Guid staffUserId,
        long tableId,
        CancellationToken ct = default,
        long? orderId = null);

    /// <summary>
    /// Xác nhận đơn hàng đã thanh toán đủ qua VietQR ('paid'). Bàn vẫn ở trạng thái Đang có khách cho đến khi Trả bàn.
    /// </summary>
    Task<ServiceResult<TableCardDto>> ConfirmVietQrPaidAsync(
        Guid staffUserId,
        long tableId,
        CancellationToken ct = default,
        long? orderId = null);

    /// <summary>
    /// Trả bàn (đóng LuotBan) khi khách rời đi và tất cả các đơn trong lượt đã xử lý xong ('paid' hoặc 'cancelled').
    /// </summary>
    Task<ServiceResult<TableCardDto>> CloseTableSessionAsync(
        Guid staffUserId,
        long tableId,
        CancellationToken ct = default);
}
