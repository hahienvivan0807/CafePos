# POS quán cà phê · Sổ tay dự án

## Mục tiêu

Xây POS phục vụ tại bàn cho dự án cá nhân và portfolio Software/AI Engineer. Sản phẩm đi theo hướng Flutter Web trước, app sau, với ASP.NET Core Web API và PostgreSQL. Hiện tại đang đặc tả tính năng và mô phỏng giao diện. Tiến độ triển khai sản phẩm chưa được ghi nhận.

Trang theo dõi local là công cụ riêng để đọc sổ tay, xem mô phỏng nghiệp vụ và lưu tiến độ.

## Vai trò và màn hình

| Vai trò | Màn hình và tác vụ |
|---|---|
| Nhân viên | Sơ đồ bàn, chi tiết lượt sử dụng, giỏ tạm, ghi món, yêu cầu hủy món, hiển thị VietQR, xem chi tiết đơn đã trả và trả bàn. |
| Quản lý | Quản lý menu và giá, duyệt hoặc từ chối hủy món, đối soát giao dịch, xem báo cáo, dự báo và dùng trợ lý AI. |

Khách gọi món với nhân viên và quét VietQR bằng app ngân hàng. Hai vai trò sử dụng POS là nhân viên và quản lý. QR trong MVP phục vụ thanh toán.

## Bàn, đơn và thanh toán

1. **Mở bàn** tạo một lượt sử dụng. Bàn hiển thị **Trống** hoặc **Đang có khách**. Một lượt có thể có nhiều đơn đã thanh toán và tối đa một đơn đang mở hoặc chờ thanh toán.
2. **Ghi món** lưu món, số lượng, đơn giá tại thời điểm bán, người ghi và thời điểm. Nhân viên sửa được giỏ tạm. Với món đã ghi, nhân viên gửi yêu cầu hủy kèm lý do. Quản lý duyệt hoặc từ chối. Lưu dòng gốc và lịch sử xử lý.
3. **Tạo VietQR** khi khách yêu cầu thanh toán. QR dùng tài khoản nhận cố định và số tiền còn phải thu, với mã tham chiếu riêng cho mỗi lần phát hành. Bản demo dùng webhook giả lập. Backend thực tế xác thực nguồn thông báo và đối soát giao dịch. Webhook gửi lặp chỉ ghi nhận một lần cho cùng giao dịch.
4. **Đủ tiền** thì đơn chuyển sang **Đã thanh toán**. Bàn vẫn **Đang có khách**. Màn hình bàn hiển thị các đơn của lượt và món thuộc từng đơn.
5. **Trả bàn** khi nhóm rời đi và các đơn trong lượt đã được xử lý. Nhân viên bấm nút để kết thúc lượt và đưa bàn về **Trống**.

### Ca B07 · Hai đơn trong một lượt

Đơn A đã thanh toán, nhóm vẫn ngồi. Người thứ năm gọi một ly 25.000đ. Nhân viên tạo đơn B ở cùng lượt B07. Đơn B có QR riêng 25.000đ. Màn hình hiển thị đơn A đã trả và đơn B đang xử lý. Thanh toán xong đơn B, nhân viên trả bàn khi nhóm rời đi.

### Ca gọi thêm khi đang chờ QR

Đơn tăng từ 65.000đ lên 90.000đ. POS ngừng hiển thị QR 65.000đ, giữ mã tham chiếu để nhận diện giao dịch đến muộn.

| Tình huống | Kết quả |
|---|---|
| Chưa ghi nhận tiền | QR mới 90.000đ. |
| Đã xác minh và ghi nhận 65.000đ | QR mới 25.000đ. Nếu QR 90.000đ đã hiển thị, ngừng hiển thị và giữ tham chiếu. |
| Đã nhận cả 65.000đ và 90.000đ | Lưu hai giao dịch. Đơn thu đủ 90.000đ, 65.000đ thu dư vào **Cần đối soát**. |

### Bill

Bản đầu mô tả màn hình chi tiết đơn đã thanh toán. Thiết bị, in giấy và tự in đang để ngỏ.

