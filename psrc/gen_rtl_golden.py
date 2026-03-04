#!/usr/bin/env python3
"""Generate integer golden vectors for RWKVCNN RTL functional verification.

This script emulates the arithmetic flow in `vsrc/Joint-CFR-DPD/top/rwkvcnn_top.sv`
using tensor payload from `vsrc/rom/manifest.json` + `vsrc/rom/bin/*.bin`.

Outputs:
  - input CSV (integer vectors, IO input domain)
  - golden CSV (integer vectors, IO output domain)
"""

from __future__ import annotations

import argparse
import csv
import json
import random
import struct
from pathlib import Path
from typing import Dict, List, Sequence, Tuple


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


def qmax_unsigned(bits: int) -> int:
    if bits <= 0:
        return 0
    if bits >= 63:
        return 0x7FFF_FFFF_FFFF_FFFF
    return (1 << bits) - 1


def sat_signed32(x: int, bits: int) -> int:
    lo = qmin_signed(bits)
    hi = qmax_signed(bits)
    if x > hi:
        return int(hi)
    if x < lo:
        return int(lo)
    return int(x)


def sat_signed64(x: int, bits: int) -> int:
    lo = qmin_signed(bits)
    hi = qmax_signed(bits)
    if x > hi:
        return int(hi)
    if x < lo:
        return int(lo)
    return int(x)


def sat_unsigned64(x: int, bits: int) -> int:
    hi = qmax_unsigned(bits)
    if x < 0:
        return 0
    if x > hi:
        return int(hi)
    return int(x)


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


def requant_pow2_signed(x: int, exp_in: int, exp_out: int, bits: int) -> int:
    delta = int(exp_in) - int(exp_out)
    if delta > 0:
        if delta >= 62:
            y = qmin_signed(bits) if x < 0 else qmax_signed(bits)
        else:
            y = int(x) << delta
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
    cmax = qmax_unsigned(int(gate_bits))
    if y < 0:
        return 0
    if y > cmax:
        return int(cmax)
    return int(y)


def parse_model_dims(tensors: List[Dict]) -> Dict[str, int]:
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


def read_int32_le(path: Path, numel: int) -> List[int]:
    raw = path.read_bytes()
    expect = int(numel) * 4
    if len(raw) != expect:
        raise ValueError(f"{path} size mismatch: got {len(raw)} bytes, expect {expect}")
    return list(struct.unpack("<" + "i" * int(numel), raw))


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


