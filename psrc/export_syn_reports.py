#!/usr/bin/env python3
"""Export DC/PT synthesis artifacts under report/syn and write summary CSVs.

This script mirrors step-specific outputs from syn_flow/runs/<design>/ into:
  report/syn/dc/<design>/
  report/syn/pt/<design>/

It also maintains:
  report/syn/dc/data.csv
  report/syn/pt/data.csv

The summary fields target the synthesis portion of exp.md Table 1, but each
flow only writes the columns it can actually produce:
  - DC: 模块 / 单元面积
  - PT: 模块 / 总功耗 / WNS/WHS
"""

import argparse
import csv
import re
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Sequence


NUMBER_RE = r"[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?"
POWER_UNITS_W = {
    "W": 1.0,
    "mW": 1.0e-3,
    "uW": 1.0e-6,
    "nW": 1.0e-9,
    "pW": 1.0e-12,
    "fW": 1.0e-15,
    "kW": 1.0e3,
    "MW": 1.0e6,
}

DISPLAY_NAME_MAP = {
    "migo": "MIGO",
    "joint_cfr": "JCFR-DPD",
}

DC_REPORT_FILES = (
    "analyze_file.rpt",
    "elaborate.rpt",
    "link.rpt",
    "uniquify.rpt",
    "check_design_pre.rpt",
    "check_timing_pre.rpt",
    "check_library.rpt",
    "compile_ultra.rpt",
    "check_design_post.rpt",
    "check_timing_post.rpt",
    "threshold_cell.rpt",
    "qor.rpt",
    "area.rpt",
    "power_dc.rpt",
    "clock_gate.rpt",
    "timing_max.rpt",
    "timing_min.rpt",
    "constraints.rpt",
)

PT_REPORT_FILES = (
    "pt_timing_max.rpt",
    "pt_timing_min.rpt",
    "pt_constraints.rpt",
    "power_pt.rpt",
    "switching_activity.rpt",
)

DC_FIELDNAMES = (
    "模块",
    "单元面积",
)

PT_FIELDNAMES = (
    "模块",
    "总功耗",
    "WNS/WHS",
)


def read_text(path):
    # type: (Path) -> str
    return path.read_text(encoding="utf-8", errors="ignore")


def fmt_decimal(value, digits=6):
    # type: (Optional[float], int) -> str
    if value is None:
        return ""
    text = f"{value:.{digits}f}"
    text = text.rstrip("0").rstrip(".")
    return text if text else "0"


def parse_tcl_string_var(config_path, key):
    # type: (Path, str) -> Optional[str]
    pattern = re.compile(rf'^\s*set\s+{re.escape(key)}\s+"([^"]+)"', re.MULTILINE)
    match = pattern.search(read_text(config_path))
    return match.group(1).strip() if match else None


def parse_tcl_scalar_var(config_path, key):
    # type: (Path, str) -> Optional[str]
    pattern = re.compile(rf"^\s*set\s+{re.escape(key)}\s+([^\s#]+)", re.MULTILINE)
    match = pattern.search(read_text(config_path))
    return match.group(1).strip().strip('"') if match else None


def infer_top_module(run_root):
    # type: (Path) -> Optional[str]
    mapped_dir = run_root / "mapped"
    if not mapped_dir.exists():
        return None
    candidates = sorted(mapped_dir.glob("*-mapped.v"))
    if not candidates:
        return None
    return candidates[0].name[: -len("-mapped.v")]


def infer_clock_ns(config_path, run_root, top_module):
    # type: (Path, Path, str) -> str
    mapped_sdc = run_root / "mapped" / f"{top_module}-mapped.sdc"
    if mapped_sdc.exists():
        text = read_text(mapped_sdc)
        match = re.search(
            rf"create_clock\s+.*?-period\s+({NUMBER_RE})\b",
            text,
            re.MULTILINE,
        )
        if match:
            return match.group(1)

    value = parse_tcl_scalar_var(config_path, "DEFAULT_CLK_NS")
    return value or ""


def parse_first_number(text, patterns):
    # type: (str, Sequence[str]) -> Optional[float]
    for pattern in patterns:
        match = re.search(pattern, text, re.MULTILINE)
        if match:
            return float(match.group(1))
    return None


