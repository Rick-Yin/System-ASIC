#!/usr/bin/env python3
import argparse
import csv
import pathlib
import re
from dataclasses import dataclass
from typing import Dict, List, Optional


CLOCK_DIR_RE = re.compile(r"^clk_([0-9]+(?:p[0-9]+)?)ns$")
AREA_RE = re.compile(r"Chip area for module .*?:\s*([0-9eE+\-.]+)")
CELL_RE = re.compile(r"Number of cells:\s*([0-9]+)")
CELL_LINE_RE = re.compile(r"^\s*([0-9]+)(?:\s+[0-9eE+\-.]+)?\s+cells\s*$", re.MULTILINE)


@dataclass
class QorRow:
    clock_ns: str
    status: str
    mode: str
    total_cells: str
    total_area: str
    mul_cells: str
    div_cells: str
    mux_cells: str
    report_dir: str


def read_text(path: pathlib.Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="ignore")


def parse_clock_ns(dirname: str) -> Optional[float]:
    m = CLOCK_DIR_RE.match(dirname)
    if not m:
        return None
    return float(m.group(1).replace("p", "."))


def parse_stat(stat_text: str) -> tuple[Optional[int], Optional[float], Dict[str, int]]:
    cells = None
    type_counts: Dict[str, int] = {}

    areas = AREA_RE.findall(stat_text)
    if areas:
        try:
            area = float(areas[-1])
        except ValueError:
            area = None
    else:
        area = None

    cells_all = CELL_RE.findall(stat_text)
    if cells_all:
        try:
            cells = int(cells_all[-1])
        except ValueError:
            cells = None
    else:
        line_cells = CELL_LINE_RE.findall(stat_text)
        if line_cells:
            try:
                cells = int(line_cells[-1])
            except ValueError:
                cells = None

    for line in stat_text.splitlines():
        s = line.strip()
        if not s:
            continue
        toks = s.split()
        if len(toks) < 2:
            continue
        if not toks[0].isdigit():
            continue
        cell_type = toks[-1]
        if not cell_type.startswith("$"):
            continue
        type_counts[cell_type] = type_counts.get(cell_type, 0) + int(toks[0])

    return cells, area, type_counts


def collect_rows(reports_dir: pathlib.Path, mode: str) -> List[QorRow]:
    rows = []
    for sub in sorted(reports_dir.iterdir() if reports_dir.exists() else []):
        if not sub.is_dir():
            continue
        clk = parse_clock_ns(sub.name)
        if clk is None:
            continue

        status_path = sub / "status.txt"
        status = read_text(status_path).strip().lower() if status_path.exists() else "unknown"
        if status not in {"pass", "fail"}:
            status = "unknown"

        stat_txt = read_text(sub / "stat.rpt")
        cells, area, type_counts = parse_stat(stat_txt)
        mul_cells = type_counts.get("$mul", 0)
        div_cells = type_counts.get("$div", 0)
        mux_cells = (
            type_counts.get("$mux", 0)
            + type_counts.get("$pmux", 0)
            + type_counts.get("$bmux", 0)
            + type_counts.get("$bwmux", 0)
        )

        rows.append(
            QorRow(
                clock_ns=f"{clk:.3f}",
                status=status,
                mode=mode,
                total_cells=str(cells) if cells is not None else "n/a",
                total_area=f"{area:.3f}" if area is not None else "n/a",
                mul_cells=str(mul_cells),
                div_cells=str(div_cells),
                mux_cells=str(mux_cells),
                report_dir=str(sub),
            )
        )
    rows.sort(key=lambda r: float(r.clock_ns))
    return rows


def write_csv(path: pathlib.Path, rows: List[QorRow]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            ["clock_ns", "status", "mode", "total_cells", "total_area", "mul_cells", "div_cells", "mux_cells", "report_dir"]
        )
        for r in rows:
            writer.writerow(
                [r.clock_ns, r.status, r.mode, r.total_cells, r.total_area, r.mul_cells, r.div_cells, r.mux_cells, r.report_dir]
            )


def write_md(path: pathlib.Path, rows: List[QorRow], top_module: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        f"# OSS Synthesis QoR Summary ({top_module})",
        "",
        "| clock_ns | status | mode | total_cells | total_area | $mul | $div | $mux* | report_dir |",
        "|---:|:---:|:---:|---:|---:|---:|---:|---:|---|",
    ]
    for r in rows:
        lines.append(
            f"| {r.clock_ns} | {r.status} | {r.mode} | {r.total_cells} | {r.total_area} | {r.mul_cells} | {r.div_cells} | {r.mux_cells} | `{r.report_dir}` |"
        )
    if not rows:
        lines.append("| n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a | n/a |")
    lines.append("")
    lines.append("`$mux* = $mux + $pmux + $bmux + $bwmux`")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Summarize Yosys clock-sweep QoR reports.")
    parser.add_argument("--reports-dir", required=True, help="Run report directory (contains clk_*ns/).")
    parser.add_argument("--output-csv", required=True, help="Output CSV path.")
    parser.add_argument("--output-md", required=True, help="Output markdown path.")
    parser.add_argument("--top-module", default="top", help="Top module name for display.")
    parser.add_argument("--mode", default="mapped", choices=["frontend", "mapped"], help="Run mode for summary context.")
    args = parser.parse_args()

    reports_dir = pathlib.Path(args.reports_dir)
    rows = collect_rows(reports_dir, args.mode)
    write_csv(pathlib.Path(args.output_csv), rows)
    write_md(pathlib.Path(args.output_md), rows, args.top_module)

    print(f"[OSS-QOR] rows: {len(rows)}")
    print(f"[OSS-QOR] csv: {args.output_csv}")
    print(f"[OSS-QOR] md: {args.output_md}")


if __name__ == "__main__":
    main()
