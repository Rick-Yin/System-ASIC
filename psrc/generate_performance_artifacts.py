#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import h5py

os.environ.setdefault("MPLCONFIGDIR", "/tmp/matplotlib")
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


PREFERRED_CASE_ORDER = [
    "migo_no_cfr_no_dpd",
    "migo_hc_no_dpd",
    "migo_no_cfr_dpd",
    "migo_no_cfr_volterra",
    "migo_hc_volterra",
    "migo_joint_cfr_dpd",
]

LEGEND_PRIORITY = [
    "migo_joint_cfr_dpd",
    "wls_joint_cfr_dpd",
    "swls_joint_cfr_dpd",
    "migo_hc_volterra",
    "migo_no_cfr_volterra",
    "migo_no_cfr_dpd",
    "migo_hc_no_dpd",
    "migo_no_cfr_no_dpd",
]

CASE_STYLES: dict[str, dict[str, Any]] = {
    "migo_no_cfr_no_dpd": {
        "color": "#4D4D4D",
        "linestyle": "--",
        "marker": "o",
        "linewidth": 1.8,
        "markersize": 5.5,
        "alpha": 0.92,
        "zorder": 3,
        "markerfacecolor": "white",
        "markeredgewidth": 1.2,
    },
    "migo_hc_no_dpd": {
        "color": "#0072B2",
        "linestyle": "-.",
        "marker": "s",
        "linewidth": 1.8,
        "markersize": 5.5,
        "alpha": 0.92,
        "zorder": 4,
        "markerfacecolor": "white",
        "markeredgewidth": 1.2,
    },
    "migo_no_cfr_dpd": {
        "color": "#009E73",
        "linestyle": ":",
        "marker": "^",
        "linewidth": 1.9,
        "markersize": 6.0,
        "alpha": 0.94,
        "zorder": 5,
        "markerfacecolor": "white",
        "markeredgewidth": 1.2,
    },
    "migo_no_cfr_volterra": {
        "color": "#E69F00",
        "linestyle": "-.",
        "marker": "D",
        "linewidth": 1.9,
        "markersize": 5.8,
        "alpha": 0.94,
        "zorder": 5,
        "markerfacecolor": "white",
        "markeredgewidth": 1.2,
    },
    "migo_hc_volterra": {
        "color": "#56B4E9",
        "linestyle": "-",
        "marker": "v",
        "linewidth": 2.1,
        "markersize": 6.0,
        "alpha": 0.96,
        "zorder": 6,
        "markerfacecolor": "white",
        "markeredgewidth": 1.2,
    },
    "migo_joint_cfr_dpd": {
        "color": "#C73E1D",
        "linestyle": "-",
        "marker": "o",
        "linewidth": 3.0,
        "markersize": 7.0,
        "alpha": 1.0,
        "zorder": 12,
        "markerfacecolor": "#C73E1D",
        "markeredgecolor": "white",
        "markeredgewidth": 1.0,
    },
    "wls_joint_cfr_dpd": {
        "color": "#7A0019",
        "linestyle": "-",
        "marker": "P",
        "linewidth": 2.5,
        "markersize": 6.4,
        "alpha": 0.98,
        "zorder": 10,
        "markerfacecolor": "#7A0019",
        "markeredgecolor": "white",
        "markeredgewidth": 1.0,
    },
    "swls_joint_cfr_dpd": {
        "color": "#8C564B",
        "linestyle": "-",
        "marker": "X",
        "linewidth": 2.5,
        "markersize": 6.4,
        "alpha": 0.98,
        "zorder": 10,
        "markerfacecolor": "#8C564B",
        "markeredgecolor": "white",
        "markeredgewidth": 1.0,
    },
}


@dataclass
class Dataset:
    path: Path
    snr_range: np.ndarray
    case_ids: list[str]
    ber_curve_by_method: np.ndarray  # shape: cases x snr
    evm_curve_by_method: np.ndarray  # shape: cases x snr
    mcs_value: int
    modulation_name: str


def configure_plot_style() -> None:
    plt.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "font.size": 11,
            "axes.labelsize": 12,
            "axes.titlesize": 12,
            "xtick.labelsize": 10.5,
            "ytick.labelsize": 10.5,
            "legend.fontsize": 10.5,
            "axes.linewidth": 1.1,
            "grid.linewidth": 0.7,
            "grid.alpha": 0.28,
            "grid.color": "#BDBDBD",
            "savefig.bbox": "tight",
        }
    )