def power_to_watts(value, unit):
    # type: (float, str) -> float
    if unit not in POWER_UNITS_W:
        raise ValueError(f"unsupported power unit: {unit}")
    return value * POWER_UNITS_W[unit]


def parse_named_power_w(text, name):
    # type: (str, str) -> Optional[float]
    pattern = re.compile(
        rf"^\s*{re.escape(name)}\s*=\s*({NUMBER_RE})\s*([fpnumkM]?W)\b",
        re.MULTILINE,
    )
    match = pattern.search(text)
    if not match:
        return None
    return power_to_watts(float(match.group(1)), match.group(2))


def parse_total_power_mw(report_path):
    # type: (Path) -> Optional[float]
    if not report_path.exists():
        return None

    text = read_text(report_path)
    total_pattern = re.compile(
        rf"^\s*Total\s+Power\s*=\s*({NUMBER_RE})\s*([fpnumkM]?W)\b",
        re.MULTILINE,
    )
    match = total_pattern.search(text)
    if match:
        return power_to_watts(float(match.group(1)), match.group(2)) * 1.0e3

    internal_w = parse_named_power_w(text, "Cell Internal Power")
    switching_w = parse_named_power_w(text, "Net Switching Power")
    leakage_w = parse_named_power_w(text, "Cell Leakage Power")
    if None not in (internal_w, switching_w, leakage_w):
        return (internal_w + switching_w + leakage_w) * 1.0e3

    return None


def parse_area(report_path):
    # type: (Path) -> Optional[float]
    if not report_path.exists():
        return None

    text = read_text(report_path)
    return parse_first_number(
        text,
        (
            rf"^\s*Total cell area:\s*({NUMBER_RE})\s*$",
            rf"^\s*Total cell area:\s*({NUMBER_RE})\b",
        ),
    )


def parse_worst_slack(report_path):
    # type: (Path) -> Optional[float]
    if not report_path.exists():
        return None

    text = read_text(report_path)
    values = [
        float(match.group(1))
        for match in re.finditer(
            rf"^\s*slack\s*(?:\([^)]+\))?\s*({NUMBER_RE})\s*$",
            text,
            re.MULTILINE,
        )
    ]
    if not values:
        return None
    return min(values)


def reset_directory(path):
    # type: (Path) -> None
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def copy_file_if_exists(src, dst):
    # type: (Path, Path) -> None
    if not src.exists():
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def _copy_tree_contents(src, dst):
    # type: (Path, Path) -> None
    if not dst.exists():
        dst.mkdir(parents=True)
    for item in src.iterdir():
        target = dst / item.name
        if item.is_dir():
            _copy_tree_contents(item, target)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(str(item), str(target))


def copy_tree_if_exists(src, dst):
    # type: (Path, Path) -> None
    if not src.exists():
        return
    _copy_tree_contents(src, dst)


def write_single_row_csv(path, fieldnames, row):
    # type: (Path, Sequence[str], Dict[str, str]) -> None
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerow(row)


