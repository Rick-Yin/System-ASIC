#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path
from typing import Any

import numpy as np


def load_complex_csv(path: Path) -> np.ndarray:
    data = np.loadtxt(path, delimiter=",")
    if data.ndim == 1:
        if data.size == 0:
            return np.zeros((0,), dtype=np.complex128)
        if data.size == 2:
            data = data.reshape(1, 2)
        else:
            data = data.reshape(-1, 1)
    if data.shape[1] == 1:
        return data[:, 0].astype(np.complex128)
    return data[:, 0].astype(np.complex128) + 1j * data[:, 1].astype(np.complex128)


def save_complex_csv(path: Path, signal: np.ndarray) -> None:
    signal = np.asarray(signal).reshape(-1)
    data = np.column_stack([signal.real, signal.imag])
    np.savetxt(path, data, delimiter=",", fmt="%.18e")


def pa_model(signal: np.ndarray) -> np.ndarray:
    coeffs = np.array(
        [
            [1.0513 + 0.0904j, -0.0680 - 0.0023j, 0.0289 + 0.0054j],
            [0.0542 - 0.2900j, 0.2234 + 0.2317j, -0.0621 - 0.0932j],
            [-0.9657 - 0.7028j, -0.2451 - 0.3735j, 0.1229 + 0.1508j],
        ],
        dtype=np.complex128,
    )
    padded = np.concatenate([np.zeros(2, dtype=np.complex128), signal.reshape(-1)])
    out = np.zeros(signal.shape, dtype=np.complex128)
    for idx in range(2, padded.size):
        acc = 0.0j
        for tap in range(3):
            x = padded[idx - tap]
            acc += coeffs[0, tap] * x
            acc += coeffs[1, tap] * x * (abs(x) ** 2)
            acc += coeffs[2, tap] * x * (abs(x) ** 4)
        out[idx - 2] = acc
    return out


def apply_hc(signal: np.ndarray, clip_max: float) -> np.ndarray:
    signal = np.asarray(signal, dtype=np.complex128)
    mag = np.abs(signal)
    out = signal.copy()
    mask = mag > clip_max
    if np.any(mask):
        out[mask] = clip_max * signal[mask] / mag[mask]
    return out


def apply_volterra(signal: np.ndarray, coeffs: np.ndarray) -> np.ndarray:
    coeffs = np.asarray(coeffs, dtype=np.complex128).reshape(-1)
    if coeffs.size != 9:
        raise ValueError(f"volterra expects 9 coefficients, got {coeffs.size}")
    padded = np.concatenate([np.zeros(2, dtype=np.complex128), signal.reshape(-1)])
    out = np.zeros(signal.shape, dtype=np.complex128)
    for idx in range(2, padded.size):
        x0 = padded[idx]
        x1 = padded[idx - 1]
        x2 = padded[idx - 2]
        out[idx - 2] = (
            coeffs[0] * x0
            + coeffs[1] * x1
            + coeffs[2] * x2
            + coeffs[3] * x0 * (abs(x0) ** 2)
            + coeffs[4] * x1 * (abs(x1) ** 2)
            + coeffs[5] * x2 * (abs(x2) ** 2)
            + coeffs[6] * x0 * (abs(x0) ** 4)
            + coeffs[7] * x1 * (abs(x1) ** 4)
            + coeffs[8] * x2 * (abs(x2) ** 4)
        )
    return out


def apply_iterative_dpd(signal: np.ndarray, iterations: int, step: float) -> np.ndarray:
    target = np.asarray(signal, dtype=np.complex128)
    predistorted = target.copy()
    for _ in range(max(int(iterations), 1)):
        pa_out = pa_model(predistorted)
        predistorted = predistorted + step * (target - pa_out)
    return predistorted