def save_csv_int(path: Path, rows: Sequence[Sequence[int]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        for row in rows:
            writer.writerow([int(v) for v in row])


class RTLGoldenModel:
    def __init__(self, manifest: Dict, tensor_vals: Dict[str, List[int]], tensor_meta: Dict[str, Dict]):
        self.manifest = manifest
        self.tensor_vals = tensor_vals
        self.tensor_meta = tensor_meta

        dims = parse_model_dims(manifest["tensors"])
        self.in_dim = int(dims["IN_DIM"])
        self.model_dim = int(dims["MODEL_DIM"])
        self.layer_num = int(dims["LAYER_NUM"])
        self.out_dim = int(dims["OUT_DIM"])
        self.kernel_size = int(dims["KERNEL_SIZE"])
        self.hidden_sz = int(dims["HIDDEN_SZ"])

        int_ctx = manifest.get("int_ctx", {})
        att_cfg = int_ctx.get("att_cfg", {})
        io = manifest.get("io", {})
        self.res_exp = int(int_ctx.get("res_exp", -6))
        self.res_bits = int(int_ctx.get("res_bits", 8))
        self.gate_bits = int(int_ctx.get("gate_bits", 8))
        self.k_bits = int(att_cfg.get("k_bits", 8))
        self.v_bits = int(att_cfg.get("v_bits", 8))
        self.r_bits = int(att_cfg.get("r_bits", 8))
        self.exp_v = int(att_cfg.get("exp_v", -7))
        self.exp_r = int(att_cfg.get("exp_r", -7))
        self.exp_mul = int(att_cfg.get("exp_mul", -6))
        self.mul_bits = int(att_cfg.get("mul_bits", 8))
        self.p_bits = int(att_cfg.get("p_bits", 16))
        self.a_bits = int(att_cfg.get("a_bits", 24))
        self.b_bits = int(att_cfg.get("b_bits", 24))
        self.io_exp_in = int(io.get("exp_in", -11))
        self.io_exp_out = int(io.get("exp_out", -11))
        self.io_in_bits = int(io.get("in_bits", 12))
        self.io_out_bits = int(io.get("out_bits", 12))

        self.pp_init = -(1 << (self.p_bits - 1))

        self.input_proj_w = self._vals("input_proj.w")
        self.input_proj_b = self._vals("input_proj.b")
        self.output_proj_w = self._vals("output_proj.w")
        self.output_proj_b = self._vals("output_proj.b")
        self.wkv_lut = self._vals("wkv_lut")
        self.wkv_min_delta_i = self._scalar("wkv_min_delta_i")
        self.wkv_step_i = self._scalar("wkv_step_i")
        self.wkv_e_frac = self._scalar("wkv_e_frac")
        self.wkv_log_exp = self._scalar("wkv_log_exp")

        self.reset_state()

    def reset_state(self) -> None:
        self.att_hist = [
            [[0 for _ in range(self.kernel_size)] for _ in range(self.model_dim)]
            for _ in range(self.layer_num)
        ]
        self.ffn_hist = [
            [[0 for _ in range(self.kernel_size)] for _ in range(self.model_dim)]
            for _ in range(self.layer_num)
        ]
        self.pp_state = [[self.pp_init for _ in range(self.model_dim)] for _ in range(self.layer_num)]
        self.aa_state = [[0 for _ in range(self.model_dim)] for _ in range(self.layer_num)]
        self.bb_state = [[0 for _ in range(self.model_dim)] for _ in range(self.layer_num)]

    def _vals(self, name: str) -> List[int]:
        if name not in self.tensor_vals:
            raise KeyError(f"tensor not found in manifest/bin: {name}")
        return self.tensor_vals[name]

    def _meta(self, name: str) -> Dict:
        if name not in self.tensor_meta:
            raise KeyError(f"tensor meta not found: {name}")
        return self.tensor_meta[name]

    def _exp(self, name: str) -> int:
        return int(self._meta(name)["exp"])

    def _scalar(self, name: str) -> int:
        vals = self._vals(name)
        if len(vals) != 1:
            raise ValueError(f"{name} is not scalar, numel={len(vals)}")
        return int(vals[0])

    def _lut_lookup(self, delta_i: int) -> int:
        num = int(delta_i) - int(self.wkv_min_delta_i)
        if int(self.wkv_step_i) == 0:
            idx = 0
        else:
            idx = div_rne64(num, int(self.wkv_step_i))
        if idx < 0:
            idx = 0
        elif idx >= len(self.wkv_lut):
            idx = len(self.wkv_lut) - 1
        return int(self.wkv_lut[idx])

    def _ts_w(self, blk: int, c: int, k: int, phase: str) -> int:
        name = f"blocks.{blk}.{phase}.time_shift.w"
        vals = self._vals(name)
        return int(vals[c * self.kernel_size + k])

    def _ts_b(self, blk: int, c: int, phase: str) -> int:
        name = f"blocks.{blk}.{phase}.time_shift.b"
        vals = self._vals(name)
        return int(vals[c])

    def _ts_w_exp(self, blk: int, phase: str) -> int:
        return self._exp(f"blocks.{blk}.{phase}.time_shift.w")

    def _ts_b_exp(self, blk: int, phase: str) -> int:
        return self._exp(f"blocks.{blk}.{phase}.time_shift.b")

    def _tm(self, blk: int, c: int, which: str, phase: str) -> int:
        vals = self._vals(f"blocks.{blk}.{phase}.time_mix_{which}")
        return int(vals[c])

    def _tm_one(self, blk: int, phase: str) -> int:
        return int(self._vals(f"blocks.{blk}.{phase}.one_tm")[0])

    def _tm_exp(self, blk: int, phase: str) -> int:
        return self._exp(f"blocks.{blk}.{phase}.time_mix_k")

    def _linear_w(self, blk: int, phase: str, which: str, o: int, i: int) -> int:
        vals = self._vals(f"blocks.{blk}.{phase}.{which}.w")
        if phase == "ffn" and which == "value":
            idx = o * self.hidden_sz + i
        else:
            idx = o * self.model_dim + i
        return int(vals[idx])

    def _linear_exp(self, blk: int, phase: str, which: str) -> int:
        return self._exp(f"blocks.{blk}.{phase}.{which}.w")

    def _att_time_first(self, blk: int, c: int) -> int:
        return int(self._vals(f"blocks.{blk}.att.time_first")[c])

    def _att_time_decay(self, blk: int, c: int) -> int:
        return int(self._vals(f"blocks.{blk}.att.time_decay_wexp")[c])

    def _run_ip(self, in_vec: Sequence[int]) -> List[int]:
        wexp = self._exp("input_proj.w")
        bexp = self._exp("input_proj.b")
        out = [0 for _ in range(self.model_dim)]
        for o in range(self.model_dim):
            acc = 0
            for i in range(self.in_dim):
                acc += int(in_vec[i]) * int(self.input_proj_w[o * self.in_dim + i])
            exp_acc = self.io_exp_in + wexp
            b_aligned = requant_pow2_signed(int(self.input_proj_b[o]), bexp, exp_acc, 32)
            acc += b_aligned
            out[o] = requant_pow2_signed(acc, exp_acc, self.res_exp, self.res_bits)
        return out

    def _run_att(self, blk: int, work_vec: List[int]) -> List[int]:
        x_base = list(work_vec)
        xx = [0 for _ in range(self.model_dim)]
        xk = [0 for _ in range(self.model_dim)]
        xv = [0 for _ in range(self.model_dim)]
        xr = [0 for _ in range(self.model_dim)]
        k_att = [0 for _ in range(self.model_dim)]
        v_att = [0 for _ in range(self.model_dim)]
        r_att = [0 for _ in range(self.model_dim)]
        gate_att = [0 for _ in range(self.model_dim)]
        y_wkv = [0 for _ in range(self.model_dim)]
        mul_att = [0 for _ in range(self.model_dim)]
        att_out = [0 for _ in range(self.model_dim)]

        ts_w_exp = self._ts_w_exp(blk, "att")
        ts_b_exp = self._ts_b_exp(blk, "att")
        for c in range(self.model_dim):
            acc = 0
            for k in range(self.kernel_size):
                acc += int(self.att_hist[blk][c][k]) * self._ts_w(blk, c, k, "att")
            exp_acc = self.res_exp + ts_w_exp
            b_aligned = requant_pow2_signed(self._ts_b(blk, c, "att"), ts_b_exp, exp_acc, 32)
            acc += b_aligned
            xx[c] = requant_pow2_signed(acc, exp_acc, self.res_exp, self.res_bits)

        one_tm = self._tm_one(blk, "att")
        tm_exp = self._tm_exp(blk, "att")
        for c in range(self.model_dim):
            tmv = self._tm(blk, c, "k", "att")
            prod = int(work_vec[c]) * tmv + int(xx[c]) * int(one_tm - tmv)
            xk[c] = sat_signed32(rshift_rne64(prod, -tm_exp), self.res_bits)

            tmv = self._tm(blk, c, "v", "att")
            prod = int(work_vec[c]) * tmv + int(xx[c]) * int(one_tm - tmv)
            xv[c] = sat_signed32(rshift_rne64(prod, -tm_exp), self.res_bits)

            tmv = self._tm(blk, c, "r", "att")
            prod = int(work_vec[c]) * tmv + int(xx[c]) * int(one_tm - tmv)
            xr[c] = sat_signed32(rshift_rne64(prod, -tm_exp), self.res_bits)

        key_exp = self._linear_exp(blk, "att", "key")
        value_exp = self._linear_exp(blk, "att", "value")
        recep_exp = self._linear_exp(blk, "att", "receptance")
        out_exp = self._linear_exp(blk, "att", "output")
        for o in range(self.model_dim):
            acc = 0
            for i in range(self.model_dim):
                acc += int(xk[i]) * self._linear_w(blk, "att", "key", o, i)
            k_att[o] = requant_pow2_signed(acc, self.res_exp + key_exp, self.wkv_log_exp, self.k_bits)

            acc = 0
            for i in range(self.model_dim):
                acc += int(xv[i]) * self._linear_w(blk, "att", "value", o, i)
            v_att[o] = requant_pow2_signed(acc, self.res_exp + value_exp, self.exp_v, self.v_bits)

            acc = 0
            for i in range(self.model_dim):
                acc += int(xr[i]) * self._linear_w(blk, "att", "receptance", o, i)
            r_att[o] = requant_pow2_signed(acc, self.res_exp + recep_exp, self.exp_r, self.r_bits)
            gate_att[o] = hardsigmoid_int_default(r_att[o], self.exp_r, self.gate_bits)

        for c in range(self.model_dim):
            uu = self._att_time_first(blk, c)
            wd = self._att_time_decay(blk, c)

            ww = int(k_att[c]) + int(uu)
            p = self.pp_state[blk][c] if self.pp_state[blk][c] > ww else ww

            e1 = self._lut_lookup(self.pp_state[blk][c] - p)
            e2 = self._lut_lookup(ww - p)

            aa = int(self.aa_state[blk][c])
            bb = int(self.bb_state[blk][c])

            t1 = rshift_rne64(aa * int(e1), int(self.wkv_e_frac))
            t2 = int(v_att[c]) * int(e2)
            aa = sat_signed64(t1 + t2, self.a_bits)

            t1 = rshift_rne64(bb * int(e1), int(self.wkv_e_frac))
            t2 = int(e2)
            bb = int(sat_unsigned64(t1 + t2, self.b_bits))

            bb_safe = 1 if bb <= 0 else bb
            yi = div_rne64(aa, bb_safe)
            y_wkv[c] = int(yi)

            ww2 = int(self.pp_state[blk][c]) + int(wd)
            p2 = ww2 if ww2 > int(k_att[c]) else int(k_att[c])

            e1n = self._lut_lookup(ww2 - p2)
            e2n = self._lut_lookup(int(k_att[c]) - p2)

            t1 = rshift_rne64(aa * int(e1n), int(self.wkv_e_frac))
            t2 = int(v_att[c]) * int(e2n)
            aa = sat_signed64(t1 + t2, self.a_bits)

            t1 = rshift_rne64(bb * int(e1n), int(self.wkv_e_frac))
            t2 = int(e2n)
            bb = int(sat_unsigned64(t1 + t2, self.b_bits))

            self.pp_state[blk][c] = int(p2)
            self.aa_state[blk][c] = int(aa)
            self.bb_state[blk][c] = int(bb)

        for c in range(self.model_dim):
            prod = int(y_wkv[c]) * int(gate_att[c])
            mul_att[c] = requant_pow2_signed(prod, self.exp_v - self.gate_bits, self.exp_mul, self.mul_bits)

        for o in range(self.model_dim):
            acc = 0
            for i in range(self.model_dim):
                acc += int(mul_att[i]) * self._linear_w(blk, "att", "output", o, i)
            att_out[o] = requant_pow2_signed(acc, self.exp_mul + out_exp, self.res_exp, self.res_bits)
            work_vec[o] = sat_signed32(int(work_vec[o]) + int(att_out[o]), self.res_bits)

        for c in range(self.model_dim):
            for k in range(self.kernel_size - 1):
                self.att_hist[blk][c][k] = int(self.att_hist[blk][c][k + 1])
            self.att_hist[blk][c][self.kernel_size - 1] = int(x_base[c])

        return work_vec

    def _run_ffn(self, blk: int, work_vec: List[int]) -> List[int]:
        x_base = list(work_vec)
        xx = [0 for _ in range(self.model_dim)]
        xk = [0 for _ in range(self.model_dim)]
        xr = [0 for _ in range(self.model_dim)]
        k_ffn = [0 for _ in range(self.hidden_sz)]
        k_sq = [0 for _ in range(self.hidden_sz)]
        kv_ffn = [0 for _ in range(self.model_dim)]
        gate_in = [0 for _ in range(self.model_dim)]
        gate = [0 for _ in range(self.model_dim)]
        ffn_out = [0 for _ in range(self.model_dim)]

        ts_w_exp = self._ts_w_exp(blk, "ffn")
        ts_b_exp = self._ts_b_exp(blk, "ffn")
        for c in range(self.model_dim):
            acc = 0
            for k in range(self.kernel_size):
                acc += int(self.ffn_hist[blk][c][k]) * self._ts_w(blk, c, k, "ffn")
            exp_acc = self.res_exp + ts_w_exp
            b_aligned = requant_pow2_signed(self._ts_b(blk, c, "ffn"), ts_b_exp, exp_acc, 32)
            acc += b_aligned
            xx[c] = requant_pow2_signed(acc, exp_acc, self.res_exp, self.res_bits)

        one_tm = self._tm_one(blk, "ffn")
        tm_exp = self._tm_exp(blk, "ffn")
        for c in range(self.model_dim):
            tmv = self._tm(blk, c, "k", "ffn")
            prod = int(work_vec[c]) * tmv + int(xx[c]) * int(one_tm - tmv)
            xk[c] = sat_signed32(rshift_rne64(prod, -tm_exp), self.res_bits)

            tmv = self._tm(blk, c, "r", "ffn")
            prod = int(work_vec[c]) * tmv + int(xx[c]) * int(one_tm - tmv)
            xr[c] = sat_signed32(rshift_rne64(prod, -tm_exp), self.res_bits)

        key_exp = self._linear_exp(blk, "ffn", "key")
        value_exp = self._linear_exp(blk, "ffn", "value")
        recep_exp = self._linear_exp(blk, "ffn", "receptance")
        qmax_res = qmax_signed(self.res_bits)
        for o in range(self.hidden_sz):
            acc = 0
            for i in range(self.model_dim):
                acc += int(xk[i]) * self._linear_w(blk, "ffn", "key", o, i)
            k_ffn[o] = requant_pow2_signed(acc, self.res_exp + key_exp, self.res_exp, self.res_bits)

            if k_ffn[o] < 0:
                k_ffn[o] = 0
            elif k_ffn[o] > qmax_res:
                k_ffn[o] = int(qmax_res)

            prod = int(k_ffn[o]) * int(k_ffn[o])
            k_sq[o] = requant_pow2_signed(prod, self.res_exp + self.res_exp, self.res_exp, self.res_bits)

        for o in range(self.model_dim):
            acc = 0
            for i in range(self.hidden_sz):
                acc += int(k_sq[i]) * self._linear_w(blk, "ffn", "value", o, i)
            kv_ffn[o] = requant_pow2_signed(acc, self.res_exp + value_exp, self.res_exp, self.res_bits)

            acc = 0
            for i in range(self.model_dim):
                acc += int(xr[i]) * self._linear_w(blk, "ffn", "receptance", o, i)
            gate_in[o] = requant_pow2_signed(acc, self.res_exp + recep_exp, self.res_exp, self.res_bits)
            gate[o] = hardsigmoid_int_default(gate_in[o], self.res_exp, self.gate_bits)

            prod = int(kv_ffn[o]) * int(gate[o])
            ffn_out[o] = requant_pow2_signed(prod, self.res_exp - self.gate_bits, self.res_exp, self.res_bits)
            work_vec[o] = sat_signed32(int(work_vec[o]) + int(ffn_out[o]), self.res_bits)

        for c in range(self.model_dim):
            for k in range(self.kernel_size - 1):
                self.ffn_hist[blk][c][k] = int(self.ffn_hist[blk][c][k + 1])
            self.ffn_hist[blk][c][self.kernel_size - 1] = int(x_base[c])

        return work_vec

    def _run_op(self, work_vec: Sequence[int]) -> List[int]:
        wexp = self._exp("output_proj.w")
        bexp = self._exp("output_proj.b")
        out = [0 for _ in range(self.out_dim)]
        for o in range(self.out_dim):
            acc = 0
            for i in range(self.model_dim):
                acc += int(work_vec[i]) * int(self.output_proj_w[o * self.model_dim + i])
            exp_acc = self.res_exp + wexp
            b_aligned = requant_pow2_signed(int(self.output_proj_b[o]), bexp, exp_acc, 32)
            acc += b_aligned
            out[o] = requant_pow2_signed(acc, exp_acc, self.io_exp_out, self.io_out_bits)
        return out

    def step(self, in_vec: Sequence[int]) -> List[int]:
        if len(in_vec) != self.in_dim:
            raise ValueError(f"input width mismatch: got {len(in_vec)} expect {self.in_dim}")
        work_vec = self._run_ip(in_vec)
        for blk in range(self.layer_num):
            work_vec = self._run_att(blk, work_vec)
            work_vec = self._run_ffn(blk, work_vec)
        out = self._run_op(work_vec)
        return out


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


def main() -> None:
    ap = argparse.ArgumentParser(description="Generate integer golden vectors from RWKV ROM manifest/bin")
    ap.add_argument("--manifest", type=Path, default=Path("vsrc/rom/manifest.json"))
    ap.add_argument("--bin-dir", type=Path, default=Path("vsrc/rom/bin"))
    ap.add_argument("--input-csv", type=Path, default=None, help="Optional existing input CSV to replay")
    ap.add_argument("--output-input-csv", type=Path, default=Path("vsrc/rom/golden/input_vectors.csv"))
    ap.add_argument("--output-golden-csv", type=Path, default=Path("vsrc/rom/golden/golden_output.csv"))
    ap.add_argument("--frames", type=int, default=256, help="Used when --input-csv is not provided")
    ap.add_argument("--mode", choices=["random", "edge"], default="random")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--stateless", action="store_true", help="Reset internal state before each frame")
    args = ap.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    tensors = manifest["tensors"]
    tensor_meta = {t["name"]: t for t in tensors}
    tensor_vals: Dict[str, List[int]] = {}
    for t in tensors:
        tensor_vals[t["name"]] = read_int32_le(args.bin_dir / t["bin_file"], int(t["numel"]))

    model = RTLGoldenModel(manifest, tensor_vals, tensor_meta)

    if args.input_csv is not None:
        in_rows = load_csv_int(args.input_csv)
        if len(in_rows) == 0:
            raise SystemExit(f"empty input csv: {args.input_csv}")
        for i, row in enumerate(in_rows):
            if len(row) != model.in_dim:
                raise SystemExit(f"input row {i} width mismatch: got {len(row)} expect {model.in_dim}")
    else:
        in_rows = build_input_rows(args.mode, int(args.frames), model.in_dim, model.io_in_bits, int(args.seed))

    out_rows: List[List[int]] = []
    if args.stateless:
        for row in in_rows:
            model.reset_state()
            out_rows.append(model.step(row))
    else:
        model.reset_state()
        for row in in_rows:
            out_rows.append(model.step(row))

    save_csv_int(args.output_input_csv, in_rows)
    save_csv_int(args.output_golden_csv, out_rows)

    print(f"[OK] inputs : {args.output_input_csv}  rows={len(in_rows)} dim={model.in_dim}")
    print(f"[OK] golden : {args.output_golden_csv}  rows={len(out_rows)} dim={model.out_dim}")
    print(f"[INFO] mode={args.mode} seed={args.seed} stateless={args.stateless}")
    print(
        f"[INFO] domains: in_bits={model.io_in_bits} in_exp={model.io_exp_in}, "
        f"out_bits={model.io_out_bits} out_exp={model.io_exp_out}"
    )


if __name__ == "__main__":
    main()
