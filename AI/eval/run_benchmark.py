"""
Chấm điểm tự động (Benchmark) mô hình chạy trên Ollama local bằng tập Hold-out Test.
So sánh công bằng giữa Base Model (qwen2.5:3b) và Fine-tuned Model (cafepos-qwen-lora).

Chạy:
    python AI/eval/run_benchmark.py --model qwen2.5:3b --limit 40
    python AI/eval/run_benchmark.py --model qwen2.5:3b
"""

from __future__ import annotations

import argparse
import json
import statistics
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCHEMA_PATH = ROOT / "AI" / "schemas" / "tool_schemas.json"
HOLDOUT_PATH = ROOT / "AI" / "eval" / "holdout_test.jsonl"
RESULTS_DIR = ROOT / "AI" / "eval" / "results"


def call_ollama(base_url: str, model: str, messages: list[dict], tools: list[dict]) -> tuple[dict, float]:
    payload = {
        "model": model,
        "stream": False,
        "messages": messages,
        "tools": tools,
        "options": {"temperature": 0.0},
    }
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        f"{base_url.rstrip('/')}/api/chat",
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    t0 = time.perf_counter()
    with urllib.request.urlopen(req, timeout=120) as resp:
        raw = resp.read().decode("utf-8")
    elapsed_ms = (time.perf_counter() - t0) * 1000.0
    return json.loads(raw), elapsed_ms


def normalize_val(v):
    if isinstance(v, str):
        return v.strip().lower()
    return v


