#!/usr/bin/env python3
"""Convenience wrapper to generate golden vectors from RWKVCNN_Quan forward_int."""

from pathlib import Path
import subprocess
import sys


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    cmd = [sys.executable, str(root / "psrc" / "gen_golden_from_rwkv_quan.py")]
    return subprocess.call(cmd, cwd=str(root))


if __name__ == "__main__":
    raise SystemExit(main())
