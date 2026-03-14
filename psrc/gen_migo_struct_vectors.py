#!/usr/bin/env python3
"""Generate directed structure-validation vectors for the current MIGO RTL."""

from __future__ import annotations

import argparse
import json
import random
from pathlib import Path

from migo_ref import CURRENT_BY, CURRENT_N, CURRENT_SHIFT, current_migo_coeffs, swrap


def rounded_output(final_sum: int) -> int:
    acc = int(final_sum)
    if CURRENT_SHIFT > 0:
        acc = (acc + (1 << (CURRENT_SHIFT - 1))) >> CURRENT_SHIFT
    else:
        acc >>= CURRENT_SHIFT
    return swrap(acc, CURRENT_BY)


def build_const_coeff_mac_cases(num_cases: int, seed: int) -> list[tuple[list[int], int]]:
    coeffs = current_migo_coeffs()
    rng = random.Random(seed)

    handcrafted: list[list[int]] = [
        [0] * CURRENT_N,
        [127] * CURRENT_N,
        [-128] * CURRENT_N,
        [127 if (idx & 1) == 0 else -128 for idx in range(CURRENT_N)],
        [idx - (CURRENT_N // 2) for idx in range(CURRENT_N)],
        [-(idx - (CURRENT_N // 2)) for idx in range(CURRENT_N)],
        [0 if idx not in {52, 69, 73, 79, 80, 108} else 127 for idx in range(CURRENT_N)],
        [0 if idx not in {52, 69, 73, 79, 80, 108} else -128 for idx in range(CURRENT_N)],
    ]

    cases: list[list[int]] = handcrafted[: max(0, min(num_cases, len(handcrafted)))]
    while len(cases) < num_cases:
        cases.append([rng.randint(-128, 127) for _ in range(CURRENT_N)])

    rows: list[tuple[list[int], int]] = []
    for taps in cases[:num_cases]:
        expected = sum(coeff * tap for coeff, tap in zip(coeffs, taps))
        rows.append((taps, expected))
    return rows


def build_round_shift_cases() -> list[tuple[int, int]]:
    deltas = (-129, -128, -1, 0, 1, 127, 128, 129)
    cases: list[tuple[int, int]] = []
    for bucket in range(-16, 16):
        center = bucket * (1 << CURRENT_SHIFT)
        for delta in deltas:
            final_sum = center + delta
            cases.append((final_sum, rounded_output(final_sum)))
    return cases


def write_const_coeff_mac(path: Path, rows: list[tuple[list[int], int]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        f.write(f"{len(rows)}\n")
        for taps, expected in rows:
            payload = " ".join(str(value) for value in taps)
            f.write(f"{payload} {expected}\n")


def write_round_shift(path: Path, rows: list[tuple[int, int]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        f.write(f"{len(rows)}\n")
        for final_sum, expected in rows:
            f.write(f"{final_sum} {expected}\n")


def write_manifest(
    path: Path,
    *,
    const_coeff_cases: int,
    round_shift_cases: int,
    seed: int,
) -> None:
    manifest = {
        "generator": "psrc/gen_migo_struct_vectors.py",
        "const_coeff_mac_cases": const_coeff_cases,
        "round_shift_cases": round_shift_cases,
        "seed": seed,
        "n": CURRENT_N,
        "shift": CURRENT_SHIFT,
        "out_bits": CURRENT_BY,
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate MIGO structure-validation vectors.")
    parser.add_argument("--out-dir", type=Path, required=True, help="Output directory.")
    parser.add_argument("--const-cases", type=int, default=256, help="Number of const-coeff MAC cases.")
    parser.add_argument("--seed", type=int, default=11, help="Seed for deterministic random cases.")
    args = parser.parse_args()

    const_rows = build_const_coeff_mac_cases(args.const_cases, args.seed)
    round_rows = build_round_shift_cases()

    out_dir = args.out_dir
    write_const_coeff_mac(out_dir / "const_coeff_mac.vec", const_rows)
    write_round_shift(out_dir / "round_shift.vec", round_rows)
    write_manifest(
        out_dir / "manifest_migo_struct.json",
        const_coeff_cases=len(const_rows),
        round_shift_cases=len(round_rows),
        seed=args.seed,
    )

    print(f"const_coeff_mac_cases={len(const_rows)}")
    print(f"round_shift_cases={len(round_rows)}")
    print(f"out_dir={out_dir}")


if __name__ == "__main__":
    main()
