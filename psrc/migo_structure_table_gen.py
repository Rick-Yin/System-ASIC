#!/usr/bin/env python3
"""Build MIGO structure-validation summary CSV from test logs."""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path


LINE_RE = re.compile(
    r"\[MIGO-STRUCT\]\[(PASS|FAIL)\]\s+item=([A-Za-z0-9_]+)\s+cases=(\d+)\s+mismatches=(\d+)"
)

ITEM_META = {
    "const_coeff_mac": "常数系数乘加路径",
    "round_shift": "末级舍入与右移输出",
}


def parse_log(path: Path) -> tuple[str, str, int, int]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    for line in text.splitlines():
        match = LINE_RE.search(line)
        if match:
            return match.group(1), match.group(2), int(match.group(3)), int(match.group(4))
    raise RuntimeError(f"no MIGO structure summary found in {path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Summarize MIGO structure-validation logs.")
    parser.add_argument("--log-dir", type=Path, required=True, help="Log directory.")
    parser.add_argument("--output-csv", type=Path, required=True, help="Summary CSV path.")
    args = parser.parse_args()

    rows = []
    total_cases = 0
    total_mismatches = 0

    for item in ("const_coeff_mac", "round_shift"):
        log_path = args.log_dir / f"tb_migo_{item}.log"
        status, parsed_item, cases, mismatches = parse_log(log_path)
        if parsed_item != item:
            raise RuntimeError(f"log item mismatch: expected {item}, got {parsed_item} in {log_path}")
        correct = cases - mismatches
        rows.append(
            {
                "Item": ITEM_META[item],
                "Correct": correct,
                "Total": cases,
                "Mismatches": mismatches,
                "Verdict": "Equivalent (bit-exact)" if status == "PASS" and mismatches == 0 else "Check required",
            }
        )
        total_cases += cases
        total_mismatches += mismatches

    args.output_csv.parent.mkdir(parents=True, exist_ok=True)
    with args.output_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["Item", "Correct", "Total", "Mismatches", "Verdict"])
        for row in rows:
            writer.writerow([row["Item"], row["Correct"], row["Total"], row["Mismatches"], row["Verdict"]])
        writer.writerow(
            [
                "TOTAL",
                total_cases - total_mismatches,
                total_cases,
                total_mismatches,
                "Equivalent (bit-exact)" if total_mismatches == 0 else "Check required",
            ]
        )

    print(f"[MIGO-STRUCT][OK] wrote {args.output_csv}")


if __name__ == "__main__":
    main()
