# Daylight AI · Báo Cáo Tích Hợp & Kiểm Chứng Số Liệu (`v0.2`)

> **Trạng thái:** Bản cập nhật AI `v0.2` đã kết nối hoàn chỉnh `Flutter Web → ASP.NET Core (.NET 10) → Ollama Local (ổ D) → PostgreSQL` với model tự huấn luyện trên Google Colab (**0đ API Key**). Cần tiếp tục nâng cấp ở bản `v0.3` (bổ sung tool đọc lịch trực & mẫu đối lập).
>
> Xem quy trình kỹ thuật đầy đủ tại [QUY-TRINH-AI-VA-DANH-GIA.md](./QUY-TRINH-AI-VA-DANH-GIA.md).

---

## 1. Kiến trúc & Hạ tầng đã triển khai
- **Mô hình tự huấn luyện**: `cafepos-qwen-lora` (fine-tune LoRA từ `Qwen/Qwen2.5-3B-Instruct` bằng Unsloth trên Google Colab, lượng tử hóa `GGUF Q4_K_M` dung lượng **1,840.5 MB**).
- **Runtime Local (0đ API Key, 0 MB ổ `C:\`)**:
  - Cài đặt Ollama `0.40.18` tại `D:\Tools\Ollama`, kho model cố định tại `OLLAMA_MODELS=D:\AI_Models\ollama`.
  - Chạy **100% trên GPU local** (`NVIDIA Quadro T2000 · 4 GB VRAM`, chiếm ~2.2 GB VRAM).
- **Backend & An toàn nghiệp vụ**:
  - 3 endpoint bảo vệ bởi `ManagerOnly` + chống CSRF: `GET /api/manager/ai-assistant/status`, `POST /api/manager/ai-assistant/chat`, `POST /api/manager/ai-assistant/confirm`.
  - **Human-in-the-loop (Mini-Form)**: Mọi thao tác ghi dữ liệu (giảm giá món, phân công ca) đều hiển thị bản nháp cho Quản lý chỉnh sửa trực tiếp và bấm **Xác nhận** mới ghi xuống PostgreSQL.
- **Bộ 5 công cụ chuẩn (`AI/schemas/tool_schemas.json`)**:
  1. `get_shift_revenue` (Đọc doanh thu 4 ca)
  2. `get_top_products` (Đọc món bán chạy)
  3. `get_weekly_shift_gaps` (Kiểm tra ca thiếu định biên tuần)
  4. `draft_menu_promotion` (Tạo Mini-Form giảm giá món)
  5. `draft_shift_assignment` (Tạo Mini-Form phân công ca)

---

## 2. Số liệu Huấn luyện & Kiểm chứng Độc lập (Đã đo thực tế)

### 2.1. Tập dữ liệu (Tách 0% trùng lặp)
- **Train Set**: `610` mẫu (`AI/data/processed/train_tool_calling.jsonl`)
- **Validation Set**: `79` mẫu (`AI/data/processed/val_tool_calling.jsonl`)
- **Hold-out Test Set (Giữ riêng)**: `98` mẫu (`AI/eval/holdout_test.jsonl` — gồm `75` câu cần gọi tool + `23` câu thiếu tham số / ngoài phạm vi)

### 2.2. Quá trình hội tụ LoRA (`r=16, alpha=32, 3 epochs / 117 steps`)
- `eval_loss` giảm đều từ **`0.01802`** (step 25) → **`0.01291`** (step 50) → **`0.01129`** (step 75) → **`0.01047`** (epoch 3, step 117).
- `train_loss` cuối: **`0.01037`** (cân bằng sát `eval_loss`, không có dấu hiệu overfit).

### 2.3. Bảng so sánh Before vs. After (trên cùng 98 câu Hold-out Test)
Đo tự động bằng `AI/eval/run_benchmark.py` trên GPU local (`NVIDIA Quadro T2000`):

| Chỉ số đánh giá (98 câu Hold-out) | `qwen2.5:3b` Base (Before) | `cafepos-qwen-lora` (After) | Chênh lệch |
|---|---:|---:|---:|
| **Tool Selection Accuracy** *(75 câu)* | 98.67% | **97.33%** | -1.34% |
| **JSON Schema Validity** *(75 câu)* | 98.67% | **97.33%** | -1.34% |
| **Slot / Argument Exact Match** *(75 câu)* | 65.33% | **97.33%** | **+32.00%** |
| **Clarification & Safety Refusal** *(23 câu)* | 34.78% | **91.30%** | **+56.52%** |
| **Hallucination Rate** *(càng thấp càng tốt)* | 15.31% | **2.04%** | **-13.27%** (giảm **7.5×**) |
| **Latency P50 / P95 (local GPU)** | 0.80s / 1.38s | **1.44s / 1.95s** | Đáp ứng mượt (< 2s) |

**Bằng chứng log đầy đủ trong repo:**
- Before: `AI/eval/results/benchmark_qwen2.5_3b.json`
- After: `AI/eval/results/benchmark_cafepos-qwen-lora.json`

---

## 3. Hạn chế phát hiện thực tế & Kế hoạch sửa ở phiên bản `v0.3`
Trong quá trình kiểm thử giao tiếp thực tế trên web, phát hiện lỗi **Over-triggering (gọi nhầm tool ghi cho câu hỏi đọc)**:
- **Ví dụ thực tế**: Quản lý hỏi *"hôm nay ai làm ca trưa"* → `cafepos-qwen-lora` gọi nhầm `draft_shift_assignment` (bung Mini-Form phân công ca) thay vì tra cứu danh sách người đang trực.
- **Nguyên nhân gốc**:
  1. Bộ `v1.0` mới có 5 tool, **chưa có tool đọc lịch trực theo ngày/ca (`get_shift_roster`)**.
  2. Tập train `v0.2` có `170/610` mẫu liên quan *"làm ca..."* đều gắn nhãn `draft_shift_assignment`, thiếu **mẫu đối lập (Contrastive examples)** giữa *Hỏi lịch* và *Xếp lịch*.
- **Hạng mục cần làm ở lần cập nhật tới (`v0.3`)**:
  1. Thêm tool thứ 6 `get_shift_roster(work_date, shift_code)` đọc trực tiếp từ `pos."PhanCaNhanVien"`.
  2. Bổ sung ~150 mẫu đối lập (*"hôm nay ai làm ca trưa?"* vs *"xếp Minh Khang làm ca trưa hôm nay"*) vào `AI/scripts/generate_dataset.py` và `holdout_test.jsonl`.
  3. Retrain `v0.3` trên Colab và bổ sung so sánh Ablation Study với `Qwen 2.5 7B`.
