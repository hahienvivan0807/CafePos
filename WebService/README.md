# Theo dõi dự án POS quán cà phê

Ứng dụng web local (ASP.NET Core Razor Pages + EF Core + SQL Server) dùng để theo dõi tiến độ các màn hình **Nhân viên**, **Quản lý**, và **Backend** theo sổ tay `PROJECT.md`, lưu trạng thái trực tiếp vào database `CafePosTracker`.

## 1. Cấu hình SQL Server Instance

- Instance đã kiểm tra trên máy: `.\SQLEXPRESS` (`DESKTOP-HBBLO71\SQLEXPRESS`)
- Phương thức xác thực: **Windows Authentication** (`Trusted_Connection=True`)
- Connection string không lưu cứng trong mã nguồn công khai (`appsettings.json`), mà được đặt ngoài mã nguồn qua:
  - File cục bộ `appsettings.Local.json` (đã thêm vào `.gitignore`, và được copy vào thư mục `publish/`)
  - Hoặc `dotnet user-secrets` khi chạy phát triển
  - Hoặc biến môi trường `ConnectionStrings__DefaultConnection`

Ví dụ nội dung `appsettings.Local.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=.\\SQLEXPRESS;Database=CafePosTracker;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=True"
  }
}
```

## 2. Tạo database & Migration

Khi ứng dụng khởi động, `Program.cs` tự động chạy `MigrateAsync()` và seed dữ liệu idempotent từ `TrackerSeeder`.

Nếu muốn tạo/cập nhật thủ công:

- **Bằng EF Core CLI**:
  ```powershell
  dotnet ef database update
  ```
- **Bằng SSMS**:
  1. Mở SSMS và kết nối tới `.\SQLEXPRESS` (Windows Authentication).
  2. Tạo database `CafePosTracker` nếu chưa có:
     ```sql
     IF DB_ID(N'CafePosTracker') IS NULL
         CREATE DATABASE [CafePosTracker];
     GO
     USE [CafePosTracker];
     GO
     ```
  3. Mở và chạy file script đã xuất sẵn: `Database/CafePosTracker_Schema.sql` (chạy lặp lại an toàn, không nhân đôi dữ liệu).

## 3. Xem dữ liệu & kiểm tra trạng thái trong SSMS

Mở **New Query** trên database `CafePosTracker` và chạy câu lệnh sau để kiểm tra trạng thái một công việc (ví dụ `STAFF_TABLE_MAP` hoặc tất cả công việc):

```sql
USE CafePosTracker;
GO

-- Kiểm tra trạng thái một công việc cụ thể
SELECT
    g.Name AS Nhom,
    i.Code,
    i.Title,
    i.IsCompleted,
    i.CompletedAt,
    i.UpdatedAt
FROM dbo.WorkItems i
INNER JOIN dbo.WorkGroups g ON g.Id = i.GroupId
WHERE i.Code = 'STAFF_TABLE_MAP';

-- Hoặc xem toàn bộ danh sách theo thứ tự
SELECT
    g.DisplayOrder AS GroupOrder,
    g.Name AS Nhom,
    i.DisplayOrder AS ItemOrder,
    i.Code,
    i.Title,
    i.IsCompleted,
    i.CompletedAt,
    i.UpdatedAt
FROM dbo.WorkItems i
INNER JOIN dbo.WorkGroups g ON g.Id = i.GroupId
ORDER BY g.DisplayOrder, i.DisplayOrder;
```

## 4. Cách mở ứng dụng hằng ngày

- Nhấp đúp lối tắt **`Theo dõi dự án POS`** trên Desktop.
- Lối tắt tự kiểm tra `http://localhost:5178`: nếu ứng dụng chưa chạy sẽ khởi động bản `publish\CafePosTracker.exe` ở chế độ nền, chờ sẵn sàng rồi mở trình duyệt. Không cần mở IDE hay gõ lệnh.

## 5. Nghiệm thu nhanh

1. Mở ứng dụng qua lối tắt Desktop, tick một mục (ví dụ **Sơ đồ bàn**).
2. Chạy câu `SELECT` ở mục 3 trong SSMS để thấy `IsCompleted = 1` và `CompletedAt` đã được ghi.
3. Đóng tab trình duyệt, mở lại qua lối tắt Desktop và xác nhận dấu tick vẫn còn.
4. Bấm bỏ tick trên web và kiểm tra lại trong SSMS thấy `IsCompleted = 0`, `CompletedAt = NULL`.
5. Để thử lỗi kết nối: tạm dừng service `SQL Server (SQLEXPRESS)` (hoặc đổi sai tên server trong `publish\appsettings.Local.json`), bấm tick trên web -> giao diện giữ nguyên trạng thái cũ và hiện thông báo lỗi kèm nút **Thử lại**.