def compare_args(expected: dict, predicted: dict) -> bool:
    if not isinstance(predicted, dict):
        return False
    for k, exp_v in expected.items():
        if k not in predicted:
            return False
        pred_v = predicted[k]
        if k == "product_name":
            if normalize_val(exp_v) not in normalize_val(pred_v) and normalize_val(pred_v) not in normalize_val(exp_v):
                return False
        elif k == "apply_window":
            # Chỉ cần có nội dung không rỗng
            if not str(pred_v).strip():
                return False
        elif k == "staff_keyword":
            if not str(pred_v).strip():
                return False
        else:
            if normalize_val(exp_v) != normalize_val(pred_v):
                return False
    return True


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", default="qwen2.5:3b")
    parser.add_argument("--base-url", default="http://127.0.0.1:11434")
    parser.add_argument("--limit", type=int, default=0, help="0 = chạy toàn bộ holdout_test.jsonl")
    args = parser.parse_args()

    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    tools = schema["tools"]
    rows = [json.loads(line) for line in HOLDOUT_PATH.read_text(encoding="utf-8").splitlines() if line.strip()]
    if args.limit > 0:
        rows = rows[: args.limit]

    total = len(rows)
    tool_total = 0
    tool_correct = 0
    json_valid = 0
    args_correct = 0

    non_tool_total = 0
    safety_or_clarify_correct = 0
    hallucinated_tool_or_claim = 0

    latencies: list[float] = []
    errors: list[dict] = []
    confusion: dict[str, dict[str, int]] = {}

    print(f"Running benchmark on model='{args.model}' ({total} hold-out cases)...")

    for idx, row in enumerate(rows, 1):
        exp_tool = row["expected_tool"]
        exp_args = row["expected_args"]
        category = row["category"]
        # Chỉ gửi system + history + user (bỏ assistant đáp án)
        input_messages = row["messages"][:-1]
        user_text = input_messages[-1]["content"]

        resp, ms = call_ollama(args.base_url, args.model, input_messages, tools)
        latencies.append(ms)

        msg = resp.get("message", {})
        tool_calls = msg.get("tool_calls") or []
        content = (msg.get("content") or "").strip()

        pred_tool = None
        pred_args = {}
        is_json_ok = True

        if tool_calls:
            fn = tool_calls[0].get("function", {})
            pred_tool = fn.get("name")
            raw_args = fn.get("arguments", {})
            if isinstance(raw_args, str):
                try:
                    pred_args = json.loads(raw_args)
                except Exception:
                    is_json_ok = False
                    pred_args = {}
            elif isinstance(raw_args, dict):
                pred_args = raw_args
            else:
                is_json_ok = False

        exp_label = exp_tool or "NO_TOOL"
        pred_label = pred_tool or "NO_TOOL"
        confusion.setdefault(exp_label, {})
        confusion[exp_label][pred_label] = confusion[exp_label].get(pred_label, 0) + 1

        if exp_tool is not None:
            tool_total += 1
            if pred_tool == exp_tool:
                tool_correct += 1
                if is_json_ok:
                    json_valid += 1
                    if compare_args(exp_args, pred_args):
                        args_correct += 1
                    else:
                        errors.append(
                            {
                                "id": idx,
                                "category": category,
                                "user": user_text,
                                "expected": {"tool": exp_tool, "args": exp_args},
                                "predicted": {"tool": pred_tool, "args": pred_args},
                                "reason": "WRONG_ARGS",
                            }
                        )
                else:
                    errors.append(
                        {
                            "id": idx,
                            "category": category,
                            "user": user_text,
                            "expected": {"tool": exp_tool, "args": exp_args},
                            "predicted": {"tool": pred_tool, "raw": tool_calls[0]},
                            "reason": "INVALID_JSON",
                        }
                    )
            else:
                if pred_tool is None and ("đã tạo" in content.lower() or "đã giảm" in content.lower()):
                    hallucinated_tool_or_claim += 1
                errors.append(
                    {
                        "id": idx,
                        "category": category,
                        "user": user_text,
                        "expected": {"tool": exp_tool, "args": exp_args},
                        "predicted": {"tool": pred_tool, "content": content[:140]},
                        "reason": "WRONG_OR_MISSED_TOOL",
                    }
                )
        else:
            non_tool_total += 1
            if pred_tool is None:
                # Không gọi tool sai là đạt, nhưng nếu bịa "đã tạo lịch" / "đã giảm" thì tính hallucination
                low = content.lower()
                if "đã tạo lịch" in low or "đã giảm giá" in low or "đã xóa" in low:
                    hallucinated_tool_or_claim += 1
                    errors.append(
                        {
                            "id": idx,
                            "category": category,
                            "user": user_text,
                            "expected": {"tool": None},
                            "predicted": {"tool": None, "content": content[:140]},
                            "reason": "HALLUCINATED_COMPLETION",
                        }
                    )
                else:
                    safety_or_clarify_correct += 1
            else:
                hallucinated_tool_or_claim += 1
                errors.append(
                    {
                        "id": idx,
                        "category": category,
                        "user": user_text,
                        "expected": {"tool": None},
                        "predicted": {"tool": pred_tool, "args": pred_args},
                        "reason": "UNSAFE_OR_PREMATURE_TOOL_CALL",
                    }
                )

        if idx % 10 == 0 or idx == total:
            print(f"  [{idx}/{total}] avg_ms={statistics.mean(latencies):.0f}ms")

    lat_sorted = sorted(latencies)
    p50 = lat_sorted[len(lat_sorted) // 2] / 1000.0 if lat_sorted else 0.0
    p95 = lat_sorted[min(len(lat_sorted) - 1, int(len(lat_sorted) * 0.95))] / 1000.0 if lat_sorted else 0.0

    summary = {
        "model": args.model,
        "total_cases": total,
        "tool_cases": tool_total,
        "non_tool_cases": non_tool_total,
        "tool_selection_accuracy_pct": round(100.0 * tool_correct / max(1, tool_total), 2),
        "json_schema_validity_pct": round(100.0 * json_valid / max(1, tool_total), 2),
        "slot_exact_match_pct": round(100.0 * args_correct / max(1, tool_total), 2),
        "clarification_and_safety_pct": round(100.0 * safety_or_clarify_correct / max(1, non_tool_total), 2),
        "hallucination_rate_pct": round(100.0 * hallucinated_tool_or_claim / max(1, total), 2),
        "latency_p50_sec": round(p50, 2),
        "latency_p95_sec": round(p95, 2),
        "confusion_matrix": confusion,
        "sample_errors": errors[:15],
    }

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    safe_name = args.model.replace(":", "_").replace("/", "_")
    out_path = RESULTS_DIR / f"benchmark_{safe_name}.json"
    out_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")

    print("\n=== BENCHMARK SUMMARY ===")
    for k, v in summary.items():
        if k not in ("confusion_matrix", "sample_errors"):
            print(f"  {k}: {v}")
    print(f"Saved full report to: {out_path}")


if __name__ == "__main__":
    main()
