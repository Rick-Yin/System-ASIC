#!/usr/bin/env python3
"""Evaluate bit-exact agreement between MIGO golden and RTL outputs."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

from migo_ref import swrap, read_int_vector


def write_csv_summary(
    path: Path,
    rows: int,
    bits: int,
    bit_errors: int,
    bit_total: int,
    ber: float,
    vector_mismatch: int,
    vector_mismatch_ratio: float,
    mae: float,
    max_abs_err: int,
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            [
                "rows",
                "dims",
                "bits_per_component",
                "bit_errors",
                "bit_total",
                "ber",
                "vector_mismatch",
                "vector_mismatch_ratio",
                "mae",
                "max_abs_err",
            ]
        )
        writer.writerow(
            [
                rows,
                1,
                bits,
                bit_errors,
                bit_total,
                f"{ber:.6e}",
                vector_mismatch,
                f"{vector_mismatch_ratio:.6e}",
                f"{mae:.6f}",
                max_abs_err,
            ]
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Evaluate bit-exact agreement for MIGO vectors.")
    parser.add_argument("--ref", type=Path, required=True, help="Golden output vector path.")
    parser.add_argument("--rtl", type=Path, required=True, help="RTL output vector path.")
    parser.add_argument("--bits", type=int, default=9, help="Output bit width.")
    parser.add_argument("--output-csv", type=Path, default=None, help="Optional CSV summary path.")
    parser.add_argument("--require-exact", action="store_true", help="Exit non-zero if any mismatch is found.")
    args = parser.parse_args()

    ref = [swrap(value, args.bits) for value in read_int_vector(args.ref)]
    rtl = [swrap(value, args.bits) for value in read_int_vector(args.rtl)]

    if len(ref) != len(rtl):
        raise SystemExit(f"row count mismatch: ref={len(ref)} rtl={len(rtl)}")
    if not ref:
        raise SystemExit("empty input")

    bit_errors = 0
    vector_mismatch = 0
    sum_abs_err = 0
    max_abs_err = 0
    mask = (1 << args.bits) - 1

    for ref_value, rtl_value in zip(ref, rtl):
        if ref_value != rtl_value:
            vector_mismatch += 1
        bit_errors += ((ref_value & mask) ^ (rtl_value & mask)).bit_count()
        abs_err = abs(ref_value - rtl_value)
        sum_abs_err += abs_err
        if abs_err > max_abs_err:
            max_abs_err = abs_err

    rows = len(ref)
    bit_total = rows * args.bits
    ber = bit_errors / bit_total if bit_total else 0.0
    vector_mismatch_ratio = vector_mismatch / rows if rows else 0.0
    mae = sum_abs_err / rows if rows else 0.0

    print(f"rows={rows} dims=1 bits={args.bits}")
    print(f"bit_errors={bit_errors} bit_total={bit_total} BER={ber:.6e}")
    print(f"vector_mismatch={vector_mismatch}/{rows} ratio={vector_mismatch_ratio:.6e}")
    print(f"MAE={mae:.6f} max_abs_err={max_abs_err}")

    if args.output_csv is not None:
        write_csv_summary(
            args.output_csv,
            rows,
            args.bits,
            bit_errors,
            bit_total,
            ber,
            vector_mismatch,
            vector_mismatch_ratio,
            mae,
            max_abs_err,
        )
        print(f"csv={args.output_csv}")

    if args.require_exact and vector_mismatch != 0:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
