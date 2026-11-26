# Bàn giao dự án POS quán cà phê

Cập nhật ngày 25/11/2026. Tệp này dùng để tiếp tục công việc trong một phiên Codex hoặc Antigravity mới. [Lịch sử chat](Lich-su-chat-POS.md) giữ các trao đổi và quyết định theo thời gian.

## Bắt đầu phiên mới

- Mở dự án `D:\Pin Học Lập Trình\Dự án cá nhân\Quản Lý Quán Cà Phê`. Đây là thư mục có `Backend`, `PosClient`, `Docs` và `WebService`.
- Đọc `Docs/PROJECT.md`, `Docs/TOM-TAT-DU-AN-POS.md`, `Docs/THIET-KE-LUONG-DANG-NHAP.md` và `Docs/HowToRun.md`. Một số tài liệu và câu trả lời mô tả các bước cũ. Ưu tiên quyết định mới nhất bên dưới và kiểm tra mã hiện tại.
- Màn hình POS đã chốt nằm trong [dự án Google Stitch](https://stitch.google.com/projects/4907969291961553465). Antigravity tiếp tục ở cuộc trò chuyện **Triển Khai Màn Đăng Nhập CafePos**.

## Mục tiêu và phạm vi

Xây dựng POS phục vụ tại bàn cho một quán cà phê làm dự án cá nhân và portfolio Software/AI Engineer. Làm web trước bằng Flutter Web, có thể phát triển app sau. Backend ASP.NET Core C# theo ba lớp `CafePos.Api`, `CafePos.Application` và `CafePos.Infrastructure`, dùng PostgreSQL. `WebService` là web theo dõi tiến độ dự án riêng, có checklist và phần tóm tắt thu gọn. Không nhầm thư mục này với giao diện POS trong `PosClient`.

| Vai trò | Phạm vi |
| --- | --- |
| Nhân viên (`Staff`) | Đăng nhập, sử dụng các chức năng được cấp. Chỉ thao tác dịch vụ tại bàn trong khung giờ ca được xếp. Ngoài ca vẫn dùng được các chức năng khác theo quyền. Chấm công check-in/check-out để giai đoạn sau, tách khỏi điều kiện thao tác bàn. |
| Quản lý (`Manager`) | Vào thẳng khu quản lý. Được thao tác POS và bàn không phụ thuộc ca. Quản lý món và giá, duyệt hủy món, xem đối soát, báo cáo, dự báo và trợ lý AI. |

Khách gọi món qua nhân viên và dùng ứng dụng ngân hàng quét VietQR khi thanh toán. MVP chưa có tài khoản hoặc giao diện riêng cho khách, chưa dùng QR để gọi món. In hóa đơn vật lý và tự in vẫn để ngỏ.

## Quy tắc nghiệp vụ đã chốt

1. Mở bàn tạo một **lượt sử dụng bàn**. Mỗi lượt có thể có nhiều đơn đã thanh toán và tối đa một đơn đang mở hoặc chờ thanh toán.
2. Nhân viên được thêm món. Món đã xác nhận ghi có giá lưu tại thời điểm bán. Khi cần hủy món đã ghi, nhân viên gửi lý do để quản lý duyệt và lưu lịch sử. Giỏ tạm trước khi xác nhận có thể sửa.
3. VietQR động gắn số tiền và mã tham chiếu riêng. Khi tổng đơn tăng, POS ngừng hiển thị QR cũ, giữ mã tham chiếu để đối soát và sinh QR mới theo **số còn phải thu**. Ghi nhận mọi giao dịch đã xác minh một lần, kể cả đến muộn. Khoản thu dư vào **Cần đối soát**.
4. Nhận đủ tiền đã xác minh thì **đơn** chuyển **Đã thanh toán**. Bàn vẫn **Đang có khách**. Nếu nhóm gọi thêm sau thanh toán, mở đơn mới trong cùng lượt, có QR riêng và xem được cả các đơn đã trả.
5. Nhân viên bấm **Trả bàn** khi nhóm rời đi và các đơn trong lượt đã được xử lý. Trang chi tiết đơn đã thanh toán là đủ cho giai đoạn chưa triển khai máy in.

## PostgreSQL và đăng nhập

- Máy đã có PostgreSQL 18 và pgAdmin. Kết nối trước đây đã xác minh tại `127.0.0.1:1024`, database `cafe_pos`, schema `pos`. Tài khoản kết nối PostgreSQL đã kiểm tra là `postgres`. Tài khoản POS `pinvutru` là bản ghi ứng dụng đang hoạt động với vai trò `Manager`.
- Bảng và cột dùng tiếng Việt không dấu, viết liền hoa chữ đầu, như `NguoiDung`, `HoSoNguoiDung`, `VaiTro`, `LuotBan`, `DonHang`, `DongMon` và `MatKhauBam`. SQL PostgreSQL cần đặt tên PascalCase trong dấu ngoặc kép. Ưu tiên SQL gọn cho dự án mới. Khi làm tiếp trên database đã có, kiểm tra schema trước khi sửa.
- SQL đợt 1 đã được chạy trong pgAdmin. Bản SQL của phiên cũ ở `C:\Users\littl\Documents\Codex\2026-11-13\t-m-t-t-t-ng\outputs\01-pos-schema.sql`. Dùng để đối chiếu cấu trúc, vì database và code có thể đã thay đổi sau đó.
- Đăng nhập bằng ASP.NET Core Identity và cookie phiên. Ghi nhớ đăng nhập là lựa chọn trên thiết bị. Dùng HTTPS, cookie bảo mật, cơ chế chống CSRF cho thao tác ghi cần bảo vệ và kiểm tra vai trò ở server. Cấu hình kết nối cục bộ qua .NET User Secrets hoặc `ConnectionStrings__DefaultConnection`. Thông tin xác thực nằm ngoài gói bàn giao.

## Trạng thái triển khai

- **Đã xác minh ở phiên trước.** Bản đăng nhập preview hiển thị tiếng Việt, bắt buộc nhập đủ hai trường và bật/tắt ẩn mật khẩu. Backend ba lớp build thành công. Với PostgreSQL thử nghiệm, `/api/health` trả `200`, `/api/auth/me` trả `401` khi chưa có phiên. Kiểm thử Flutter bản preview khi đó phát hiện hai lỗi tràn ngang. Kết nối tới database chính và vai trò Manager đã xác minh bằng truy vấn đọc, riêng với kiểm thử backend nói trên.
- **Đã thấy trong mã ngày 25/11.** Flutter có `tinh_nang/xac_thuc` gọi API, khôi phục phiên và điều hướng theo vai trò, cùng khung `tinh_nang/quan_ly/giao_dien/khung_quan_ly.dart`. Backend có các endpoint auth, tổng quan quản lý và thao tác mở bàn/ghi món, yêu cầu QR, xác nhận đã trả, trả bàn. Project API có `UserSecretsId` và nạp biến môi trường. Mã có một số màn quản lý còn ghi rõ trạng thái chưa tích hợp.
- **Cần kiểm tra trên bản hiện tại.** Chạy build và test lại. Nối chính xác `cafe_pos` qua cấu hình cục bộ rồi thử đăng nhập thật trên HTTPS, ghi nhớ/khôi phục phiên, đăng xuất, lỗi đăng nhập và chặn tài khoản không có quyền vào Manager. Kiểm tra layout điện thoại và kiểm lại hai lỗi tràn ngang. Xác minh nghiệp vụ mở bàn, ghi món, thanh toán và trả bàn trên dữ liệu thử nghiệm trước khi bổ sung tính năng.
- Cấu hình launch backend hiện dùng `https://localhost:7179` và `http://localhost:5180`. Flutter có tham số `POS_API_BASE_URL` và mặc định trỏ `https://localhost:7179` khi chạy tách cổng. Bản xem giao diện qua LAN từng ở `http://192.168.1.10:5179/`. Địa chỉ và tiến trình có thể thay đổi. Dùng HTTPS để thử đăng nhập thật.

## Phần phát triển sau POS và xác thực

- **VietQR và đối soát.** Tích hợp webhook xác minh giao dịch hoặc service mô phỏng. Kiểm tra xử lý trùng, đến muộn, trả thiếu, trả dư, và tách trạng thái bàn khỏi trạng thái đơn. Trong mã đã có endpoint xác nhận đã trả, cần kiểm tra nó thực hiện luồng nào trước khi coi là tích hợp webhook.
- **Báo cáo và dự báo.** Chuẩn hóa quy tắc doanh thu, lợi nhuận và món bán chạy ở backend để dashboard và AI đọc cùng một nguồn. Tự huấn luyện mô hình dự báo trên lịch sử hoặc dữ liệu giả lập có chu kỳ. So sánh với dự báo cơ sở theo thời gian. Gợi ý nhập hàng cần dự báo theo món, định mức và tồn kho.
- **Trợ lý AI tiếng Việt.** Dùng mô hình open-weights chạy cục bộ, kế hoạch QLoRA trên Colab T4 với khoảng 500–1.500 mẫu tiếng Việt, rồi xuất qua Ollama hoặc vLLM. Tool calling lấy số liệu qua API, hỏi lại khi thiếu thông tin và từ chối yêu cầu ngoài khả năng. Lệnh thay đổi dữ liệu tạo mini-form có `values` và `field_meta`, cho quản lý sửa và xác nhận. Backend chỉ ghi sau khi kiểm tra quyền, dữ liệu và ràng buộc.

## Tin nhắn để mở phiên mới

> Hãy đọc tệp bàn giao và thư mục Docs của dự án Quản Lý Quán Cà Phê. Tiếp tục từ mã hiện có trong Backend và PosClient, giữ mô hình ASP.NET Core 3 lớp, Flutter Web và PostgreSQL cafe_pos. Trước hết xác minh bản Antigravity bằng cách build/test rồi chạy luồng đăng nhập thật và giao diện Manager trên HTTPS. Dùng secret cục bộ, giữ nguyên dữ liệu hiện có và thử các thao tác ghi trên dữ liệu riêng. Phân biệt phần đã chạy thật với phần mới thấy trong mã. Giữ các quyết định về quyền theo ca, lượt bàn, VietQR, in bill và AI trong bản bàn giao.