def decode_hdf5_value(handle: h5py.File, value: Any) -> Any:
    if isinstance(value, h5py.Reference):
        if not value:
            return ""
        return decode_hdf5_value(handle, handle[value][()])

    if isinstance(value, np.ndarray):
        if value.dtype == object:
            return [decode_hdf5_value(handle, item) for item in value.flatten()]
        if value.dtype.kind in {"u", "i"} and value.ndim >= 1:
            flat = value.flatten()
            if flat.size > 0 and np.all((flat >= 0) & (flat <= 0x10FFFF)):
                try:
                    return "".join(chr(int(x)) for x in flat if int(x) != 0)
                except ValueError:
                    pass
        if value.size == 1:
            return value.reshape(-1)[0].item()
        return value

    if isinstance(value, (np.integer, np.floating)):
        return value.item()

    return value


def load_case_ids(handle: h5py.File) -> list[str]:
    raw = handle["case_ids"][()]
    decoded = decode_hdf5_value(handle, raw)
    if isinstance(decoded, str):
        return [decoded]
    if isinstance(decoded, list):
        return [str(item) for item in decoded]
    return [str(decoded)]


def orient_curves(curves: np.ndarray, num_cases: int, num_snr: int) -> np.ndarray:
    arr = np.asarray(curves, dtype=float)
    if arr.ndim == 1:
        if num_cases == 1:
            return arr.reshape(1, -1)
        if num_snr == 1:
            return arr.reshape(-1, 1)
    if arr.shape == (num_cases, num_snr):
        return arr
    if arr.shape == (num_snr, num_cases):
        return arr.T
    if num_cases == 1 and arr.shape[0] == num_snr:
        return arr.reshape(1, num_snr)
    if num_cases == 1 and arr.shape[-1] == num_snr:
        return arr.reshape(1, num_snr)
    raise ValueError(f"Unexpected curve shape {arr.shape} for {num_cases=} {num_snr=}")


def load_compare_mat(path: Path) -> Dataset:
    with h5py.File(path, "r") as handle:
        snr_range = np.asarray(handle["snr_range"][()]).reshape(-1).astype(float)
        case_ids = load_case_ids(handle)
        ber_curve = orient_curves(handle["ber_curve_by_method"][()], len(case_ids), len(snr_range))
        evm_curve = orient_curves(handle["evm_curve_by_method"][()], len(case_ids), len(snr_range))
        mcs_value = int(np.asarray(handle["mcs_value"][()]).reshape(-1)[0])
        modulation_name = str(decode_hdf5_value(handle, handle["modulation_name"][()]))

    return Dataset(
        path=path,
        snr_range=snr_range,
        case_ids=case_ids,
        ber_curve_by_method=ber_curve,
        evm_curve_by_method=evm_curve,
        mcs_value=mcs_value,
        modulation_name=modulation_name,
    )


def get_display_name(case_id: str) -> str:
    return {
        "migo_no_cfr_no_dpd": "No CFR + No DPD",
        "migo_hc_no_dpd": "HC only",
        "migo_no_cfr_dpd": "DPD only",
        "migo_no_cfr_volterra": "Volterra only",
        "migo_hc_volterra": "HC + Volterra",
        "migo_joint_cfr_dpd": "Joint CFR-DPD",
        "wls_joint_cfr_dpd": "WLS + Joint CFR-DPD",
        "swls_joint_cfr_dpd": "SWLS + Joint CFR-DPD",
    }.get(case_id, case_id)


def resolve_case_order(datasets: list[Dataset]) -> list[str]:
    available = []
    for dataset in datasets:
        available.extend(dataset.case_ids)
    deduped = list(dict.fromkeys(available))

    ordered: list[str] = [case_id for case_id in PREFERRED_CASE_ORDER if case_id in deduped]
    ordered.extend(case_id for case_id in deduped if case_id not in ordered)
    if not ordered:
        raise ValueError("No case ids found in datasets.")
    return ordered


def resolve_legend_order(case_ids: list[str]) -> list[str]:
    ordered = [case_id for case_id in LEGEND_PRIORITY if case_id in case_ids]
    ordered.extend(case_id for case_id in case_ids if case_id not in ordered)
    return ordered


def get_case_style(case_id: str, fallback_index: int) -> dict[str, Any]:
    if case_id in CASE_STYLES:
        return dict(CASE_STYLES[case_id])

    fallback_colors = ["#4D4D4D", "#0072B2", "#009E73", "#E69F00", "#56B4E9", "#CC79A7"]
    fallback_markers = ["o", "s", "^", "D", "v", "P"]
    return {
        "color": fallback_colors[fallback_index % len(fallback_colors)],
        "linestyle": "-",
        "marker": fallback_markers[fallback_index % len(fallback_markers)],
        "linewidth": 1.8,
        "markersize": 5.5,
        "alpha": 0.95,
        "zorder": 5,
        "markerfacecolor": "white",
        "markeredgewidth": 1.1,
    }


