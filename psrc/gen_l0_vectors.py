#!/usr/bin/env python3
"""Generate deterministic L0 operator vectors for SystemVerilog self-check testbenches."""

from __future__ import annotations

import json
import random
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Tuple


@dataclass(frozen=True)
class L0VectorConfig:
    seed: int = 20260305
    out_dir: Path = Path("vsrc/Joint-CFR-DPD/tb/l0_ops/vectors")
    sat_random: int = 3000
    rshift_random: int = 3000
    div_random: int = 3000
    requant_random: int = 5000
    hsig_random: int = 4000
    wkv_random: int = 4000
    wkv_lut_numel: int = 256
    wkv_lut_bias: int = -500
    wkv_lut_step: int = 3


CONFIG = L0VectorConfig()

S64_MIN = -(1 << 63) + 1
S64_MAX = (1 << 63) - 1


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


def sat_signed32(x: int, bits: int) -> int:
    lo = qmin_signed(bits)
    hi = qmax_signed(bits)
    return max(lo, min(hi, int(x)))


def abs64(x: int) -> int:
    return -x if x < 0 else x


def rshift_rne64(x: int, sh: int) -> int:
    if sh <= 0:
        return int(x)
    if sh >= 62:
        return 0
    neg = x < 0
    ax = abs64(x)
    half = 1 << (sh - 1)
    mask = (1 << sh) - 1
    r = ax & mask
    q = ax >> sh
    inc = (r > half) or ((r == half) and ((q & 1) == 1))
    q2 = q + (1 if inc else 0)
    return -q2 if neg else q2


def div_rne64(x: int, d: int) -> int:
    if d == 0:
        return 0
    neg = (x < 0) ^ (d < 0)
    ax = abs64(x)
    ad = abs64(d)
    q = ax // ad
    r = ax - q * ad
    two_r = r << 1
    inc = (two_r > ad) or ((two_r == ad) and ((q & 1) == 1))
    q2 = q + (1 if inc else 0)
    return -q2 if neg else q2


def to_s64(v: int) -> int:
    u = int(v) & 0xFFFF_FFFF_FFFF_FFFF
    if u & (1 << 63):
        return u - (1 << 64)
    return u


def requant_pow2_signed(x: int, exp_in: int, exp_out: int, bits: int) -> int:
    delta = int(exp_in) - int(exp_out)
    if delta > 0:
        if delta >= 62:
            y = qmin_signed(bits) if x < 0 else qmax_signed(bits)
        else:
            x64 = to_s64(x)
            y_shifted = to_s64(x64 << delta)
            y_roundtrip = to_s64(y_shifted >> delta)
            if y_roundtrip != x64:
                y = qmin_signed(bits) if x < 0 else qmax_signed(bits)
            else:
                y = y_shifted
    elif delta < 0:
        y = rshift_rne64(int(x), -delta)
    else:
        y = int(x)
    return sat_signed32(y, bits)


def hardsigmoid_int_default(x_i: int, exp_x: int, gate_bits: int) -> int:
    exp_gate = -int(gate_bits)
    s = int(exp_x) - exp_gate
    xi = int(x_i)
    if s > 0:
        if s >= 62:
            x_scaled = -0x4000_0000_0000_0000 if xi < 0 else 0x3FFF_FFFF_FFFF_FFFF
        else:
            x_scaled = xi << s
    elif s < 0:
        x_scaled = rshift_rne64(xi, -s)
    else:
        x_scaled = xi
    div_term = div_rne64(x_scaled, 6)
    offset = (1 << int(gate_bits)) >> 1
    y = div_term + offset
    cmax = (1 << int(gate_bits)) - 1
    if y < 0:
        return 0
    if y > cmax:
        return int(cmax)
    return int(y)


def wkv_lut_lookup_idx(delta_i: int, min_delta_i: int, step_i: int, lut_numel: int) -> int:
    if lut_numel <= 0:
        return 0
    num = int(delta_i) - int(min_delta_i)
    if int(step_i) == 0:
        idx = 0
    else:
        idx = div_rne64(num, int(step_i))
    if idx < 0:
        return 0
    if idx >= lut_numel:
        return lut_numel - 1
    return int(idx)


def h32(v: int) -> str:
    return f"{(int(v) & 0xFFFF_FFFF):08X}"


def h64(v: int) -> str:
    return f"{(int(v) & 0xFFFF_FFFF_FFFF_FFFF):016X}"


def clamp_s64(v: int) -> int:
    if v < S64_MIN:
        return S64_MIN
    if v > S64_MAX:
        return S64_MAX
    return int(v)


def write_rows(path: Path, rows: Iterable[Sequence[str]]) -> int:
    count = 0
    with path.open("w", encoding="utf-8", newline="\n") as f:
        for row in rows:
            f.write(" ".join(row) + "\n")
            count += 1
    return count


