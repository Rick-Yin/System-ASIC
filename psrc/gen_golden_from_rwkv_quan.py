#!/usr/bin/env python3
"""Generate golden vectors from RWKVCNN_Quan forward_int using manifest/bin tensors.

Outputs by default:
  - golden/input_vectors.csv
  - golden/golden_output.csv
  - golden/meta.json
"""

from __future__ import annotations

import argparse
import csv
import json
import random
import struct
from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Sequence, Tuple


def qmax_signed(bits: int) -> int:
    if bits <= 1:
        return 0
    if bits >= 63:
        return 0x3FFF_FFFF_FFFF_FFFF
    return (1 << (bits - 1)) - 1


def qmin_signed(bits: int) -> int:
    if bits <= 1:
        return -1
    if bits >= 63:
        return -0x4000_0000_0000_0000
    return -(1 << (bits - 1))


def read_int32_le(path: Path, numel: int) -> List[int]:
    raw = path.read_bytes()
    expect = int(numel) * 4
    if len(raw) != expect:
        raise ValueError(f"{path} size mismatch: got {len(raw)} bytes, expect {expect}")
    return list(struct.unpack("<" + "i" * int(numel), raw))


def save_csv_int(path: Path, rows: Sequence[Sequence[int]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        for row in rows:
            writer.writerow([int(v) for v in row])


def load_csv_int(path: Path) -> List[List[int]]:
    rows: List[List[int]] = []
    with path.open("r", newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        for row in reader:
            if not row:
                continue
            vals = [int(x.strip()) for x in row if x.strip() != ""]
            if vals:
                rows.append(vals)
    return rows


def parse_model_dims(tensors: List[Dict[str, Any]]) -> Dict[str, int]:
    by_name = {t["name"]: t for t in tensors}
    input_w = by_name["input_proj.w"]["shape"]
    output_w = by_name["output_proj.w"]["shape"]
    ffn_key = by_name["blocks.0.ffn.key.w"]["shape"]
    ts_w = by_name["blocks.0.att.time_shift.w"]["shape"]

    layer_ids = set()
    for t in tensors:
        n = t["name"]
        if n.startswith("blocks."):
            parts = n.split(".")
            if len(parts) >= 2 and parts[1].isdigit():
                layer_ids.add(int(parts[1]))

    return {
        "IN_DIM": int(input_w[1]),
        "MODEL_DIM": int(input_w[0]),
        "LAYER_NUM": (max(layer_ids) + 1) if layer_ids else 0,
        "OUT_DIM": int(output_w[0]),
        "KERNEL_SIZE": int(ts_w[2]),
        "HIDDEN_SZ": int(ffn_key[0]),
    }


def build_params_from_manifest(manifest: Dict[str, Any]) -> Dict[str, Any]:
    dims = parse_model_dims(manifest["tensors"])
    params: Dict[str, Any] = {
        "in_dim": dims["IN_DIM"],
        "model_dim": dims["MODEL_DIM"],
        "layer_num": dims["LAYER_NUM"],
        "out_dim": dims["OUT_DIM"],
        "kernel_size": dims["KERNEL_SIZE"],
        "hidden_sz": dims["HIDDEN_SZ"],
        "init": False,
        "use_hsigmoid": True,
    }

    runtime_q = manifest.get("model_qparams_runtime")
    yaml_q = manifest.get("qparams_from_yaml")
    if isinstance(runtime_q, dict):
        params.update(deepcopy(runtime_q))
    elif isinstance(yaml_q, dict):
        params.update(deepcopy(yaml_q))

    io = manifest.get("io", {})
    if isinstance(io, dict):
        io_int = params.get("io_int", {}) if isinstance(params.get("io_int"), dict) else {}
        if "in_bits" in io:
            io_int["in_bits"] = int(io["in_bits"])
        if "out_bits" in io:
            io_int["out_bits"] = int(io["out_bits"])
        params["io_int"] = io_int

    return params


def build_input_rows(mode: str, frames: int, in_dim: int, in_bits: int, seed: int) -> List[List[int]]:
    lo = qmin_signed(in_bits)
    hi = qmax_signed(in_bits)
    rng = random.Random(seed)
    rows: List[List[int]] = []

    if mode == "random":
        for _ in range(frames):
            rows.append([rng.randint(lo, hi) for _ in range(in_dim)])
        return rows

    if mode == "edge":
        pattern = [lo, lo + 1, -1, 0, 1, hi - 1, hi]
        for t in range(frames):
            row = []
            for d in range(in_dim):
                row.append(int(pattern[(t * in_dim + d) % len(pattern)]))
            rows.append(row)
        return rows

    raise ValueError(f"unsupported mode: {mode}")


def product(shape: Sequence[int]) -> int:
    p = 1
    for v in shape:
        p *= int(v)
    return p


def get_submodule(module: Any, name: str) -> Any:
    if hasattr(module, "get_submodule"):
        return module.get_submodule(name)
    cur = module
    for tok in name.split("."):
        cur = getattr(cur, tok)
    return cur


def set_or_register_buffer(mod: Any, name: str, value: Any) -> None:
    if hasattr(mod, "_buffers") and name in mod._buffers:
        mod._buffers[name] = value
        return
    if hasattr(mod, name) and not (hasattr(mod, "_buffers") and name in mod._buffers):
        setattr(mod, name, value)
        return
    mod.register_buffer(name, value, persistent=False)


def tensor_from_meta(torch_mod: Any, vals: Sequence[int], meta: Dict[str, Any]) -> Any:
    shape = [int(v) for v in meta.get("shape", [len(vals)])]
    if product(shape) != len(vals):
        raise ValueError(f"shape/numel mismatch for {meta.get('name')}: shape={shape}, numel={len(vals)}")
    t = torch_mod.tensor(list(vals), dtype=torch_mod.int32)
    return t.reshape(tuple(shape))


def inject_manifest_int_buffers(
    model: Any,
    manifest: Dict[str, Any],
    tensor_vals: Dict[str, List[int]],
    tensor_meta: Dict[str, Dict[str, Any]],
    torch_mod: Any,
    wkv_lut_cls: Any,
) -> None:
    required_wkv: Dict[str, Any] = {}

    for name, meta in tensor_meta.items():
        category = str(meta.get("category", ""))
        module_name = str(meta.get("module", ""))
        tensor_name = str(meta.get("tensor", ""))
        vals = tensor_vals[name]
        exp = int(meta.get("exp", 0))
        logical_bits = int(meta.get("logical_bits", 32))
        t = tensor_from_meta(torch_mod, vals, meta)

        if category == "weight":
            mod = get_submodule(model, module_name)
            set_or_register_buffer(mod, "_int_w", t)
            set_or_register_buffer(mod, "_int_w_exp", torch_mod.tensor([exp], dtype=torch_mod.int32))
            set_or_register_buffer(mod, "_int_w_bits", torch_mod.tensor([logical_bits], dtype=torch_mod.int32))

        elif category == "bias":
            mod = get_submodule(model, module_name)
            set_or_register_buffer(mod, "_int_b", t)
            set_or_register_buffer(mod, "_int_b_exp", torch_mod.tensor([exp], dtype=torch_mod.int32))

        elif category == "time_mix":
            mod = get_submodule(model, module_name)
            map_name = {
                "time_mix_k": "_int_time_mix_k",
                "time_mix_v": "_int_time_mix_v",
                "time_mix_r": "_int_time_mix_r",
            }.get(tensor_name)
            if map_name is not None:
                set_or_register_buffer(mod, map_name, t)
                set_or_register_buffer(mod, "_int_time_mix_exp", torch_mod.tensor([exp], dtype=torch_mod.int32))

        elif category == "time_mix_meta":
            mod = get_submodule(model, module_name)
            if tensor_name == "one_tm":
                set_or_register_buffer(mod, "_int_one_tm", t)

        elif category == "wkv_param":
            mod = get_submodule(model, module_name)
            if tensor_name == "time_first":
                set_or_register_buffer(mod, "_int_time_first", t)
            elif tensor_name == "time_decay_wexp":
                set_or_register_buffer(mod, "_int_time_decay_wexp", t)

        elif category == "wkv_lut":
            required_wkv["lut_vals"] = vals

        elif category == "wkv_meta":
            if tensor_name == "wkv_min_delta_i":
                required_wkv["min_delta_i"] = int(vals[0])
            elif tensor_name == "wkv_step_i":
                required_wkv["step_i"] = int(vals[0])
            elif tensor_name == "wkv_e_frac":
                required_wkv["e_frac"] = int(vals[0])
            elif tensor_name == "wkv_log_exp":
                required_wkv["log_exp"] = int(vals[0])

    for key in ["lut_vals", "min_delta_i", "step_i", "e_frac", "log_exp"]:
        if key not in required_wkv:
            raise RuntimeError(f"manifest missing required WKV field: {key}")

    lut_tensor = torch_mod.tensor(required_wkv["lut_vals"], dtype=torch_mod.int32)
    min_delta_i = int(required_wkv["min_delta_i"])
    step_i = int(required_wkv["step_i"])
    e_frac = int(required_wkv["e_frac"])
    log_exp = int(required_wkv["log_exp"])

    model._wkv_lut = wkv_lut_cls(lut_tensor, min_delta_i=min_delta_i, step_i=step_i, e_frac=e_frac)

    set_or_register_buffer(model, "_int_wkv_lut", lut_tensor)
    set_or_register_buffer(model, "_int_wkv_min_delta_i", torch_mod.tensor([min_delta_i], dtype=torch_mod.int32))
    set_or_register_buffer(model, "_int_wkv_step_i", torch_mod.tensor([step_i], dtype=torch_mod.int32))
    set_or_register_buffer(model, "_int_wkv_e_frac", torch_mod.tensor([e_frac], dtype=torch_mod.int32))
    set_or_register_buffer(model, "_int_wkv_log_exp", torch_mod.tensor([log_exp], dtype=torch_mod.int32))

    for _, mod in model.named_modules():
        if hasattr(mod, "_int_log_exp"):
            set_or_register_buffer(mod, "_int_log_exp", torch_mod.tensor([log_exp], dtype=torch_mod.int32))

    int_ctx = manifest.get("int_ctx")
    if not isinstance(int_ctx, dict):
        raise RuntimeError("manifest missing int_ctx")
    model._int_ctx = deepcopy(int_ctx)

    io = manifest.get("io", {})
    if not isinstance(io, dict):
        raise RuntimeError("manifest missing io")
    model.qparams.setdefault("io_int", {})
    model.qparams["io_int"]["in_bits"] = int(io.get("in_bits", model.qparams["io_int"].get("in_bits", 12)))
    model.qparams["io_int"]["out_bits"] = int(io.get("out_bits", model.qparams["io_int"].get("out_bits", 12)))

    model._int_ready = True


def resolve_outputs(args: argparse.Namespace) -> Tuple[Path, Path, Path]:
    out_dir = Path(args.out_dir)
    in_csv = Path(args.output_input_csv) if args.output_input_csv else out_dir / "input_vectors.csv"
    out_csv = Path(args.output_golden_csv) if args.output_golden_csv else out_dir / "golden_output.csv"
    meta_json = Path(args.output_meta_json) if args.output_meta_json else out_dir / "meta.json"
    return in_csv, out_csv, meta_json


def main() -> None:
    ap = argparse.ArgumentParser(description="Generate golden vectors from RWKVCNN_Quan.forward_int")
    ap.add_argument("--manifest", type=Path, default=Path("vsrc/rom/manifest.json"))
    ap.add_argument("--bin-dir", type=Path, default=Path("vsrc/rom/bin"))
    ap.add_argument("--input-csv", type=Path, default=None, help="Optional integer input CSV to replay")

    ap.add_argument("--out-dir", type=Path, default=Path("golden"))
    ap.add_argument("--output-input-csv", type=Path, default=None)
    ap.add_argument("--output-golden-csv", type=Path, default=None)
    ap.add_argument("--output-meta-json", type=Path, default=None)

    ap.add_argument("--frames", type=int, default=256)
    ap.add_argument("--mode", choices=["random", "edge"], default="random")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--stateless", action="store_true", help="Run per-frame T=1 calls")
    args = ap.parse_args()

    try:
        import torch
    except Exception as e:  # pragma: no cover
        raise SystemExit(
            "[ERR] torch is required but not available. "
            "Install PyTorch in this environment before generating golden. "
            f"Detail: {e}"
        )

    try:
        from RWKVCNN_Quan import RWKVCNN_Quan, _WKVIntLUT
    except Exception as e:  # pragma: no cover
        raise SystemExit(
            "[ERR] failed to import RWKVCNN_Quan. Ensure dependency modules (e.g. trainers.py, utils.py) "
            "are available on PYTHONPATH. "
            f"Detail: {e}"
        )

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    tensors = manifest.get("tensors", [])
    if not isinstance(tensors, list) or len(tensors) == 0:
        raise SystemExit("[ERR] manifest has no tensors")

    tensor_meta: Dict[str, Dict[str, Any]] = {t["name"]: t for t in tensors}
    tensor_vals: Dict[str, List[int]] = {}
    for t in tensors:
        name = t["name"]
        numel = int(t["numel"])
        bin_file = args.bin_dir / str(t["bin_file"])
        if not bin_file.exists():
            raise SystemExit(f"[ERR] missing tensor bin: {bin_file}")
        tensor_vals[name] = read_int32_le(bin_file, numel)

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

    if args.input_csv is not None:
        in_rows = load_csv_int(args.input_csv)
        if len(in_rows) == 0:
            raise SystemExit(f"[ERR] empty input csv: {args.input_csv}")
        for i, row in enumerate(in_rows):
            if len(row) != in_dim:
                raise SystemExit(f"[ERR] input row {i} width mismatch: got {len(row)} expect {in_dim}")
    else:
        in_rows = build_input_rows(args.mode, int(args.frames), in_dim, in_bits, int(args.seed))

    if len(in_rows) == 0:
        raise SystemExit("[ERR] no input rows generated")

    scale_in = float(2.0 ** exp_in)

    out_rows: List[List[int]] = []
    exp_out_runtime: int | None = None

    with torch.no_grad():
        if args.stateless:
            for row in in_rows:
                x_i = torch.tensor(row, dtype=torch.int32).reshape(1, 1, in_dim)
                x_f = x_i.to(torch.float32) * scale_in
                _, y_i, exp_out = model.forward_int(x_f)
                exp_out_runtime = int(exp_out)
                out_rows.append([int(v) for v in y_i.reshape(-1).tolist()])
        else:
            x_i = torch.tensor(in_rows, dtype=torch.int32).reshape(1, len(in_rows), in_dim)
            x_f = x_i.to(torch.float32) * scale_in
            _, y_i, exp_out = model.forward_int(x_f)
            exp_out_runtime = int(exp_out)
            y_list = y_i.reshape(len(in_rows), out_dim).tolist()
            out_rows = [[int(v) for v in row] for row in y_list]

    if len(out_rows) != len(in_rows):
        raise SystemExit(
            f"[ERR] output rows mismatch: got {len(out_rows)} expected {len(in_rows)}"
        )

    for i, row in enumerate(out_rows):
        if len(row) != out_dim:
            raise SystemExit(f"[ERR] output row {i} width mismatch: got {len(row)} expect {out_dim}")

    output_input_csv, output_golden_csv, output_meta_json = resolve_outputs(args)
    save_csv_int(output_input_csv, in_rows)
    save_csv_int(output_golden_csv, out_rows)

    meta = {
        "generator": "psrc/gen_golden_from_rwkv_quan.py",
        "source": "RWKVCNN_Quan.forward_int",
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "manifest_path": str(args.manifest),
        "bin_dir": str(args.bin_dir),
        "manifest_generated_at_utc": manifest.get("generated_at_utc"),
        "frames": len(in_rows),
        "mode": "replay" if args.input_csv is not None else args.mode,
        "seed": int(args.seed),
        "stateful": (not bool(args.stateless)),
        "input_csv": str(args.input_csv) if args.input_csv is not None else None,
        "outputs": {
            "input_csv": str(output_input_csv),
            "golden_csv": str(output_golden_csv),
            "meta_json": str(output_meta_json),
        },
        "model_dims": dims,
        "io": {
            "in_bits": int(io.get("in_bits", model.qparams.get("io_int", {}).get("in_bits", 12))),
            "in_exp": int(io.get("exp_in", exp_in)),
            "out_bits": int(io.get("out_bits", model.qparams.get("io_int", {}).get("out_bits", 12))),
            "out_exp_manifest": int(io.get("exp_out", 0)),
            "out_exp_runtime": int(exp_out_runtime if exp_out_runtime is not None else 0),
        },
        "int_ctx": deepcopy(manifest.get("int_ctx", {})),
    }

    output_meta_json.parent.mkdir(parents=True, exist_ok=True)
    output_meta_json.write_text(json.dumps(meta, indent=2), encoding="utf-8")

    print(f"[OK] inputs : {output_input_csv} rows={len(in_rows)} dim={in_dim}")
    print(f"[OK] golden : {output_golden_csv} rows={len(out_rows)} dim={out_dim}")
    print(f"[OK] meta   : {output_meta_json}")
    print(
        "[INFO] "
        f"mode={meta['mode']} seed={meta['seed']} stateful={meta['stateful']} "
        f"in_bits={meta['io']['in_bits']} in_exp={meta['io']['in_exp']} "
        f"out_bits={meta['io']['out_bits']} out_exp={meta['io']['out_exp_runtime']}"
    )


if __name__ == "__main__":
    main()