def sanitize_metric_values(metric: str, values: np.ndarray) -> np.ndarray:
    arr = np.asarray(values, dtype=float).copy()
    if metric == "ber":
        positive = arr[arr > 0]
        floor = 1e-6 if positive.size == 0 else max(1e-6, float(np.min(positive)) * 0.5)
        arr[arr <= 0] = floor
    return arr


def compute_metric_limits(datasets: list[Dataset], metric: str) -> tuple[float, float] | None:
    all_values: list[np.ndarray] = []
    for dataset in datasets:
        source = dataset.ber_curve_by_method if metric == "ber" else 100.0 * dataset.evm_curve_by_method
        for row in source:
            valid = np.asarray(row, dtype=float)
            valid = valid[np.isfinite(valid)]
            if valid.size == 0:
                continue
            if metric == "ber":
                valid = valid[valid > 0]
            if valid.size:
                all_values.append(valid)

    if not all_values:
        return None

    merged = np.concatenate(all_values)
    if metric == "ber":
        ymin = 10 ** np.floor(np.log10(np.min(merged)))
        ymax = 10 ** np.ceil(np.log10(np.max(merged)))
        ymin = min(ymin, 1e-3)
        ymax = max(ymax, 1e-1)
        return float(ymin), float(min(1.0, ymax))

    ymax = float(np.max(merged))
    return 0.0, max(1.0, ymax * 1.12)


def style_axis(ax: plt.Axes, metric: str, panel_idx: int, num_panels: int) -> None:
    ax.grid(True, which="major", axis="both")
    ax.grid(True, which="minor", axis="y", alpha=0.18)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.tick_params(direction="out", length=4.0, width=1.0)
    ax.set_xlabel("SNR (dB)")
    if panel_idx == 0:
        ax.set_ylabel("BER" if metric == "ber" else "EVM (%)")
    elif num_panels > 1:
        ax.set_ylabel("")


def plot_metric(datasets: list[Dataset], metric: str, out_png: Path, out_pdf: Path) -> None:
    configure_plot_style()
    case_order = resolve_case_order(datasets)
    legend_order = resolve_legend_order(case_order)
    y_limits = compute_metric_limits(datasets, metric)

    fig, axes = plt.subplots(
        1,
        len(datasets),
        figsize=(4.9 * len(datasets), 4.1),
        squeeze=False,
        sharey=True if len(datasets) > 1 else False,
    )
    axes_1d = axes[0]
    legend_handles: dict[str, Any] = {}

    for ds_idx, dataset in enumerate(datasets):
        ax = axes_1d[ds_idx]
        for idx, case_id in enumerate(case_order):
            if case_id not in dataset.case_ids:
                continue
            row = dataset.case_ids.index(case_id)
            raw_vals = dataset.ber_curve_by_method[row] if metric == "ber" else 100.0 * dataset.evm_curve_by_method[row]
            y_vals = sanitize_metric_values(metric, raw_vals)
            style = get_case_style(case_id, idx)
            plot_fn = ax.semilogy if metric == "ber" else ax.plot
            line, = plot_fn(dataset.snr_range, y_vals, **style)
            if case_id not in legend_handles:
                legend_handles[case_id] = line

        if y_limits is not None:
            ax.set_ylim(*y_limits)
        ax.set_xlim(float(np.min(dataset.snr_range)), float(np.max(dataset.snr_range)))
        style_axis(ax, metric, ds_idx, len(datasets))

    if legend_handles:
        handles = [legend_handles[case_id] for case_id in legend_order if case_id in legend_handles]
        labels = [get_display_name(case_id) for case_id in legend_order if case_id in legend_handles]
        legend = fig.legend(
            handles,
            labels,
            loc="upper center",
            bbox_to_anchor=(0.5, 1.02),
            ncol=min(3, len(handles)),
            frameon=False,
            handlelength=2.6,
            columnspacing=1.4,
        )
        for text, label in zip(legend.get_texts(), labels):
            if label == "Joint CFR-DPD":
                text.set_fontweight("bold")
                text.set_color("#8E2A0C")

    fig.tight_layout(rect=(0, 0, 1, 0.9))
    out_png.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_png, dpi=300)
    fig.savefig(out_pdf)
    plt.close(fig)


def find_snr_index(snr_range: np.ndarray, target: float) -> int:
    matches = np.where(np.isclose(snr_range, target))[0]
    if matches.size == 0:
        raise ValueError(f"SNR {target} not found in range {snr_range}")
    return int(matches[0])


def get_joint_filter_label(case_id: str) -> str:
    return {
        "migo_joint_cfr_dpd": "MIGO",
        "wls_joint_cfr_dpd": "WLS",
        "swls_joint_cfr_dpd": "SWLS",
    }.get(case_id, case_id)


