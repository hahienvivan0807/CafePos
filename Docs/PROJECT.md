# POS quán cà phê · Sổ tay dự án

Dự án cá nhân cho portfolio Software/AI Engineer. POS phục vụ tại bàn, Flutter Web trước và app sau, ASP.NET Core Web API và PostgreSQL. Hiện đang đặc tả tính năng. Trang theo dõi local là công cụ riêng gồm sổ tay, danh mục tính năng, bảng tiến độ và mô phỏng.

## Vai trò

- **Nhân viên** chấm công vào/ra ca, xem lịch làm việc cá nhân/chung, xem sơ đồ bàn, mở bàn, tạo đơn, ghi món, yêu cầu hủy món, hiển thị VietQR, xem đơn đã trả và trả bàn.
- **Quản lý** quản lý menu và giá, quản lý nhân viên & phân ca, duyệt hoặc từ chối hủy món, đối soát, xem báo cáo và dự báo, dùng trợ lý AI.
- Khách gọi món với nhân viên và quét VietQR bằng app ngân hàng. QR dùng để thanh toán.

## Không gian Nhân viên & Quy tắc Chấm công

- **Chấm công 3 lớp (Định vị + Wi-Fi quán + Face ID):** Thẻ **Chấm công** trên Trang chủ Nhân viên dùng để mở ca / kết thúc ca (`pos."CaLamViec"`), với thiết kế xác thực kết hợp **Định vị GPS (Geofencing tại quán)**, **Wi-Fi nội bộ quán** và **Face ID (Camera)** nhằm chống chấm công hộ.
- **Khóa bảo vệ Sơ đồ bàn khi chưa trong ca:** Khi nhân viên **chưa bắt đầu ca làm việc**, nếu bấm vào mục **Dịch vụ tại bàn (Sơ đồ bàn)** thì hệ thống hiển thị **màn hình trạng thái trống / khóa bảo vệ**, nhắc nhân viên quay lại **Chấm công vào ca** trước khi mở bàn hoặc ghi món.
- **Kỳ lương hiện tại:** Giữ trạng thái **trống dữ liệu** (không hiển thị số giả / tháng cố định), sẽ đồng bộ sau khi hoàn thiện nghiệp vụ tính công & đơn giá lương.

## Luồng POS

1. Mở bàn tạo một lượt sử dụng. Mỗi lượt có nhiều đơn đã thanh toán và tối đa một đơn đang mở hoặc chờ thanh toán.
2. Giỏ tạm sửa được. Món đã ghi lưu giá lúc bán. Muốn hủy, nhân viên gửi lý do và quản lý duyệt. Lưu dòng gốc và lịch sử.
3. Khi chốt thanh toán, tạo VietQR theo số còn phải thu và mã tham chiếu riêng. Bản demo dùng webhook giả lập. Backend thực tế xác thực nguồn báo giao dịch và kiểm tra thông tin nhận tiền. Cùng mã giao dịch chỉ ghi nhận một lần.
4. Thu đủ thì đơn **Đã thanh toán**. Bàn vẫn **Đang có khách**. Nhân viên **Trả bàn** khi nhóm rời đi và mọi đơn trong lượt đã xử lý.
5. B07 đã trả đơn A và vẫn có khách. Khi gọi thêm một ly 25.000đ sau thanh toán, tạo đơn B trong cùng lượt với QR riêng. Màn hình bàn hiện cả hai đơn.
6. Nếu đang chờ QR mà tổng đơn tăng từ 65.000đ lên 90.000đ, ngừng hiện QR cũ và giữ mã tham chiếu. QR mới là 90.000đ nếu chưa nhận tiền, hoặc 25.000đ nếu xác minh đã nhận 65.000đ. Nếu nhận cả hai khoản 65.000đ và 90.000đ, lưu hai giao dịch và đưa 65.000đ thu dư vào **Cần đối soát**.

Bản đầu có chi tiết đơn đã thanh toán. In bill vật lý và tự in đang để ngỏ.

## Báo cáo, dự báo và AI

- C# và PostgreSQL chuẩn hóa doanh thu, lợi nhuận và món bán chạy để dashboard và trợ lý dùng chung. Chốt quy tắc hoàn tiền và giá vốn khi đặc tả báo cáo.
- Tự huấn luyện XGBoost, LightGBM hoặc Prophet bằng dữ liệu lịch sử hoặc dữ liệu giả lập có chu kỳ. Đánh giá theo thời gian và so với cùng thứ tuần trước. Gợi ý nhập hàng dựa trên dự báo số ly theo món, định mức và tồn kho.
- Trợ lý tiếng Việt chạy local bằng model open-weights như Qwen 2.5 3B/7B. Dùng model gốc trước, rồi fine-tune QLoRA bằng Unsloth trên Colab T4 với khoảng 500–1.500 mẫu tiếng Việt, xuất chạy qua Ollama hoặc vLLM. So sánh với model gốc trên tập giữ riêng về chọn công cụ, điền tham số và xử lý yêu cầu ngoài phạm vi.
- **Tool Calling.** Model chọn công cụ và trích tham số. C# kiểm tra quyền và gọi API báo cáo hoặc dự báo lấy số liệu thật. Thiếu thông tin thì hỏi lại, ngoài phạm vi thì từ chối an toàn.
- **Mini-Form xác nhận.** Với yêu cầu “Thứ Bảy giảm bạc xỉu 10%”, backend tra món thật, trả JSON gồm values và field_meta. Flutter dựng form chỉnh sửa. Chỉ khi quản lý bấm Xác nhận, backend kiểm tra lại quyền và ràng buộc rồi ghi dữ liệu.

## Làm tiếp

Đặc tả màn hình **Chi tiết lượt sử dụng bàn** qua bốn thời điểm của B07 gồm đơn A đang mở, A chờ thanh toán, A đã trả khi khách còn ngồi và đơn B được tạo. Ghi rõ dữ liệu hiển thị, nút thao tác và điều kiện. Sau đó đặc tả yêu cầu–duyệt hủy món và đối soát QR cũ.
