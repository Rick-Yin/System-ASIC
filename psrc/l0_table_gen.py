#!/usr/bin/env python3
"""Build publication-ready L0 operator-equivalence tables from test logs."""

from __future__ import annotations

import csv
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple


@dataclass(frozen=True)
class L0TableConfig:
    log_dir: Path = Path("vsrc/Joint-CFR-DPD/tb/l0_ops/logs")
    out_csv: Path = Path("report/l0_equivalence_table.csv")
    out_cov_csv: Path = Path("report/l0_equivalence_coverage.csv")
    out_md: Path = Path("report/l0_equivalence_table.md")
    out_tex: Path = Path("report/l0_equivalence_table.tex")


CONFIG = L0TableConfig()

EXPECTED_OPS: List[str] = [
    "sat_signed32",
    "rshift_rne64",
    "div_rne64",
    "requant_pow2_signed",
    "hardsigmoid_int_default",
    "wkv_lut_lookup",
]

OPERATOR_META: Dict[str, Dict[str, str]] = {
    "sat_signed32": {
        "category": "Saturation",
        "function": "Signed clipping",
        "domain": "x:int64; bits:1..32",
        "corners": "Lower/upper clip boundaries; near-boundary +/-1 transitions",
    },
    "rshift_rne64": {
        "category": "Rounding",
        "function": "Arithmetic right-shift with RNE",
        "domain": "x:int64; sh:-8..96",
        "corners": "sh<=0 passthrough; sh>=62; tie-to-even at half LSB",
    },
    "div_rne64": {
        "category": "Rounding",
        "function": "Signed divide with RNE",
        "domain": "x:int64; d:int64",
        "corners": "d=0 handling; sign flips; half-way tie-to-even",
    },
    "requant_pow2_signed": {
        "category": "Quantization",
        "function": "Power-of-two requantization",
        "domain": "x:int64; exp delta:-48..48; bits:2..31",
        "corners": "Large shift saturation; signed overflow guard; tie rounding",
    },
    "hardsigmoid_int_default": {
        "category": "Activation",
        "function": "Integer hard-sigmoid",
        "domain": "x_i:int32; exp_x:-20..12; gate_bits:4..15",
        "corners": "Lower/upper clamp to [0, 2^gate_bits-1]",
    },
    "wkv_lut_lookup": {
        "category": "Lookup",
        "function": "WKV LUT index mapping",
        "domain": "delta/min/step:int32; LUT_NUMEL=256",
        "corners": "step=0; +/-step; index clamp to [0, LUT_NUMEL-1]",
    },
}

LINE_RE = re.compile(
    r"\[L0\]\[(PASS|FAIL)\]\s+op=([A-Za-z0-9_]+)\s+cases=(\d+)\s+mismatches=(\d+)"
)


def parse_log(path: Path) -> Tuple[str, str, int, int]:
    txt = path.read_text(encoding="utf-8", errors="ignore")
    for line in txt.splitlines():
        m = LINE_RE.search(line)
        if m:
            status = m.group(1)
            op_name = m.group(2)
            cases = int(m.group(3))
            mismatches = int(m.group(4))
            return status, op_name, cases, mismatches
    raise RuntimeError(f"no L0 summary line found in {path}")


def format_rate_percent(mismatches: int, cases: int) -> str:
    if cases <= 0:
        return "0.000000"
    return f"{(100.0 * mismatches / cases):.6f}"


def build_rows(config: L0TableConfig) -> Tuple[List[Dict[str, str]], List[Dict[str, str]], Dict[str, int]]:
    result_rows: List[Dict[str, str]] = []
    coverage_rows: List[Dict[str, str]] = []
    total_cases = 0
    total_mismatches = 0

    for idx, op in enumerate(EXPECTED_OPS, start=1):
        log_file = config.log_dir / f"tb_l0_{op}.log"
        if not log_file.exists():
            raise FileNotFoundError(f"missing log file: {log_file}")
        status, op_name, cases, mismatches = parse_log(log_file)
        if op_name != op:
            raise RuntimeError(f"log op mismatch: expected {op}, got {op_name} in {log_file}")
        meta = OPERATOR_META[op]
        verdict = "Equivalent (bit-exact)" if status == "PASS" and mismatches == 0 else "Not equivalent"
        result_rows.append(
            {
                "Index": f"OP{idx}",
                "Category": meta["category"],
                "Operator": op,
                "Test Vectors": str(cases),
                "Mismatches": str(mismatches),
                "Mismatch Rate (%)": format_rate_percent(mismatches, cases),
                "Verdict": verdict,
            }
        )
        coverage_rows.append(
            {
                "Operator": op,
                "Function": meta["function"],
                "Numeric Domain": meta["domain"],
                "Directed Corner Coverage": meta["corners"],
            }
        )
        total_cases += cases
        total_mismatches += mismatches

    summary = {
        "total_ops": len(result_rows),
        "total_cases": total_cases,
        "total_mismatches": total_mismatches,
    }
    return result_rows, coverage_rows, summary


