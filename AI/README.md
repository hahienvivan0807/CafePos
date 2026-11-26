# AI Workspace · PinVuTru Cafe POS

Thư mục này chứa mã nguồn, schema, dữ liệu huấn luyện, notebook Colab và bộ công cụ đánh giá cho 2 nhánh AI tự huấn luyện của dự án (xem chi tiết tại [Docs/QUY-TRINH-AI-VA-DANH-GIA.md](../Docs/QUY-TRINH-AI-VA-DANH-GIA.md)).

## Cấu trúc thư mục

- `schemas/` — Hợp đồng Tool Calling chuẩn (`tool_schemas.json`) dùng chung cho C# Backend và Python training/eval.
- `data/raw/` — Dữ liệu gốc xuất từ PostgreSQL (19 món nước, 4 khung ca, lịch sử đơn hàng).
- `data/processed/` — Dataset tiếng Việt đã làm sạch (`train_tool_calling.jsonl`, `val.jsonl`).
- `eval/` — Tập kiểm thử giữ riêng (`holdout_test.jsonl`), script chấm điểm tự động (`run_benchmark.py`) và thư mục `results/` lưu bảng kết quả & Confusion Matrix.
- `notebooks/` — Notebook chạy trên Google Colab Pro A100 (`train_qwen_lora_a100.ipynb`, `train_forecast_lgbm.ipynb`).
- `modelfiles/` — Cấu hình `Modelfile` để nạp file `.gguf` tự train vào Ollama trên ổ `D:\`.
- `scripts/` — Script Python sinh dữ liệu, kiểm tra chất lượng dataset và chuyển đổi định dạng.

> **Lưu ý:** Trọng số model nặng (`.gguf`, `.onnx`, `.safetensors`, `.bin`, `.pt`) **không lưu trong Git** mà được lưu cố định tại `D:\AI_Models\`.
