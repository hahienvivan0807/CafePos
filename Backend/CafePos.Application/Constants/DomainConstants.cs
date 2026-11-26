namespace CafePos.Application.Constants;

public static class RoleNames
{
    public const string Staff = "Staff";
    public const string Manager = "Manager";
    public const string StaffOrManager = "Staff,Manager";
}

public static class ShiftStatuses
{
    public const string DangMo = "DangMo";
    public const string DaDong = "DaDong";
}

public static class OrderStatuses
{
    public const string Open = "open";
    public const string AwaitingPayment = "awaiting_payment";
    public const string Paid = "paid";
    public const string Cancelled = "cancelled";
}

public static class TableVisualStatuses
{
    public const string Empty = "EMPTY";             // Bàn trống (#059669 Emerald Mint)
    public const string Occupied = "OCCUPIED";       // Đang có khách (#475569 Clean Slate)
    public const string AwaitingQr = "AWAITING_QR";  // Chờ VietQR (#D97706 Amber Daylight)
    public const string AddOn = "ADD_ON";            // Gọi thêm / Cần thu (#EA580C Coral Terracotta)
}
