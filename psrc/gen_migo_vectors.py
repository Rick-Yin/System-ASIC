#!/usr/bin/env python3
"""Generate deterministic MIGO input and golden output vectors."""

from __future__ import annotations

import argparse
from pathlib import Path

from migo_ref import current_migo_coeffs, default_migo_samples, migo_reference, write_int_vector, write_meta


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate deterministic vectors for MIGO RTL validation.")
    parser.add_argument("--out-dir", type=Path, required=True, help="Output directory for input/golden vectors.")
    parser.add_argument("--frames", type=int, default=512, help="Number of valid input samples.")
    parser.add_argument("--seed", type=int, default=1, help="Seed for the deterministic random tail.")
    args = parser.parse_args()

    coeffs = current_migo_coeffs()
    inputs = default_migo_samples(num_samples=args.frames, seed=args.seed)
    golden = migo_reference(inputs, coeffs=coeffs)

    out_dir = args.out_dir
    write_int_vector(out_dir / "input_samples.vec", inputs)
    write_int_vector(out_dir / "golden_output.vec", golden)
    write_meta(out_dir / "meta_migo.json", num_samples=args.frames, seed=args.seed, coeffs=coeffs)

    print(f"frames={args.frames}")
    print(f"seed={args.seed}")
    print(f"input={out_dir / 'input_samples.vec'}")
    print(f"golden={out_dir / 'golden_output.vec'}")
    print(f"meta={out_dir / 'meta_migo.json'}")


if __name__ == "__main__":
    main()