def gen_sat_rows(rng: random.Random, cfg: L0VectorConfig) -> List[Tuple[str, str, str]]:
    rows: List[Tuple[str, str, str]] = []
    bits_pool = [1, 2, 3, 4, 8, 12, 16, 24, 31, 32]

    for bits in bits_pool:
        lo = qmin_signed(bits)
        hi = qmax_signed(bits)
        directed = [lo - 2, lo - 1, lo, lo + 1, -1, 0, 1, hi - 1, hi, hi + 1, hi + 2]
        for x in directed:
            y = sat_signed32(x, bits)
            rows.append((h64(clamp_s64(x)), h32(bits), h32(y)))

    for _ in range(cfg.sat_random):
        bits = bits_pool[rng.randrange(len(bits_pool))]
        x = rng.randint(-(1 << 52), (1 << 52))
        y = sat_signed32(x, bits)
        rows.append((h64(clamp_s64(x)), h32(bits), h32(y)))
    return rows


def gen_rshift_rows(rng: random.Random, cfg: L0VectorConfig) -> List[Tuple[str, str, str]]:
    rows: List[Tuple[str, str, str]] = []
    x_directed = [-(1 << 50), -(1 << 20), -1000, -3, -2, -1, 0, 1, 2, 3, 1000, (1 << 20), (1 << 50)]
    sh_directed = [-4, -1, 0, 1, 2, 3, 4, 7, 8, 15, 31, 32, 61, 62, 63, 64, 80]
    for x in x_directed:
        for sh in sh_directed:
            y = rshift_rne64(x, sh)
            rows.append((h64(clamp_s64(x)), h32(sh), h64(clamp_s64(y))))

    for _ in range(cfg.rshift_random):
        x = rng.randint(-(1 << 56), (1 << 56))
        sh = rng.randint(-8, 96)
        y = rshift_rne64(x, sh)
        rows.append((h64(clamp_s64(x)), h32(sh), h64(clamp_s64(y))))
    return rows