def build_table_rows(datasets: list[Dataset], key_snr_points: tuple[float, float]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    joint_case_ids = ["migo_joint_cfr_dpd", "wls_joint_cfr_dpd", "swls_joint_cfr_dpd"]

    for dataset in datasets:
        idx_low = find_snr_index(dataset.snr_range, key_snr_points[0])
        idx_high = find_snr_index(dataset.snr_range, key_snr_points[1])

        for case_id in joint_case_ids:
            if case_id not in dataset.case_ids:
                continue
            row = dataset.case_ids.index(case_id)
            rows.append(
                {
                    "mcs_value": dataset.mcs_value,
                    "modulation": dataset.modulation_name,
                    "filter": get_joint_filter_label(case_id),
                    "linearization": "Joint CFR-DPD",
                    "snr_m5_ber": float(dataset.ber_curve_by_method[row, idx_low]),
                    "snr_m5_evm_percent": float(100.0 * dataset.evm_curve_by_method[row, idx_low]),
                    "snr_15_ber": float(dataset.ber_curve_by_method[row, idx_high]),
                    "snr_15_evm_percent": float(100.0 * dataset.evm_curve_by_method[row, idx_high]),
                }
            )
    return rows


def write_table(rows: list[dict[str, Any]], out_csv: Path, out_md: Path, key_snr_points: tuple[float, float]) -> None:
    fieldnames = [
        "mcs_value",
        "modulation",
        "filter",
        "linearization",
        "snr_m5_ber",
        "snr_m5_evm_percent",
        "snr_15_ber",
        "snr_15_evm_percent",
    ]
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    with out_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)

    with out_md.open("w", encoding="utf-8") as f:
        f.write("# 表 2：关键 SNR 点下的 BER / EVM 汇总\n\n")
        f.write(
            f"固定线性化方式为 `Joint CFR-DPD`，关键 SNR 点固定为 `{int(key_snr_points[0])} dB` 和 `{int(key_snr_points[1])} dB`。\n\n"
        )
        f.write(
            f"| MCS | 调制 | 滤波器 | 线性化 | SNR={int(key_snr_points[0])} BER | SNR={int(key_snr_points[0])} EVM (%) | SNR={int(key_snr_points[1])} BER | SNR={int(key_snr_points[1])} EVM (%) |\n"
        )
        f.write("|---:|---|---|---|---:|---:|---:|---:|\n")
        for row in rows:
            f.write(
                f"| {row['mcs_value']} | {row['modulation']} | {row['filter']} | {row['linearization']} | "
                f"{row['snr_m5_ber']:.6e} | {row['snr_m5_evm_percent']:.3f} | "
                f"{row['snr_15_ber']:.6e} | {row['snr_15_evm_percent']:.3f} |\n"
            )


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate performance figures and table from ber_compare_MCS_*.mat files")
    parser.add_argument("--result", action="append", required=True, help="Path to ber_compare_MCS_*.mat; repeatable")
    parser.add_argument("--report-root", required=True, help="Output directory")
    parser.add_argument("--key-snr-points", default="-5,15", help="Two comma-separated SNR points, default -5,15")
    args = parser.parse_args()

    key_vals = [float(token) for token in args.key_snr_points.replace(";", ",").split(",") if token.strip()]
    if len(key_vals) != 2:
        raise ValueError("--key-snr-points must contain exactly two values")
    key_snr_points = (key_vals[0], key_vals[1])

    datasets = [load_compare_mat(Path(path)) for path in args.result]
    datasets.sort(key=lambda ds: ds.mcs_value)

    report_root = Path(args.report_root)
    fig1_png = report_root / "fig1_snr_ber_all_mcs.png"
    fig1_pdf = report_root / "fig1_snr_ber_all_mcs.pdf"
    fig2_png = report_root / "fig2_snr_evm_all_mcs.png"
    fig2_pdf = report_root / "fig2_snr_evm_all_mcs.pdf"
    table2_csv = report_root / "table2_key_snr_summary.csv"
    table2_md = report_root / "table2_key_snr_summary.md"
    manifest_json = report_root / "paper_artifact_manifest.json"

    plot_metric(datasets, "ber", fig1_png, fig1_pdf)
    plot_metric(datasets, "evm", fig2_png, fig2_pdf)
    rows = build_table_rows(datasets, key_snr_points)
    write_table(rows, table2_csv, table2_md, key_snr_points)

    manifest = {
        "result_files": [str(ds.path) for ds in datasets],
        "mcs_values": [ds.mcs_value for ds in datasets],
        "key_snr_points": list(key_snr_points),
        "artifacts": {
            "fig1_png": str(fig1_png),
            "fig1_pdf": str(fig1_pdf),
            "fig2_png": str(fig2_png),
            "fig2_pdf": str(fig2_pdf),
            "table2_csv": str(table2_csv),
            "table2_md": str(table2_md),
        },
    }
    report_root.mkdir(parents=True, exist_ok=True)
    manifest_json.write_text(json.dumps(manifest, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
