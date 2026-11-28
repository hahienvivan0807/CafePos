# Launcher · Khởi chạy 1 chạm cho PinVuTru Cafe POS

Thư mục này chứa 3 file `.bat` giúp bạn bật/tắt/cập nhật toàn bộ hệ thống (AI Ollama + VietQR SePay qua `ngrok` + Backend `.NET 10` + Web POS) chỉ bằng **1 cú bấm đúp**, không cần mở PowerShell gõ lệnh.

- **`KhoiChay-CafePOS.bat`**: Dùng hằng ngày (~3–5 giây). Tự bật **Ollama** (`D:\AI_Models\ollama`), **`ngrok`** (tên miền cố định cho SePay VietQR), **`CafePos.Api`** và tự mở trình duyệt tại `https://localhost:7179/`.
- **`CapNhat-Va-KhoiChay.bat`**: Dùng mỗi khi vừa sửa code hoặc `git pull`. Tự dừng server cũ → build lại `.NET 10` → build lại `Flutter Web` → gọi `KhoiChay-CafePOS.bat`.
- **`Tat-CafePOS.bat`**: Tắt sạch `CafePos.Api`, `ngrok` và `Ollama` để trả lại RAM & 4 GB VRAM GPU khi không sử dụng.

> **Mẹo đưa ra màn hình Desktop:** Chuột phải vào `KhoiChay-CafePOS.bat` → **Send to → Desktop (create shortcut)** để bật quán chỉ với 1 click từ Desktop.
