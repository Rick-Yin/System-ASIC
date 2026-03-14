#!/usr/bin/env python3
"""Reference helpers for the current MIGO RTL implementation."""

from __future__ import annotations

import json
import random
from pathlib import Path
from typing import Iterable


CURRENT_N = 161
CURRENT_BX = 8
CURRENT_BY = 9
CURRENT_SHIFT = 8
CURRENT_ROUND = True


def swrap(value: int, bits: int) -> int:
    """Wrap an integer to a signed fixed-width two's-complement value."""
    mask = (1 << bits) - 1
    value &= mask
    if value & (1 << (bits - 1)):
        value -= 1 << bits
    return value


def current_migo_coeffs() -> list[int]:
    """Return the effective FIR tap coefficients implemented by the current RTL."""
    coeffs = [0] * CURRENT_N
    base = {
        52: -1,
        53: -2,
        54: -2,
        55: -2,
        56: -1,
        57: -2,
        58: -2,
        59: -1,
        68: 2,
        69: 5,
        70: 6,
        71: 8,
        72: 9,
        73: 11,
        74: 13,
        75: 14,
        76: 15,
        77: 16,
        78: 16,
        79: 17,
        80: 11,
    }
    for idx, coeff in base.items():
        coeffs[idx] = coeff
        if idx < CURRENT_N // 2:
            coeffs[CURRENT_N - 1 - idx] = coeff
    return coeffs


def default_migo_samples(num_samples: int = 512, seed: int = 1) -> list[int]:
    """Build a deterministic stimulus set with the same structure as the RTL testbench."""
    rng = random.Random(seed)
    samples: list[int] = []
    for idx in range(num_samples):
        if idx == 0:
            sample = 64
        elif idx < 48:
            sample = 0
        elif idx < 160:
            sample = -128 if (idx & 1) else 127
        elif idx < 256:
            sample = idx - 208
        else:
            sample = rng.randint(-128, 127)
        samples.append(swrap(sample, CURRENT_BX))
    return samples


def migo_reference(
    samples: Iterable[int],
    coeffs: Iterable[int] | None = None,
    bx: int = CURRENT_BX,
    by: int = CURRENT_BY,
    shift: int = CURRENT_SHIFT,
    round_en: bool = CURRENT_ROUND,
) -> list[int]:
    """Run the current MIGO filter in Python with RTL-matching fixed-point behavior."""
    tap_coeffs = list(current_migo_coeffs() if coeffs is None else coeffs)
    if len(tap_coeffs) != CURRENT_N:
        raise ValueError(f"expected {CURRENT_N} coefficients, got {len(tap_coeffs)}")

    delay = [0] * CURRENT_N
    outputs: list[int] = []

    for sample in samples:
        x_in = swrap(int(sample), bx)
        delay = [x_in] + delay[:-1]

        acc = 0
        for coeff, tap in zip(tap_coeffs, delay):
            acc += coeff * tap

        if round_en and shift > 0:
            acc = (acc + (1 << (shift - 1))) >> shift
        else:
            acc >>= shift

        outputs.append(swrap(acc, by))

    return outputs


def write_int_vector(path: Path, values: Iterable[int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        for value in values:
            f.write(f"{int(value)}\n")


def read_int_vector(path: Path) -> list[int]:
    rows: list[int] = []
    with path.open("r", encoding="utf-8") as f:
        for lineno, line in enumerate(f, start=1):
            text = line.strip()
            if not text:
                continue
            try:
                rows.append(int(text, 10))
            except ValueError as exc:
                raise ValueError(f"malformed integer in {path}:{lineno}: {text}") from exc
    return rows


def write_meta(path: Path, *, num_samples: int, seed: int, coeffs: Iterable[int]) -> None:
    meta = {
        "generator": "psrc/migo_ref.py",
        "num_samples": int(num_samples),
        "seed": int(seed),
        "bx": CURRENT_BX,
        "by": CURRENT_BY,
        "shift": CURRENT_SHIFT,
        "round": int(CURRENT_ROUND),
        "coeffs": list(coeffs),
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(meta, indent=2), encoding="utf-8")