def upsert_csv(path, fieldnames, row, key_fields):
    # type: (Path, Sequence[str], Dict[str, str], Sequence[str]) -> None
    existing: List[Dict[str, str]] = []
    key = tuple(row[field] for field in key_fields)

    if path.exists():
        with path.open("r", newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            for item in reader:
                if tuple(item.get(field, "") for field in key_fields) != key:
                    existing.append({name: item.get(name, "") for name in fieldnames})

    existing.append({name: row.get(name, "") for name in fieldnames})
    existing.sort(key=lambda item: tuple(item.get(field, "") for field in key_fields))

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(existing)


def relpath_text(path, repo_root):
    # type: (Path, Path) -> str
    try:
        return str(path.relative_to(repo_root))
    except ValueError:
        return str(path)


def export_dc_artifacts(run_root, export_dir):
    # type: (Path, Path) -> None
    reset_directory(export_dir)
    copy_tree_if_exists(run_root / "dc", export_dir / "dc")
    copy_tree_if_exists(run_root / "mapped", export_dir / "mapped")
    copy_file_if_exists(run_root / "logs" / "dc_shell.log", export_dir / "logs" / "dc_shell.log")
    for report_name in DC_REPORT_FILES:
        copy_file_if_exists(run_root / "reports" / report_name, export_dir / "reports" / report_name)


def export_pt_artifacts(run_root, export_dir):
    # type: (Path, Path) -> None
    reset_directory(export_dir)
    copy_tree_if_exists(run_root / "power", export_dir / "power")
    copy_file_if_exists(run_root / "logs" / "vcs_compile.log", export_dir / "logs" / "vcs_compile.log")
    copy_file_if_exists(run_root / "logs" / "vcs_sim.log", export_dir / "logs" / "vcs_sim.log")
    copy_file_if_exists(run_root / "logs" / "pt_shell.log", export_dir / "logs" / "pt_shell.log")
    for report_name in PT_REPORT_FILES:
        copy_file_if_exists(run_root / "reports" / report_name, export_dir / "reports" / report_name)


def build_dc_row(repo_root, run_root, export_dir, design, top_module, clock_ns):
    # type: (Path, Path, Path, str, str, str) -> Dict[str, str]
    area_report = run_root / "reports" / "area.rpt"
    unit_area = parse_area(area_report)
    return {
        "模块": DISPLAY_NAME_MAP.get(design, design),
        "单元面积": fmt_decimal(unit_area),
    }


def build_pt_row(repo_root, run_root, export_dir, design, top_module, clock_ns):
    # type: (Path, Path, Path, str, str, str) -> Dict[str, str]
    power_report = run_root / "reports" / "power_pt.rpt"
    timing_max_report = run_root / "reports" / "pt_timing_max.rpt"
    timing_min_report = run_root / "reports" / "pt_timing_min.rpt"

    total_power_mw = parse_total_power_mw(power_report)
    wns_ns = parse_worst_slack(timing_max_report)
    whs_ns = parse_worst_slack(timing_min_report)
    wns_whs_ns = ""
    if wns_ns is not None or whs_ns is not None:
        wns_whs_ns = f"{fmt_decimal(wns_ns)} / {fmt_decimal(whs_ns)}"

    return {
        "模块": DISPLAY_NAME_MAP.get(design, design),
        "总功耗": fmt_decimal(total_power_mw),
        "WNS/WHS": wns_whs_ns,
    }


def parse_args():
    # type: () -> argparse.Namespace
    parser = argparse.ArgumentParser(description="Export DC/PT artifacts under report/syn and summarize metrics.")
    parser.add_argument("--mode", choices=("dc", "pt"), required=True, help="Flow stage to export.")
    parser.add_argument("--repo-root", type=Path, required=True, help="Repository root path.")
    parser.add_argument("--run-root", type=Path, required=True, help="syn_flow/runs/<design> directory.")
    parser.add_argument("--design", required=True, help="Design key, e.g. migo or joint_cfr.")
    parser.add_argument("--clock-ns", required=True, help="Clock period in ns.")
    parser.add_argument("--config", type=Path, required=True, help="Design config.tcl path.")
    parser.add_argument("--top-module", default="", help="Optional top module override.")
    return parser.parse_args()


def main():
    # type: () -> None
    args = parse_args()

    repo_root = args.repo_root.resolve()
    run_root = args.run_root.resolve()
    config_path = args.config.resolve()
    top_module = args.top_module.strip() or parse_tcl_string_var(config_path, "TOP_MODULE") or infer_top_module(run_root)
    if not top_module:
        raise SystemExit(f"[SYN-EXPORT][ERR] unable to infer TOP_MODULE from {config_path}")

    clock_ns = args.clock_ns.strip() or infer_clock_ns(config_path, run_root, top_module)

    export_root = repo_root / "report" / "syn" / args.mode
    export_dir = export_root / args.design

    if args.mode == "dc":
        export_dc_artifacts(run_root, export_dir)
        row = build_dc_row(repo_root, run_root, export_dir, args.design, top_module, clock_ns)
        fieldnames = DC_FIELDNAMES
    else:
        export_pt_artifacts(run_root, export_dir)
        row = build_pt_row(repo_root, run_root, export_dir, args.design, top_module, clock_ns)
        fieldnames = PT_FIELDNAMES

    write_single_row_csv(export_dir / "data.csv", fieldnames, row)
    upsert_csv(export_root / "data.csv", fieldnames, row, key_fields=("模块",))

    print(f"[SYN-EXPORT][OK] mode={args.mode} export_dir={export_dir}")
    print(f"[SYN-EXPORT][OK] data_csv={export_root / 'data.csv'}")


if __name__ == "__main__":
    main()
