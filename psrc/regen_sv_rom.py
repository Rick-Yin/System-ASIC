#!/usr/bin/env python3
"""Convenience wrapper to regenerate SV ROM/package artifacts."""

from pathlib import Path
import subprocess
import sys


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    cmd = [sys.executable, str(root / "psrc" / "tools" / "gen_rwkv_sv_rom.py")]
    return subprocess.call(cmd, cwd=str(root))


if __name__ == "__main__":
    raise SystemExit(main())
