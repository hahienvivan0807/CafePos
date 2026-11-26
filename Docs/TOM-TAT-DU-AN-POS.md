# Sổ tay theo dõi dự án POS quán cà phê

## Mục đích

Một trang cá nhân để xem dự án quán cà phê cần những màn hình và tính năng nào, rồi đánh dấu từng việc khi làm xong. Khi mở lại trang, người làm dự án thấy ngay phần đã hoàn thành và phần còn lại.

## Trải nghiệm trang theo dõi

- Dashboard sáng với tông kem yến mạch, tím mận và điểm nhấn cam đất. Thẻ có độ nổi nhẹ, nhấc lên khi rê chuột và phản hồi nhẹ khi bấm.
- Ba tab **Nhân viên**, **Quản lý** và **Backend**. Hai tab đầu liệt kê giao diện cần làm cho từng vai trò. Tab Backend liệt kê các nghiệp vụ hệ thống cần xử lý.
- Mỗi thẻ có tên, mô tả ngắn và ô đánh dấu. Bấm vào tên để xem chi tiết và tiêu chí hoàn thành. Bấm ô một lần để hoàn thành, bấm lại để bỏ đánh dấu. Tiến độ được lưu để lần mở sau tiếp tục.
- Có tìm kiếm, lọc **Tất cả**, **Chưa hoàn thành**, **Đã hoàn thành**, và bộ đếm tiến độ theo nhóm.
- Panel **Tóm tắt dự án** có thể thu gọn để dành chỗ cho danh sách. Mở lại từ đầu trang.
- Mở trang bằng nhấp đúp lối tắt trên Desktop.

## Ý tưởng POS

POS phục vụ tại bàn cho quán cà phê. Nhân viên ghi món và hỗ trợ thanh toán. Quản lý kiểm soát menu, hủy món, đối soát tiền và theo dõi hoạt động quán. Khách gọi món trực tiếp với nhân viên và quét QR để thanh toán.

| Nhóm | Những mục cần làm |
|---|---|
| **Nhân viên** | Sơ đồ bàn, chi tiết lượt sử dụng bàn, ghi món, yêu cầu hủy món, màn hình thanh toán, chi tiết đơn đã trả và thao tác trả bàn. |
| **Quản lý** | Quản lý menu và giá, duyệt hoặc từ chối hủy món, đối soát giao dịch, báo cáo, dự báo và trợ lý tiếng Việt. |
| **Backend** | Phân quyền, quản lý bàn và lượt sử dụng, lưu giá lúc bán, ghi lịch sử hủy món, tạo QR theo số còn phải thu, ghi nhận và đối soát thanh toán, tổng hợp báo cáo, cung cấp dự báo và xử lý yêu cầu của trợ lý. |

## Quy tắc nghiệp vụ đã chốt

1. **Mở bàn** bắt đầu một lượt sử dụng. Trong một lượt có thể có nhiều đơn đã thanh toán và tối đa một đơn đang mở hoặc chờ thanh toán.
2. Nhân viên sửa được giỏ tạm. Món đã ghi chỉ hủy sau khi quản lý duyệt yêu cầu có lý do. Hệ thống giữ dòng món gốc và lịch sử xử lý.
3. Khi xác nhận đủ tiền, đơn chuyển sang **Đã thanh toán**. Bàn vẫn **Đang có khách**. Nhân viên **Trả bàn** khi khách rời đi và các đơn trong lượt đã được xử lý.
4. Nếu nhóm đã thanh toán mà vẫn ngồi và gọi thêm một ly 25.000đ, nhân viên tạo đơn mới trong cùng lượt. Đơn mới có QR riêng. Màn hình bàn hiển thị cả đơn cũ và đơn mới.
5. Nếu khách gọi thêm khi đang chờ thanh toán, ví dụ tổng đơn tăng từ 65.000đ lên 90.000đ, ngừng hiển thị QR cũ và giữ mã tham chiếu để đối soát khoản đến muộn. QR mới là 90.000đ nếu chưa nhận tiền hoặc 25.000đ nếu đã xác minh nhận 65.000đ. Nếu nhận cả hai khoản 65.000đ và 90.000đ, ghi nhận cả hai giao dịch và đưa 65.000đ thu dư vào **Cần đối soát**. Cùng một giao dịch chỉ được ghi nhận một lần.
6. Có màn hình xem chi tiết đơn đã thanh toán. **In bill vật lý đang để ngỏ.**

## Báo cáo, dự báo và trợ lý

- Báo cáo cho quản lý xem doanh thu, số đơn đã thanh toán và món bán chạy. Trợ lý dùng cùng nguồn số liệu để trả lời câu hỏi tiếng Việt.
- Dự báo doanh thu dựa trên lịch sử bán hàng. Gợi ý nhập nguyên liệu khi có dữ liệu về số lượng món dự kiến bán, định mức pha chế và tồn kho.
- Với yêu cầu thay đổi như “Thứ Bảy giảm bạc xỉu 10%”, trợ lý chuẩn bị bản nháp để quản lý xem và chỉnh sửa. Thay đổi chỉ được áp dụng sau khi quản lý xác nhận.

## Việc tiếp theo

Đặc tả màn hình **Chi tiết lượt sử dụng bàn** qua ca B07. Mô tả dữ liệu và nút thao tác ở bốn thời điểm gồm đơn A đang mở, đơn A chờ thanh toán, đơn A đã trả khi khách còn ngồi và đơn B được tạo trong cùng lượt.
