# Quy Trình Xử Lý Dữ Liệu Khi Xóa Nhân Viên

Tài liệu ghi nhận ngắn gọn cơ chế xóa nhân viên hiện tại trong hệ thống **PinVuTru Cafe POS** để tránh quên khi mở rộng thêm bảng nghiệp vụ mới.

---

## 1. Vị trí xử lý trong mã nguồn
- **API Endpoint:** `DELETE /api/manager/staff/{staffUserId}` — `Backend/CafePos.Api/Controllers/QuanLy/NhanVien/StaffManagementController.cs` (yêu cầu quyền `ManagerOnly` + `X-CSRF-TOKEN`).
- **Xử lý nghiệp vụ & dữ liệu:** `DeleteStaffAsync` — `Backend/CafePos.Infrastructure/Services/QuanLy/NhanVien/StaffManagementService.cs`.
- **Cột trạng thái hoạt động trong DB:** `pos."NguoiDung"."DangHoatDong"` (`bool`, mặc định `true`).

---

## 2. Luồng xử lý dữ liệu khi Quản lý bấm "Xóa"

1. **Chặn tự xóa chính mình:**
   - Nếu `staffUserId == currentManagerId` → từ chối (`400`, `CANNOT_DELETE_SELF`).

2. **Kiểm tra lịch sử phát sinh (`hasHistory`):**
   Hệ thống kiểm tra nhân viên có từng xuất hiện trong **5 bảng** sau hay chưa:
   - `pos."CaLamViec"` (`IdNguoiDung`)
   - `pos."LuotBan"` (`IdNguoiMo`, `IdNguoiTraBan`)
   - `pos."DonHang"` (`IdNguoiTao`)
   - `pos."DongMon"` (`IdNguoiGhiMon`)
   - `pos."YeuCauHuyMon"` (`IdNguoiYeuCau`, `IdNguoiXuLy`)

3. **Hai nhánh kết quả:**
   - **Trường hợp 1 — Đã có lịch sử (`hasHistory == true`) → KHÔNG xóa cứng:**
     - Chuyển `pos."NguoiDung"."DangHoatDong" = false` (trạng thái **Đã khóa**).
     - Gọi `UpdateSecurityStampAsync(user)` để thu hồi ngay mọi phiên đăng nhập cũ.
     - Trả mã `409` (`STAFF_HAS_HISTORY_LOCKED`) và giữ nguyên dữ liệu phục vụ đối soát, hóa đơn, ca làm.
   - **Trường hợp 2 — Chưa có bất kỳ lịch sử nào (`hasHistory == false`) → Xóa vật lý:**
     - Gọi `_userManager.DeleteAsync(user)` để xóa sạch tài khoản (phục vụ trường hợp tạo nhầm nhân viên chưa từng sử dụng).

---

## 3. Lưu ý bắt buộc khi thêm bảng mới sau này

Khi dự án bổ sung các bảng mới có liên kết đến nhân viên (ví dụ: `LichPhanCa`, `BangLuong`, `PhieuChi`, `KiemKho`...):

1. **Cập nhật điều kiện `hasHistory`** trong `StaffManagementService.DeleteStaffAsync`:
   - Nối thêm `|| await _db.<BangMoi>.AnyAsync(x => x.IdNguoiDung == staffUserId, ct)` để đảm bảo không bao giờ chạy xuống `DeleteAsync(user)`.
2. **Bảo vệ 2 lớp ở PostgreSQL:**
   - Khóa ngoại trỏ về `pos."NguoiDung"("Id")` luôn đặt **`ON DELETE RESTRICT`** (không dùng `ON DELETE CASCADE`) để chính database cũng chặn xóa cứng nếu lỡ quên cập nhật code.

---

## 4. Tra cứu & khôi phục khi tiệm cần đối soát
- Tài khoản bị chuyển sang **Đã khóa** (`DangHoatDong = false`) không thể đăng nhập POS, nhưng vẫn giữ nguyên tên trong hóa đơn, ca làm và đối soát lịch sử.
- Quản lý có thể lọc trạng thái **Đã khóa** trên màn hình **Quản lý nhân viên** để xem lại thông tin hoặc mở **Sửa** → đổi lại **Đang hoạt động** nếu nhân viên quay lại làm việc.