def write_result_csv(path: Path, rows: List[Dict[str, str]], summary: Dict[str, int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        columns = [
            "Index",
            "Category",
            "Operator",
            "Test Vectors",
            "Mismatches",
            "Mismatch Rate (%)",
            "Verdict",
        ]
        writer.writerow(columns)
        for row in rows:
            writer.writerow([row[c] for c in columns])
        writer.writerow(
            [
                "TOTAL",
                "-",
                f"{summary['total_ops']} operators",
                str(summary["total_cases"]),
                str(summary["total_mismatches"]),
                format_rate_percent(summary["total_mismatches"], summary["total_cases"]),
                "Equivalent (bit-exact)" if summary["total_mismatches"] == 0 else "Check required",
            ]
        )


def write_coverage_csv(path: Path, rows: List[Dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        columns = ["Operator", "Function", "Numeric Domain", "Directed Corner Coverage"]
        writer.writerow(columns)
        for row in rows:
            writer.writerow([row[c] for c in columns])


def write_md(
    path: Path,
    result_rows: List[Dict[str, str]],
    coverage_rows: List[Dict[str, str]],
    summary: Dict[str, int],
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    total_rate = format_rate_percent(summary["total_mismatches"], summary["total_cases"])
    overall_verdict = "Equivalent (bit-exact)" if summary["total_mismatches"] == 0 else "Check required"

    lines = [
        "# L0 Operator Equivalence (Paper-Ready)",
        "",
        f"- Operators: {summary['total_ops']}",
        f"- Total test vectors: {summary['total_cases']}",
        f"- Total mismatches: {summary['total_mismatches']}",
        f"- Overall mismatch rate: {total_rate}%",
        f"- Overall verdict: {overall_verdict}",
        "",
        "## Main Equivalence Results",
        "",
        "| ID | Category | Operator | #Test Vectors | #Mismatches | Mismatch Rate (%) | Verdict |",
        "|---|---|---|---:|---:|---:|---|",
    ]
    for row in result_rows:
        lines.append(
            f"| {row['Index']} | {row['Category']} | `{row['Operator']}` | "
            f"{row['Test Vectors']} | {row['Mismatches']} | {row['Mismatch Rate (%)']} | {row['Verdict']} |"
        )
    lines.append(
        f"| TOTAL | - | {summary['total_ops']} operators | {summary['total_cases']} | "
        f"{summary['total_mismatches']} | {total_rate} | {overall_verdict} |"
    )
    lines.extend(
        [
            "",
            "## Stimulus Coverage Notes",
            "",
            "| Operator | Function | Numeric Domain | Directed Corner Coverage |",
            "|---|---|---|---|",
        ]
    )
    for row in coverage_rows:
        lines.append(
            f"| `{row['Operator']}` | {row['Function']} | {row['Numeric Domain']} | {row['Directed Corner Coverage']} |"
        )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def tex_escape(s: str) -> str:
    table = {
        "\\": r"\textbackslash{}",
        "&": r"\&",
        "%": r"\%",
        "$": r"\$",
        "#": r"\#",
        "_": r"\_",
        "{": r"\{",
        "}": r"\}",
        "~": r"\textasciitilde{}",
        "^": r"\textasciicircum{}",
    }
    return "".join(table.get(ch, ch) for ch in s)


def write_tex(path: Path, rows: List[Dict[str, str]], summary: Dict[str, int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    total_rate = format_rate_percent(summary["total_mismatches"], summary["total_cases"])
    overall_verdict = "Equivalent (bit-exact)" if summary["total_mismatches"] == 0 else "Check required"

    lines = [
        r"\begin{table}[t]",
        r"\centering",
        r"\caption{L0 operator bit-exact equivalence between Python reference and RTL (Icarus Verilog).}",
        r"\label{tab:l0_equivalence}",
        r"\begin{tabular}{lllrrrl}",
        r"\toprule",
        r"ID & Category & Operator & Vectors & Mismatches & Mismatch Rate (\%) & Verdict \\",
        r"\midrule",
    ]
    for row in rows:
        lines.append(
            " & ".join(
                [
                    tex_escape(row["Index"]),
                    tex_escape(row["Category"]),
                    r"\texttt{" + tex_escape(row["Operator"]) + "}",
                    tex_escape(row["Test Vectors"]),
                    tex_escape(row["Mismatches"]),
                    tex_escape(row["Mismatch Rate (%)"]),
                    tex_escape(row["Verdict"]),
                ]
            )
            + r" \\"
        )
    lines.extend(
        [
            r"\midrule",
            " & ".join(
                [
                    "TOTAL",
                    "-",
                    tex_escape(f"{summary['total_ops']} operators"),
                    tex_escape(str(summary["total_cases"])),
                    tex_escape(str(summary["total_mismatches"])),
                    tex_escape(total_rate),
                    tex_escape(overall_verdict),
                ]
            )
            + r" \\",
            r"\bottomrule",
            r"\end{tabular}",
            r"\end{table}",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def main(config: L0TableConfig = CONFIG) -> None:
    result_rows, coverage_rows, summary = build_rows(config)
    write_result_csv(config.out_csv, result_rows, summary)
    write_coverage_csv(config.out_cov_csv, coverage_rows)
    write_md(config.out_md, result_rows, coverage_rows, summary)
    write_tex(config.out_tex, result_rows, summary)
    print(f"[L0][OK] wrote {config.out_csv}")
    print(f"[L0][OK] wrote {config.out_cov_csv}")
    print(f"[L0][OK] wrote {config.out_md}")
    print(f"[L0][OK] wrote {config.out_tex}")


if __name__ == "__main__":
    main()