## Báo cáo và mô hình dự báo tự huấn luyện

- C# và PostgreSQL dùng chung định nghĩa doanh thu, lợi nhuận và món bán chạy cho dashboard và trợ lý. Chốt cách tính hoàn tiền và giá vốn khi đặc tả báo cáo.
- Dùng Python tự huấn luyện một mô hình dự báo doanh thu như XGBoost, LightGBM hoặc Prophet trên lịch sử bán hàng hoặc dữ liệu giả lập có tính chu kỳ. Đánh giá theo thời gian và so với mốc cùng thứ tuần trước.
- Đề xuất nhập nguyên liệu dựa trên dự báo số lượng bán theo món, định mức pha chế và tồn kho hiện tại.

## Trợ lý AI tiếng Việt chạy local

### Mô hình và huấn luyện

Dùng mô hình open-weights như Qwen 2.5 3B hoặc 7B. Hoàn thiện luồng với model gốc trước. Sau đó fine-tune QLoRA bằng Unsloth trên Google Colab GPU T4 với khoảng 500–1.500 mẫu tiếng Việt theo nghiệp vụ quán. Xuất mô hình để chạy local qua Ollama hoặc vLLM. Luồng trợ lý không phụ thuộc API mô hình thương mại đóng.

Bộ mẫu bao gồm chọn công cụ, trích tham số, hỏi lại khi thiếu thông tin, từ chối yêu cầu ngoài phạm vi và đề xuất thao tác. Dùng tập kiểm thử giữ riêng để so sánh model gốc và model đã fine-tune về độ chính xác chọn công cụ, điền tham số và xử lý yêu cầu ngoài phạm vi.

### Hỏi số liệu qua Tool Calling

Ví dụ quản lý hỏi **“Hôm qua quán thu bao nhiêu?”**. Model chọn công cụ báo cáo và trích khoảng ngày. C# kiểm tra quyền và tham số, gọi cùng logic báo cáo với dashboard rồi trả kết quả để trợ lý diễn đạt bằng tiếng Việt. Các con số đến từ backend. Với yêu cầu dự báo, trợ lý lấy kết quả mô hình dự báo qua API. Khi thiếu tham số, trợ lý hỏi lại. Nếu yêu cầu nằm ngoài phạm vi công cụ, trợ lý trả lời rằng hệ thống chưa hỗ trợ.

### Thao tác nghiệp vụ với Mini-Form xác nhận

Ví dụ quản lý nói **“Thứ Bảy giảm bạc xỉu 10%”**. Model trích ý định, món, mức giảm và thời gian. C# tra món thật trong PostgreSQL, kiểm tra dữ liệu và chuẩn bị bản nháp JSON gồm hai phần:

- `values` chứa giá trị đề xuất như mã món, mức giảm và thời gian áp dụng.
- `field_meta` mô tả nhãn, kiểu trường, lựa chọn hợp lệ và trường bắt buộc để Flutter render Mini-Form chỉnh sửa được.

Quản lý xem, sửa hoặc hủy bản nháp. Chỉ khi quản lý bấm **Xác nhận**, Flutter mới gửi yêu cầu lưu. C# kiểm tra lại quyền, món, mức giảm và khoảng thời gian trước khi ghi vào PostgreSQL. Đây là luồng Human-in-the-Loop cho thay đổi dữ liệu.

## Làm tiếp

Đặc tả màn hình **Chi tiết lượt sử dụng bàn**. Với ca B07, ghi rõ dữ liệu, nút khả dụng và điều kiện thao tác ở bốn thời điểm gồm đơn A đang mở, A chờ thanh toán, A đã trả khi khách còn ngồi, và đơn B được tạo. Sau đó đặc tả cặp yêu cầu–duyệt hủy món và luồng đối soát QR cũ.

## Trang theo dõi local

Cột trái đọc sổ tay này. Cột phải có mục **Làm tiếp**, nhóm công việc, trạng thái, checklist, ghi chú và liên kết minh chứng. Trạng thái công việc chỉ cập nhật tại bảng tương tác. Các quyết định nghiệp vụ lâu dài lưu trong Markdown.

