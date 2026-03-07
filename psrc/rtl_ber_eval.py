#!/usr/bin/env python3
"""Evaluate BER/MAE between packed golden vec and packed RTL vec outputs."""

from __future__ import annotations

import json
from pathlib import Path
from typing import List

MANIFEST = Path("vsrc/rom/manifest.json")
REF_VEC = Path("vsrc/Joint-CFR-DPD/tb/top/vectors/golden_output_packed.vec")
RTL_VEC = Path("vsrc/Joint-CFR-DPD/tb/top/logs/rtl_output_packed.vec")
DEFAULT_BITS_PER_COMPONENT = 12


def parse_model_dims(tensors: List[dict]) -> dict:
    by_name = {t["name"]: t for t in tensors}
    input_w = by_name["input_proj.w"]["shape"]
    output_w = by_name["output_proj.w"]["shape"]
    ffn_key = by_name["blocks.0.ffn.key.w"]["shape"]
    ts_w = by_name["blocks.0.att.time_shift.w"]["shape"]

    layer_ids = set()
    for t in tensors:
        name = t["name"]
        if name.startswith("blocks."):
            parts = name.split(".")
            if len(parts) >= 2 and parts[1].isdigit():
                layer_ids.add(int(parts[1]))

    return {
        "MODEL_DIM": int(input_w[0]),
        "IN_DIM": int(input_w[1]),
        "OUT_DIM": int(output_w[0]),
        "LAYER_NUM": (max(layer_ids) + 1) if layer_ids else 0,
        "HIDDEN_SZ": int(ffn_key[0]),
        "KERNEL_SIZE": int(ts_w[2]),
    }


def to_u(v: int, bits: int) -> int:
    mask = (1 << bits) - 1
    return v & mask


def to_s32(v: int) -> int:
    u = int(v) & 0xFFFF_FFFF
    if u & 0x8000_0000:
        return u - 0x1_0000_0000
    return u


def popcount(x: int) -> int:
    return x.bit_count()


def unpack_bus(bus: int, dims: int) -> List[int]:
    row: List[int] = []
    for i in range(dims):
        lane_u = (bus >> (32 * i)) & 0xFFFF_FFFF
        row.append(to_s32(lane_u))
    return row


def load_packed_vec(path: Path, dims: int) -> List[List[int]]:
    rows: List[List[int]] = []
    with path.open("r", encoding="utf-8") as f:
        for ln, line in enumerate(f, start=1):
            s = line.strip()
            if not s:
                continue
            try:
                bus = int(s, 16)
            except ValueError as e:
                raise SystemExit(f"malformed hex in {path}:{ln}: {s}") from e
            rows.append(unpack_bus(bus, dims))
    return rows


def main() -> None:
    if not MANIFEST.exists():
        raise SystemExit(f"missing manifest: {MANIFEST}")
    if not REF_VEC.exists():
        raise SystemExit(f"missing REF_VEC in script config: {REF_VEC}")
    if not RTL_VEC.exists():
        raise SystemExit(f"missing RTL_VEC in script config: {RTL_VEC}")

    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    dims = parse_model_dims(manifest["tensors"])
    out_dim = int(dims["OUT_DIM"])
    io = manifest.get("io", {})
    bits_per_component = int(io.get("out_bits", DEFAULT_BITS_PER_COMPONENT))

    ref = load_packed_vec(REF_VEC, out_dim)
    rtl = load_packed_vec(RTL_VEC, out_dim)

    if len(ref) != len(rtl):
        raise SystemExit(f"row count mismatch: ref={len(ref)} rtl={len(rtl)}")
    if len(ref) == 0:
        raise SystemExit("empty input")

    bit_err = 0
    bit_tot = 0
    vec_mismatch = 0
    max_abs_err = 0
    sum_abs_err = 0

    for a, b in zip(ref, rtl):
        mismatch = False
        for av, bv in zip(a, b):
            ua = to_u(av, bits_per_component)
            ub = to_u(bv, bits_per_component)
            bit_err += popcount(ua ^ ub)
            bit_tot += bits_per_component
            d = abs(av - bv)
            sum_abs_err += d
            if d > max_abs_err:
                max_abs_err = d
            if av != bv:
                mismatch = True
        if mismatch:
            vec_mismatch += 1

    ber = bit_err / bit_tot if bit_tot else 0.0
    vec_total = len(ref)
    vec_mismatch_ratio = vec_mismatch / vec_total
    mae = sum_abs_err / (vec_total * out_dim)

    print(f"rows={vec_total} dims={out_dim} bits={bits_per_component}")
    print(f"bit_errors={bit_err} bit_total={bit_tot} BER={ber:.6e}")
    print(f"vector_mismatch={vec_mismatch}/{vec_total} ratio={vec_mismatch_ratio:.6e}")
    print(f"MAE={mae:.6f} max_abs_err={max_abs_err}")


if __name__ == "__main__":
    main()
