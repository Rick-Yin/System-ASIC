import argparse
import csv
from pathlib import Path
from typing import List


def load_csv_int(path: Path) -> List[List[int]]:
    rows: List[List[int]] = []
    with path.open("r", newline="") as f:
        reader = csv.reader(f)
        for row in reader:
            if not row:
                continue
            vals = [int(x.strip()) for x in row if x.strip() != ""]
            if vals:
                rows.append(vals)
    return rows


def to_u(v: int, bits: int) -> int:
    mask = (1 << bits) - 1
    return v & mask


def popcount(x: int) -> int:
    return x.bit_count()


def main() -> None:
    ap = argparse.ArgumentParser(description="Evaluate BER between RTL and reference integer outputs")
    ap.add_argument("--ref", type=Path, required=True, help="Reference CSV (int values)")
    ap.add_argument("--rtl", type=Path, required=True, help="RTL CSV (int values)")
    ap.add_argument("--bits", type=int, default=12, help="Bit-width per output component")
    args = ap.parse_args()

    ref = load_csv_int(args.ref)
    rtl = load_csv_int(args.rtl)

    if len(ref) != len(rtl):
        raise SystemExit(f"row count mismatch: ref={len(ref)} rtl={len(rtl)}")
    if len(ref) == 0:
        raise SystemExit("empty input")

    dims = len(ref[0])
    for i, (a, b) in enumerate(zip(ref, rtl)):
        if len(a) != dims or len(b) != dims:
            raise SystemExit(f"row {i} width mismatch")

    bit_err = 0
    bit_tot = 0
    vec_mismatch = 0
    max_abs_err = 0
    sum_abs_err = 0

    for a, b in zip(ref, rtl):
        mismatch = False
        for av, bv in zip(a, b):
            ua = to_u(av, args.bits)
            ub = to_u(bv, args.bits)
            bit_err += popcount(ua ^ ub)
            bit_tot += args.bits
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
    mae = sum_abs_err / (vec_total * dims)

    print(f"rows={vec_total} dims={dims} bits={args.bits}")
    print(f"bit_errors={bit_err} bit_total={bit_tot} BER={ber:.6e}")
    print(f"vector_mismatch={vec_mismatch}/{vec_total} ratio={vec_mismatch_ratio:.6e}")
    print(f"MAE={mae:.6f} max_abs_err={max_abs_err}")


if __name__ == "__main__":
    main()
