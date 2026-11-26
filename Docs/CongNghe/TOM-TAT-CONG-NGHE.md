# Công nghệ dự án Quản lý quán cà phê

## Stack POS

| Công nghệ | Chức năng |
|---|---|
| **Flutter Web và Dart** | Giao diện POS trong `PosClient`. Nhân viên mở bàn, ghi món, thanh toán và trả bàn. Quản lý xem báo cáo, quản lý menu, duyệt hủy món và đối soát. Web là mục tiêu đầu tiên, app triển khai sau. |
| **C# và ASP.NET Core Web API trên .NET 10** | Cung cấp API cho giao diện và xử lý nghiệp vụ POS. |
| **EF Core và Npgsql** | Ánh xạ dữ liệu từ C# sang PostgreSQL và thực hiện giao dịch. Quy ước schema dùng tên tiếng Việt không dấu theo PascalCase, như `NguoiDung`, `HoSoNguoiDung` và `DonHang`. |
| **PostgreSQL** | Lưu tài khoản, hồ sơ, vai trò, menu, bàn, lượt sử dụng, đơn hàng và yêu cầu hủy món. Những đợt sau bổ sung giao dịch thanh toán và đối soát. |

## Backend 3 lớp

| Project | Trách nhiệm |
|---|---|
| **`CafePos.Api`** | Nhận request HTTP, trả response, cấp hoặc xóa cookie và áp dụng kiểm tra quyền tại API. |
| **`CafePos.Application`** | Tổ chức các ca sử dụng và quy tắc nghiệp vụ. Ví dụ một người chỉ có tối đa một ca làm đang mở. |
| **`CafePos.Infrastructure`** | Tích hợp EF Core, Npgsql và ASP.NET Core Identity. Triển khai truy cập dữ liệu và transaction. |

Ba project C# tạo thành một backend. Luồng chạy là **Flutter Web → ASP.NET Core → PostgreSQL**.

## Đăng nhập và ca làm việc

| Công nghệ | Chức năng |
|---|---|
| **ASP.NET Core Identity** | Xác minh mật khẩu băm, đếm lần đăng nhập sai và hỗ trợ khóa tạm. Tài khoản, thông tin hồ sơ và vai trò được lưu trong các bảng liên kết. |
| **Cookie Authentication và HTTPS** | Cho phép giữ phiên trình duyệt và ghi nhớ đăng nhập khi người dùng chọn. Backend hiện cấu hình cookie `HttpOnly`, `Secure`, `SameSite=Lax` và thời hạn 7 ngày với cơ chế gia hạn theo hoạt động. |
| **ASP.NET Core Authorization** | Kiểm tra vai trò `Staff` hoặc `Manager` ở API. |
| **ASP.NET Core Antiforgery** | Dùng mã chống CSRF cho các thao tác thay đổi dữ liệu khi xác thực bằng cookie. |
| **PostgreSQL và bảng `CaLamViec`** | Lưu giờ bắt đầu và kết thúc ca. Giao diện gọi `GET /api/auth/me` để khôi phục thông tin phiên và xác định ca đang mở. |

Xem luồng chi tiết tại [Thiết kế đăng nhập](../THIET-KE-LUONG-DANG-NHAP.md).

## Công nghệ dự kiến ở các đợt sau

| Công nghệ | Chức năng |
|---|---|
| **VietQR và webhook** | Sinh QR theo số tiền còn phải thu. Bản demo dùng webhook giả lập để thử ghi nhận, chống trùng và đối soát giao dịch. Luồng tiền mặt ghi nhận xác nhận của nhân viên. |
| **C# và PostgreSQL cho báo cáo** | Cung cấp cùng nguồn số liệu cho dashboard và trợ lý, gồm doanh thu, đơn đã thanh toán và món bán chạy. |
| **Python và mô hình dự báo** | Huấn luyện mô hình trên dữ liệu bán hàng. Các ứng viên gồm XGBoost, LightGBM và Prophet. |
| **Qwen, QLoRA và Unsloth** | Làm trợ lý tiếng Việt với mô hình gốc trước, sau đó fine-tune và so sánh trên tập kiểm thử giữ riêng. Ollama và vLLM là hai phương án chạy local đang cân nhắc. |
| **Tool Calling và Mini-Form** | Trợ lý lấy số liệu qua API. Khi đề xuất thay đổi như tạo khuyến mãi, Flutter hiển thị bản nháp để quản lý xem, sửa và xác nhận trước khi backend lưu. |

## Web theo dõi dự án cá nhân

`WebService` theo dõi checklist phát triển bằng **ASP.NET Core Razor Pages, EF Core và SQL Server**. Dùng **SSMS** để xem và quản lý dữ liệu checklist. POS vận hành quán dùng PostgreSQL.

Xem phạm vi nghiệp vụ tại [Sổ tay dự án](../PROJECT.md).