def apply_joint_model(signal: np.ndarray, manifest_path: Path, bin_dir: Path) -> tuple[np.ndarray, dict[str, Any]]:
    try:
        import torch
    except Exception as exc:  # pragma: no cover
        raise RuntimeError(f"joint_cfr_dpd requires torch: {exc}") from exc

    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from gen_golden_from_rwkv_quan import (  # type: ignore
        build_params_from_manifest,
        inject_manifest_int_buffers,
        parse_model_dims,
        read_int32_le,
    )
    from RWKVCNN_Quan import RWKVCNN_Quan, _WKVIntLUT  # type: ignore

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    tensors = manifest.get("tensors", [])
    if not isinstance(tensors, list) or not tensors:
        raise RuntimeError("manifest has no tensors")

    tensor_meta = {t["name"]: t for t in tensors}
    tensor_vals: dict[str, list[int]] = {}
    for t in tensors:
        bin_file = bin_dir / str(t["bin_file"])
        tensor_vals[t["name"]] = read_int32_le(bin_file, int(t["numel"]))

    params = build_params_from_manifest(manifest)
    model = RWKVCNN_Quan(params)
    model.eval()
    model.set_deploy_mode(True, preexp_w=True)
    inject_manifest_int_buffers(model, manifest, tensor_vals, tensor_meta, torch, _WKVIntLUT)
    if hasattr(model, "_move_int_buffers"):
        model._move_int_buffers(torch.device("cpu"))

    io = manifest.get("io", {})
    in_bits = int(io.get("in_bits", 12))
    exp_in = int(io.get("exp_in", -(in_bits - 1)))
    dims = parse_model_dims(tensors)
    in_dim = int(dims["IN_DIM"])
    out_dim = int(dims["OUT_DIM"])
    if in_dim != 2 or out_dim != 2:
        raise RuntimeError(f"joint model expects in_dim=out_dim=2, got {in_dim}/{out_dim}")

    scale_in = float(2.0**exp_in)
    max_int = (1 << (in_bits - 1)) - 1
    min_int = -(1 << (in_bits - 1))
    rows = np.column_stack([signal.real, signal.imag]) / scale_in
    rows = np.clip(np.rint(rows), min_int, max_int).astype(np.int32)

    with torch.no_grad():
        x_i = torch.tensor(rows.tolist(), dtype=torch.int32).reshape(1, len(rows), in_dim)
        x_f = x_i.to(torch.float32) * scale_in
        _, y_i, exp_out = model.forward_int(x_f)
        exp_out_runtime = int(exp_out)
        y_rows = np.array(y_i.reshape(len(rows), out_dim).tolist(), dtype=np.int32)

    scale_out = float(2.0**exp_out_runtime)
    tx_lin = y_rows[:, 0].astype(np.float64) * scale_out + 1j * y_rows[:, 1].astype(np.float64) * scale_out
    meta = {
        "backend_name": "rwkvcnn_joint_cfr_dpd",
        "out_exp_runtime": exp_out_runtime,
        "in_bits": in_bits,
        "in_exp": exp_in,
        "frames": int(len(rows)),
    }
    return tx_lin, meta


def run_backend(signal: np.ndarray, meta: dict[str, Any]) -> tuple[np.ndarray, dict[str, Any]]:
    mode = str(meta.get("backend_mode", "passthrough"))
    lin_cfg = meta.get("linearization", {})
    clip_max = float(lin_cfg.get("hc_clip_max", 1.0))
    dpd_iterations = int(lin_cfg.get("dpd_iterations", 4))
    dpd_step = float(lin_cfg.get("dpd_step", 0.75))

    coeff_pairs = np.asarray(lin_cfg.get("volterra_coeffs_real_imag", []), dtype=np.float64)
    if coeff_pairs.size == 0:
        coeffs = np.zeros((9,), dtype=np.complex128)
    else:
        coeff_pairs = coeff_pairs.reshape(-1, 2)
        coeffs = coeff_pairs[:, 0] + 1j * coeff_pairs[:, 1]

    backend_meta: dict[str, Any] = {"backend_name": mode, "status": "ok"}

    if mode == "passthrough":
        return signal, backend_meta
    if mode == "hc_only":
        return apply_hc(signal, clip_max), backend_meta
    if mode == "dpd_only":
        return apply_iterative_dpd(signal, dpd_iterations, dpd_step), backend_meta
    if mode == "volterra_only":
        return apply_volterra(signal, coeffs), backend_meta
    if mode == "hc_plus_volterra":
        return apply_volterra(apply_hc(signal, clip_max), coeffs), backend_meta
    if mode == "joint_cfr_dpd":
        manifest_path = Path(lin_cfg["model_manifest"])
        bin_dir = Path(lin_cfg["model_bin_dir"])
        tx_lin, joint_meta = apply_joint_model(signal, manifest_path, bin_dir)
        backend_meta.update(joint_meta)
        return tx_lin, backend_meta
    raise ValueError(f"unsupported backend_mode: {mode}")


def main() -> None:
    parser = argparse.ArgumentParser(description="BER linearization backend")
    parser.add_argument("--input-csv", required=True, type=Path)
    parser.add_argument("--input-meta", required=True, type=Path)
    parser.add_argument("--output-csv", required=True, type=Path)
    parser.add_argument("--output-meta", required=True, type=Path)
    args = parser.parse_args()

    signal = load_complex_csv(args.input_csv)
    meta = json.loads(args.input_meta.read_text(encoding="utf-8"))

    tx_lin, backend_meta = run_backend(signal, meta)

    args.output_csv.parent.mkdir(parents=True, exist_ok=True)
    args.output_meta.parent.mkdir(parents=True, exist_ok=True)
    save_complex_csv(args.output_csv, tx_lin)

    output_meta = {
        "status": "ok",
        "backend_name": backend_meta.get("backend_name", meta.get("backend_mode", "unknown")),
        "backend_mode": meta.get("backend_mode", "unknown"),
        "case_id": meta.get("case_id", ""),
        "iter_idx": int(meta.get("iter_idx", 0)),
        "num_samples": int(signal.size),
        "extra": backend_meta,
    }
    args.output_meta.write_text(json.dumps(output_meta, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
