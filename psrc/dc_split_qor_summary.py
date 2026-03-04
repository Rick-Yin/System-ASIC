import argparse
import pathlib
import re
from typing import Optional


def read_text(path: pathlib.Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="ignore")


def extract_total_area(txt: str) -> Optional[float]:
    m = re.search(r"Total\s+cell\s+area:\s*([0-9eE+\-.]+)", txt)
    if m:
        return float(m.group(1))
    return None


def extract_slacks(txt: str):
    vals = []
    for line in txt.splitlines():
        if "slack" not in line.lower():
            continue
        m = re.search(r"(-?\d+\.\d+|-?\d+)", line)
        if m:
            try:
                vals.append(float(m.group(1)))
            except ValueError:
                pass
    return vals


def summarize_flow(reports_root: pathlib.Path, flow: str) -> None:
    rpt_dir = reports_root / flow
    qor = read_text(rpt_dir / "qor.rpt")
    area = read_text(rpt_dir / "area.rpt")
    tmax = read_text(rpt_dir / "timing_max_20.rpt")

    area_total = extract_total_area(area)
    slacks = extract_slacks(tmax)

    print(f"[{flow}]")
    print(f"  report_dir: {rpt_dir}")
    if not rpt_dir.exists():
        print("  status: missing report directory")
        return

    print(f"  qor.rpt: {'yes' if qor else 'no'}")
    print(f"  area.rpt: {'yes' if area else 'no'}")
    print(f"  timing_max_20.rpt: {'yes' if tmax else 'no'}")

    if area_total is not None:
        print(f"  total_cell_area: {area_total:.3f}")
    else:
        print("  total_cell_area: n/a")

    if slacks:
        print(f"  worst_slack_in_timing_max_20: {min(slacks):.3f}")
        neg = sum(1 for s in slacks if s < 0)
        print(f"  negative_slack_lines: {neg}/{len(slacks)}")
    else:
        print("  worst_slack_in_timing_max_20: n/a")
    print()


def main() -> None:
    ap = argparse.ArgumentParser(description="Quick summary for split DC reports (joint/migo)")
    ap.add_argument("--reports-root", type=pathlib.Path, default=pathlib.Path("dc/reports"))
    args = ap.parse_args()

    summarize_flow(args.reports_root, "joint")
    summarize_flow(args.reports_root, "migo")


if __name__ == "__main__":
    main()