def gen_div_rows(rng: random.Random, cfg: L0VectorConfig) -> List[Tuple[str, str, str]]:
    rows: List[Tuple[str, str, str]] = []
    x_directed = [-(1 << 48), -(1 << 20), -1000, -7, -3, -2, -1, 0, 1, 2, 3, 7, 1000, (1 << 20), (1 << 48)]
    d_directed = [-1024, -16, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 16, 1024]
    for x in x_directed:
        for d in d_directed:
            y = div_rne64(x, d)
            rows.append((h64(clamp_s64(x)), h64(clamp_s64(d)), h64(clamp_s64(y))))

    for d in [2, 4, 6, 8, 10, 12, 14]:
        for q in range(-64, 65, 5):
            x = q * d + (d // 2)
            y = div_rne64(x, d)
            rows.append((h64(clamp_s64(x)), h64(clamp_s64(d)), h64(clamp_s64(y))))
            y = div_rne64(-x, d)
            rows.append((h64(clamp_s64(-x)), h64(clamp_s64(d)), h64(clamp_s64(y))))

    for _ in range(cfg.div_random):
        x = rng.randint(-(1 << 56), (1 << 56))
        d = rng.randint(-(1 << 24), (1 << 24))
        if rng.randrange(20) == 0:
            d = 0
        y = div_rne64(x, d)
        rows.append((h64(clamp_s64(x)), h64(clamp_s64(d)), h64(clamp_s64(y))))
    return rows


def gen_requant_rows(rng: random.Random, cfg: L0VectorConfig) -> List[Tuple[str, str, str, str, str]]:
    rows: List[Tuple[str, str, str, str, str]] = []
    exp_pool = [-24, -20, -16, -12, -8, -6, -3, -1, 0, 1, 3, 6, 8, 12, 16, 20, 24]
    bits_pool = [2, 3, 4, 6, 8, 12, 16, 24, 31]
    x_directed = [-(1 << 40), -(1 << 30), -4096, -3, -2, -1, 0, 1, 2, 3, 4096, (1 << 30), (1 << 40)]

    for x in x_directed:
        for exp_in in exp_pool:
            for exp_out in exp_pool:
                bits = bits_pool[(exp_in - exp_out) % len(bits_pool)]
                y = requant_pow2_signed(x, exp_in, exp_out, bits)
                rows.append((h64(clamp_s64(x)), h32(exp_in), h32(exp_out), h32(bits), h32(y)))

    for _ in range(cfg.requant_random):
        x = rng.randint(-(1 << 56), (1 << 56))
        exp_in = exp_pool[rng.randrange(len(exp_pool))]
        exp_out = exp_pool[rng.randrange(len(exp_pool))]
        bits = bits_pool[rng.randrange(len(bits_pool))]
        y = requant_pow2_signed(x, exp_in, exp_out, bits)
        rows.append((h64(clamp_s64(x)), h32(exp_in), h32(exp_out), h32(bits), h32(y)))
    return rows


def gen_hsig_rows(rng: random.Random, cfg: L0VectorConfig) -> List[Tuple[str, str, str, str]]:
    rows: List[Tuple[str, str, str, str]] = []
    exp_pool = [-20, -16, -12, -10, -8, -6, -4, -2, 0, 2, 4, 8, 12]
    gate_pool = [4, 6, 8, 10, 12, 15]
    x_directed = [-(1 << 20), -32768, -8192, -2048, -1024, -256, -128, -1, 0, 1, 127, 255, 1024, 2048, 8192, 32767, (1 << 20)]

    for x in x_directed:
        for exp_x in exp_pool:
            for gate_bits in gate_pool:
                y = hardsigmoid_int_default(x, exp_x, gate_bits)
                rows.append((h32(x), h32(exp_x), h32(gate_bits), h32(y)))

    for _ in range(cfg.hsig_random):
        x = rng.randint(-(1 << 30), (1 << 30))
        exp_x = exp_pool[rng.randrange(len(exp_pool))]
        gate_bits = gate_pool[rng.randrange(len(gate_pool))]
        y = hardsigmoid_int_default(x, exp_x, gate_bits)
        rows.append((h32(x), h32(exp_x), h32(gate_bits), h32(y)))
    return rows


def gen_wkv_rows(rng: random.Random, cfg: L0VectorConfig) -> List[Tuple[str, str, str, str, str]]:
    rows: List[Tuple[str, str, str, str, str]] = []
    lut = [cfg.wkv_lut_bias + cfg.wkv_lut_step * i for i in range(cfg.wkv_lut_numel)]
    min_pool = [-4096, -2048, -1024, -256, 0, 1024]
    step_pool = [0, 1, 2, 4, 8, 16, -2, -4, -8]

    for min_delta in min_pool:
        for step in step_pool:
            directed_delta = [
                min_delta - 2048,
                min_delta - 1024,
                min_delta - 1,
                min_delta,
                min_delta + 1,
                min_delta + 255,
                min_delta + 1024,
                min_delta + 4096,
            ]
            for q in [-64, -8, -1, 0, 1, 2, 7, 63, 127, 255, 512]:
                directed_delta.append(min_delta + q * step)
                if step != 0 and (abs(step) % 2 == 0):
                    directed_delta.append(min_delta + q * step + (step // 2))

            for delta in directed_delta:
                idx = wkv_lut_lookup_idx(delta, min_delta, step, cfg.wkv_lut_numel)
                val = lut[idx]
                rows.append((h32(delta), h32(min_delta), h32(step), h32(idx), h32(val)))

    for _ in range(cfg.wkv_random):
        min_delta = min_pool[rng.randrange(len(min_pool))]
        step = step_pool[rng.randrange(len(step_pool))]
        delta = rng.randint(-1 << 15, 1 << 15)
        idx = wkv_lut_lookup_idx(delta, min_delta, step, cfg.wkv_lut_numel)
        val = lut[idx]
        rows.append((h32(delta), h32(min_delta), h32(step), h32(idx), h32(val)))
    return rows


def main(config: L0VectorConfig = CONFIG) -> None:
    rng = random.Random(config.seed)
    out_dir = config.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    files_and_rows: Dict[str, List[Sequence[str]]] = {
        "sat_signed32.vec": gen_sat_rows(rng, config),
        "rshift_rne64.vec": gen_rshift_rows(rng, config),
        "div_rne64.vec": gen_div_rows(rng, config),
        "requant_pow2_signed.vec": gen_requant_rows(rng, config),
        "hardsigmoid_int_default.vec": gen_hsig_rows(rng, config),
        "wkv_lut_lookup.vec": gen_wkv_rows(rng, config),
    }

    counts: Dict[str, int] = {}
    for fname, rows in files_and_rows.items():
        counts[fname] = write_rows(out_dir / fname, rows)

    manifest = {
        "generator": "psrc/gen_l0_vectors.py",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "seed": config.seed,
        "files": counts,
        "wkv_lut": {
            "numel": config.wkv_lut_numel,
            "value_formula": "lut[i] = bias + step * i",
            "bias": config.wkv_lut_bias,
            "step": config.wkv_lut_step,
        },
    }
    (out_dir / "manifest_l0.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    total = sum(counts.values())
    print(f"[L0][OK] generated vectors in {out_dir} total_rows={total}")
    for fname in sorted(counts):
        print(f"[L0][OK] {fname}: {counts[fname]}")


if __name__ == "__main__":
    main()
