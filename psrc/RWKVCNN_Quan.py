import math
import os
import difflib
from typing import Any, Dict, Optional, Tuple, List, Union

import torch
import torch.nn as nn
from torch.nn import functional as F
import weakref
try:
    from trainers import FIXED_RULES
    from utils import _qmax_signed, _qmin_signed, _qmax_unsigned, choose_pow2_exp
except ImportError:
    # add path to import from ../../trainers/quantize_helper.py
    import sys
    current_dir = os.path.dirname(os.path.abspath(__file__))
    proj_dir = os.path.dirname(os.path.dirname(current_dir))
    if proj_dir not in sys.path:
        sys.path.append(proj_dir)
    from trainers import FIXED_RULES
    from utils import _qmax_signed, _qmin_signed, _qmax_unsigned, choose_pow2_exp

from torch.utils.cpp_extension import load as _torch_ext_load

T_MAX = 1024
code_dir = os.path.dirname(os.path.abspath(__file__))
wkv_op_path = os.path.join(code_dir, 'cuda', 'wkv_op_quan.cpp')
wkv_cuda_path = os.path.join(code_dir, 'cuda', 'wkv_cuda.cu')
_wkv_cuda = None
DEBUG = False


def get_wkv_cuda():
    global _wkv_cuda
    if _wkv_cuda is None:
        _wkv_cuda = _torch_ext_load(
            name=f"wkv_quan_Tmax{T_MAX}",
            sources=[wkv_op_path, wkv_cuda_path],
            verbose=DEBUG,
            extra_cuda_cflags=[
                '--maxrregcount', '60', '--use_fast_math', '-O3',
                '-Xptxas', '-O3', f'-DTmax={T_MAX}',
            ],
        )
    return _wkv_cuda


class WKV_Quan(torch.autograd.Function):
    @staticmethod
    def forward(ctx, B, T, C, w, u, k, v, preexp_w: bool = False):
        ctx.B = B
        ctx.T = T
        ctx.C = C
        ctx.preexp_w = preexp_w

        assert T <= T_MAX
        assert B * C % min(C, 1024) == 0

        if preexp_w:
            w = w.float().contiguous()
        else:
            w = -torch.exp(w.float().contiguous())

        u = u.float().contiguous()
        k = k.float().contiguous()
        v = v.float().contiguous()

        ctx.save_for_backward(w, u, k, v)
        dev = k.device
        y = torch.empty((B, T, C), device=dev, memory_format=torch.contiguous_format)
        wkv = get_wkv_cuda()
        wkv.forward(B, T, C, w, u, k, v, y)
        return y

    @staticmethod
    def backward(ctx, gy):
        B = ctx.B
        T = ctx.T
        C = ctx.C
        w, u, k, v = ctx.saved_tensors

        wkv = get_wkv_cuda()

        dev = gy.device
        gw = torch.zeros((B, C), device=dev).contiguous()
        gu = torch.zeros((B, C), device=dev).contiguous()
        gk = torch.zeros((B, T, C), device=dev).contiguous()
        gv = torch.zeros((B, T, C), device=dev).contiguous()

        wkv.backward(B, T, C, w, u, k, v, gy.float().contiguous(), gw, gu, gk, gv)

        gw = torch.sum(gw, dim=0)
        gu = torch.sum(gu, dim=0)

        if getattr(ctx, "preexp_w", False):
            gw = None

        return (None, None, None, gw, gu, gk, gv, None)


def RUN_CUDA(B, T, C, w, u, k, v, preexp_w: bool = False):
    dev = k.device
    return WKV_Quan.apply(B, T, C, w.to(dev), u.to(dev), k.to(dev), v.to(dev), preexp_w)


def rshift_rne(x: torch.Tensor, sh: int) -> torch.Tensor:
    sh = int(sh)
    if sh <= 0:
        return x

    if sh >= FIXED_RULES["max_rshift"]:
        return torch.zeros_like(x)

    x64 = x.to(torch.int64)
    sign = x64.sign()
    ax = x64.abs()

    half = 1 << (sh - 1)
    mask = (1 << sh) - 1

    r = ax & mask
    q = ax >> sh

    inc = (r > half) | ((r == half) & ((q & 1) == 1))
    q2 = q + inc.to(torch.int64)
    out = q2 * sign
    return out.to(x.dtype)


def div_rne(x: torch.Tensor, d: Union[int, torch.Tensor]) -> torch.Tensor:
    x64 = x.to(torch.int64)
    sign = x64.sign()
    ax = x64.abs()
    if isinstance(d, int):
        if d <= 0:
            raise ValueError("d must be > 0")
        d64 = d
    else:
        d64 = d.to(dtype=torch.int64, device=ax.device)
    q = ax // d64
    r = ax - q * d64
    two_r = r * 2
    inc = (two_r > d64) | ((two_r == d64) & ((q & 1) == 1))
    return ((q + inc.to(torch.int64)) * sign).to(x.dtype)


def sat_signed(x: torch.Tensor, bits: int) -> torch.Tensor:
    lo = _qmin_signed(bits)
    hi = _qmax_signed(bits)
    return torch.clamp(x, lo, hi)


def sat_unsigned(x: torch.Tensor, bits: int) -> torch.Tensor:
    lo = 0
    hi = _qmax_unsigned(bits)
    return torch.clamp(x, lo, hi)


def quantize_pow2(x: torch.Tensor, bits: int, exp: int, signed: bool = True) -> torch.Tensor:
    scale = float(2.0 ** exp)
    q = torch.round(x / scale)
    q = q.to(torch.int64)
    if signed:
        q = sat_signed(q, bits)
    else:
        q = sat_unsigned(q, bits)
    return q.to(torch.int32)


def dequantize_pow2(q: torch.Tensor, exp: int) -> torch.Tensor:
    return q.to(torch.float32) * float(2.0 ** exp)


def requant_pow2(q: torch.Tensor, exp_in: int, exp_out: int, bits: int, signed: bool = True) -> torch.Tensor:
    if exp_in == exp_out:
        out = q.to(torch.int64)
    else:
        delta = exp_in - exp_out
        x = q.to(torch.int64)
        if delta > 0:
            out = x << delta
        else:
            out = rshift_rne(x, -delta).to(torch.int64)
    if signed:
        out = sat_signed(out, bits)
    else:
        out = sat_unsigned(out, bits)
    return out.to(torch.int32)


class _StatBuf:
    def __init__(self, clip_method: str = "maxabs", percentile: float = 99.9, max_samples: int = 200000):
        self.clip_method = str(clip_method).lower()
        self.percentile = float(percentile)
        self.maxabs = 0.0
        self.samples: List[float] = []
        self.max_samples = int(max_samples)

    def update(self, x: torch.Tensor):
        xf = x.detach()
        xf = xf[torch.isfinite(xf)]
        if xf.numel() == 0:
            return
        a = xf.abs().flatten()
        m = float(a.max().item())
        if math.isfinite(m) and m > self.maxabs:
            self.maxabs = m
        if self.clip_method == "percentile" and len(self.samples) < self.max_samples:
            idx = torch.randint(0, a.numel(), (min(a.numel(), 4096),))
            remain = self.max_samples - len(self.samples)
            self.samples.extend(a.float().cpu()[idx].tolist()[:remain])

    def get_amax(self) -> float:
        if self.clip_method == "percentile" and len(self.samples) > 0:
            import numpy as np
            return float(np.quantile(np.asarray(self.samples, dtype=np.float32), self.percentile / 100.0))
        return float(self.maxabs)


class _WKVIntLUT:
    def __init__(self, lut: torch.Tensor, min_delta_i: int, step_i: int, e_frac: int):
        self.lut = lut.to(torch.int32)
        self.min_delta_i = int(min_delta_i)
        self.step_i = int(step_i)
        self.e_frac = int(e_frac)
        self.L = int(lut.numel())


def RUN_WKV_INT(
    w_i: torch.Tensor, u_i: torch.Tensor,
    k_i: torch.Tensor, v_i: torch.Tensor,
    lut: _WKVIntLUT,
    p_bits: int, a_bits: int, b_bits: int
) -> torch.Tensor:
    device = k_i.device

    B, T, C = k_i.shape
    e_frac = lut.e_frac

    pp = torch.full((B, C), _qmin_signed(p_bits), dtype=torch.int32, device=device)
    aa = torch.zeros((B, C), dtype=torch.int64, device=device)
    bb = torch.zeros((B, C), dtype=torch.int64, device=device)

    y = torch.empty((B, T, C), dtype=torch.int32, device=device)

    aa_lo = _qmin_signed(a_bits)
    aa_hi = _qmax_signed(a_bits)
    bb_lo = 0
    bb_hi = _qmax_unsigned(b_bits)

    lut_dev = lut.lut.to(device)

    for t in range(T):
        kk = k_i[:, t, :]
        vv = v_i[:, t, :]

        ww = (kk.to(torch.int64) + u_i.view(1, C).to(torch.int64)).to(torch.int32)
        p = torch.maximum(pp, ww)

        e1 = _lut_exp_uq(lut_dev, lut.min_delta_i, lut.step_i, lut.L, pp - p)
        e2 = _lut_exp_uq(lut_dev, lut.min_delta_i, lut.step_i, lut.L, ww - p)

        term1 = rshift_rne(aa * e1.to(torch.int64), e_frac).to(torch.int64)
        term2 = vv.to(torch.int64) * e2.to(torch.int64)
        aa = term1 + term2
        aa = torch.clamp(aa, aa_lo, aa_hi)

        term1b = rshift_rne(bb * e1.to(torch.int64), e_frac).to(torch.int64)
        term2b = e2.to(torch.int64)
        bb = term1b + term2b
        bb = torch.clamp(bb, bb_lo, bb_hi)

        bb_safe = torch.clamp(bb, 1, bb_hi)
        yi = div_rne(aa, bb_safe.to(torch.int64)).to(torch.int32)
        y[:, t, :] = yi

        ww2 = (pp.to(torch.int64) + w_i.view(1, C).to(torch.int64)).to(torch.int32)
        p2 = torch.maximum(ww2, kk)
        e1n = _lut_exp_uq(lut_dev, lut.min_delta_i, lut.step_i, lut.L, ww2 - p2)
        e2n = _lut_exp_uq(lut_dev, lut.min_delta_i, lut.step_i, lut.L, kk - p2)

        term1 = rshift_rne(aa * e1n.to(torch.int64), e_frac).to(torch.int64)
        term2 = vv.to(torch.int64) * e2n.to(torch.int64)
        aa = term1 + term2
        aa = torch.clamp(aa, aa_lo, aa_hi)

        term1b = rshift_rne(bb * e1n.to(torch.int64), e_frac).to(torch.int64)
        term2b = e2n.to(torch.int64)
        bb = term1b + term2b
        bb = torch.clamp(bb, bb_lo, bb_hi)

        pp = p2

    return y


def _lut_exp_uq(lut: torch.Tensor, min_delta_i: int, step_i: int, L: int, delta_i: torch.Tensor) -> torch.Tensor:
    di = delta_i.to(torch.int64)
    num = di - int(min_delta_i)
    if step_i <= 0:
        idx = torch.zeros_like(num)
    else:
        idx = div_rne(num, step_i).to(torch.int64)
    idx = torch.clamp(idx, 0, L - 1)
    return lut[idx].to(torch.int32)


def hardsigmoid_int(x_i: torch.Tensor, exp_x: int, gate_bits: int) -> Tuple[torch.Tensor, int]:
    exp_gate = -int(gate_bits)
    s = int(exp_x - exp_gate)
    xi = x_i.to(torch.int64) * FIXED_RULES["hs_slp_n"]
    if s > 0:
        x_scaled = xi << s
    elif s < 0:
        x_scaled = rshift_rne(xi, -s).to(torch.int64)
    else:
        x_scaled = xi
    div_term = div_rne(x_scaled, FIXED_RULES["hs_slp_d"]).to(torch.int64)
    offset = ((1 << gate_bits) * FIXED_RULES["hs_bia_n"]) // FIXED_RULES["hs_bia_d"]

    y = div_term + offset
    cmin = int(FIXED_RULES["hs_cmin"] * _qmax_unsigned(gate_bits))
    cmax = int(FIXED_RULES["hs_cmax"] * _qmax_unsigned(gate_bits))
    y = torch.clamp(y, cmin, cmax)
    return y.to(torch.int32), exp_gate


def RWKV_Init(model):
    for m in model.modules():
        if not isinstance(m, (nn.Linear, nn.Embedding)):
            continue
        ww = m.weight
        shape = ww.shape
        gain = 1.0
        if isinstance(m, nn.Linear):
            if shape[0] > shape[1]:
                gain = math.sqrt(shape[0] / shape[1])
            nn.init.orthogonal_(ww, gain=gain)
        if hasattr(m, 'bias') and m.bias is not None:
            nn.init.zeros_(m.bias)


class RWKV_TimeMix_Quan(nn.Module):
    def __init__(self, layer_num: int, in_dim: int, layer_id: int, kernel_size: int, use_hsigmoid: bool):
        super().__init__()
        self.layer_id = layer_id
        self.in_dim = in_dim
        self.kernel_size = kernel_size
        self.use_hsigmoid = use_hsigmoid

        self.deploy_mode = False
        self.preexp_w = False
        self.register_buffer("time_decay_w_exp", None, persistent=False)

        with torch.no_grad():
            ratio_0_to_1 = (layer_id / max(1, layer_num - 1))
            ratio_1_to_almost0 = (1.0 - (layer_id / layer_num))
            decay_speed = FIXED_RULES["tm_db"] + FIXED_RULES["tm_ds"] * torch.linspace(0, 1, in_dim) ** (FIXED_RULES["tm_pb"] + FIXED_RULES["tm_ps"] * ratio_0_to_1)
            decay_speed = torch.clamp(decay_speed, max=-0.1)
            zigzag = (torch.tensor([(i + 1) % 3 - 1 for i in range(in_dim)]) * FIXED_RULES["tm_zz"])
            x = torch.linspace(0, 1, in_dim).unsqueeze(0).unsqueeze(0)

        self.time_decay = nn.Parameter(decay_speed)
        self.time_first = nn.Parameter(torch.ones(self.in_dim) * math.log(FIXED_RULES["tm_lbase"]) + zigzag)

        self.time_mix_k = nn.Parameter(torch.pow(x, ratio_1_to_almost0))
        self.time_mix_v = nn.Parameter(torch.pow(x, ratio_1_to_almost0) + FIXED_RULES["tm_vadd"] * ratio_0_to_1)
        self.time_mix_r = nn.Parameter(torch.pow(x, FIXED_RULES["tm_rsc"] * ratio_1_to_almost0))

        self.time_shift = nn.Conv1d(
            in_channels=in_dim,
            out_channels=in_dim,
            kernel_size=kernel_size,
            stride=1,
            padding=0,
            bias=True,
            groups=in_dim
        )

        self.key = nn.Linear(self.in_dim, self.in_dim, bias=False)
        self.value = nn.Linear(self.in_dim, self.in_dim, bias=False)
        self.receptance = nn.Linear(self.in_dim, self.in_dim, bias=False)
        self.output = nn.Linear(self.in_dim, self.in_dim, bias=False)

        self.register_buffer("_int_time_mix_k", None, persistent=False)
        self.register_buffer("_int_time_mix_v", None, persistent=False)
        self.register_buffer("_int_time_mix_r", None, persistent=False)
        self.register_buffer("_int_time_mix_exp", None, persistent=False)
        self.register_buffer("_int_one_tm", None, persistent=False)

        self.register_buffer("_int_time_first", None, persistent=False)
        self.register_buffer("_int_time_decay_wexp", None, persistent=False)
        self.register_buffer("_int_log_exp", None, persistent=False)

    def set_deploy_mode(self, enable: bool = True, preexp_w: bool = True):
        self.deploy_mode = bool(enable)
        self.preexp_w = bool(preexp_w)
        if self.preexp_w:
            with torch.no_grad():
                td = self.time_decay.float().clamp(max=-0.01)
                self.time_decay_w_exp = -torch.exp(td)
        else:
            self.time_decay_w_exp = None

    def _record(self, tag: str, x: torch.Tensor):
        root = getattr(self, "_root", None)
        if root is not None and getattr(root, "_calib_enabled", False):
            root._calib_update(tag, x)

    def jit_func(self, x: torch.Tensor):
        xx = x.permute(0, 2, 1)
        pad = (self.kernel_size, -1)
        xx = F.pad(xx, pad)
        xx = self.time_shift(xx)
        xx = xx.permute(0, 2, 1)

        self._record("after_time_shift", xx)

        xk = x * self.time_mix_k + xx * (1 - self.time_mix_k)
        xv = x * self.time_mix_v + xx * (1 - self.time_mix_v)
        xr = x * self.time_mix_r + xx * (1 - self.time_mix_r)

        k = self.key(xk)
        v = self.value(xv)
        r = self.receptance(xr)

        self._record("after_kvr.k", k)
        self._record("after_kvr.v", v)
        self._record("after_kvr.r", r)

        if self.deploy_mode:
            sr = F.hardsigmoid(r)
        else:
            sr = F.hardsigmoid(r) if self.use_hsigmoid else torch.sigmoid(r)

        self._record("after_gate", sr)
        return sr, k, v

    def forward(self, x: torch.Tensor):
        B, T, C = x.size()
        sr, k, v = self.jit_func(x)

        if self.preexp_w and (self.time_decay_w_exp is not None):
            w = self.time_decay_w_exp
        else:
            w = self.time_decay

        rwkv = sr * RUN_CUDA(B, T, C, w, self.time_first, k, v, preexp_w=self.preexp_w)
        self._record("after_mul", rwkv)
        rwkv = self.output(rwkv)
        return rwkv

    def forward_int(
        self,
        x_i: torch.Tensor, exp_x: int, bits_x: int,
        res_exp: int, res_bits: int,
        cfg: Dict[str, Any],
        lut: _WKVIntLUT,
    ) -> torch.Tensor:
        x_i = x_i.to(torch.int32)
        B, T, C = x_i.shape
        device = x_i.device

        xx = x_i.permute(0, 2, 1)
        xx = F.pad(xx, (self.kernel_size, -1))
        w = self.time_shift._int_w
        wexp = int(self.time_shift._int_w_exp.item())
        wb = self.time_shift._int_b
        bexp = int(self.time_shift._int_b_exp.item()) if wb is not None else None

        K = self.kernel_size
        out = torch.zeros((B, C, T), dtype=torch.int64, device=device)
        for i in range(K):
            out += xx[:, :, i:i + T].to(torch.int64) * w[:, 0, i].view(1, C, 1).to(torch.int64)
        if wb is not None:
            b_aligned = requant_pow2(wb.view(1, C, 1).to(torch.int32), bexp, exp_x + wexp, 32, signed=True).to(torch.int64)
            out += b_aligned.to(torch.int64)
        xx_i = requant_pow2(out.to(torch.int32), exp_x + wexp, exp_x, bits_x, signed=True)
        xx_i = xx_i.permute(0, 2, 1)

        root = getattr(self, "_root", None)
        if root is not None and getattr(root, "_dump_enabled", False):
            root._dump_tensor("after_time_shift", xx_i, exp_x)

        tm_exp = int(self._int_time_mix_exp.item())
        one_tm = self._int_one_tm

        def _mix(xa: torch.Tensor, xb: torch.Tensor, tm: torch.Tensor) -> torch.Tensor:
            tm64 = tm.to(torch.int64)
            omt64 = (one_tm - tm).to(torch.int64)
            pa = xa.to(torch.int64) * tm64
            pb = xb.to(torch.int64) * omt64
            s = pa + pb
            sh = -tm_exp
            s2 = rshift_rne(s, sh).to(torch.int64)
            return sat_signed(s2, bits_x).to(torch.int32)

        xk_i = _mix(x_i, xx_i, self._int_time_mix_k)
        xv_i = _mix(x_i, xx_i, self._int_time_mix_v)
        xr_i = _mix(x_i, xx_i, self._int_time_mix_r)

        exp_log = int(self._int_log_exp.item())
        k_bits = int(cfg.get("k_bits", bits_x))
        v_bits = int(cfg.get("v_bits", bits_x))
        r_bits = int(cfg.get("r_bits", bits_x))

        k_i = linear_int(self.key, xk_i, exp_x, exp_log, k_bits, signed=True)
        v_i = linear_int(self.value, xv_i, exp_x, int(cfg.get("exp_v", exp_x)), v_bits, signed=True)
        r_i = linear_int(self.receptance, xr_i, exp_x, int(cfg.get("exp_r", exp_x)), r_bits, signed=True)

        if root is not None and getattr(root, "_dump_enabled", False):
            root._dump_tensor("after_kvr.k", k_i, exp_log)
            root._dump_tensor("after_kvr.v", v_i, int(cfg.get("exp_v", exp_x)))
            root._dump_tensor("after_kvr.r", r_i, int(cfg.get("exp_r", exp_x)))

        gate_bits = int(cfg.get("gate_bits", bits_x))
        sr_i, exp_gate = hardsigmoid_int(r_i, int(cfg.get("exp_r", exp_x)), gate_bits)

        if root is not None and getattr(root, "_dump_enabled", False):
            root._dump_tensor("after_gate", sr_i, exp_gate)

        w_i = self._int_time_decay_wexp
        u_i = self._int_time_first
        exp_v = int(cfg.get("exp_v", exp_x))
        p_bits = int(cfg.get("p_bits", 16))
        a_bits = int(cfg.get("a_bits", 24))
        b_bits = int(cfg.get("b_bits", 24))

        y_i = RUN_WKV_INT(
            w_i, u_i, k_i, v_i,
            lut=lut,
            p_bits=p_bits, a_bits=a_bits, b_bits=b_bits,
        )

        prod = y_i.to(torch.int64) * sr_i.to(torch.int64)
        exp_prod = exp_v + exp_gate
        exp_mul = int(cfg.get("exp_mul", exp_prod))
        mul_bits = int(cfg.get("mul_bits", bits_x))
        mul_i = requant_pow2(prod.to(torch.int32), exp_prod, exp_mul, mul_bits, signed=True)

        if root is not None and getattr(root, "_dump_enabled", False):
            root._dump_tensor("after_mul", mul_i, exp_mul)

        out_i = linear_int(self.output, mul_i, exp_mul, res_exp, res_bits, signed=True)
        return out_i


class RWKV_ChannelMix_Quan(nn.Module):
    def __init__(self, layer_num: int, in_dim: int, layer_id: int, kernel_size: int, hidden_sz: int, use_hsigmoid: bool):
        super().__init__()
        self.layer_id = layer_id
        self.in_dim = in_dim
        self.hidden_sz = hidden_sz
        self.kernel_size = kernel_size
        self.use_hsigmoid = use_hsigmoid

        self.deploy_mode = False

        with torch.no_grad():
            ratio_1_to_almost0 = (1.0 - (layer_id / layer_num))
            x = torch.linspace(0, 1, in_dim).unsqueeze(0).unsqueeze(0)

        self.time_mix_k = nn.Parameter(torch.pow(x, ratio_1_to_almost0))
        self.time_mix_r = nn.Parameter(torch.pow(x, ratio_1_to_almost0))

        self.time_shift = nn.Conv1d(
            in_channels=in_dim,
            out_channels=in_dim,
            kernel_size=kernel_size,
            stride=1,
            padding=0,
            bias=True,
            groups=in_dim
        )

        self.key = nn.Linear(self.in_dim, self.hidden_sz, bias=False)
        self.receptance = nn.Linear(self.in_dim, self.in_dim, bias=False)
        self.value = nn.Linear(self.hidden_sz, self.in_dim, bias=False)

        self.register_buffer("_int_time_mix_k", None, persistent=False)
        self.register_buffer("_int_time_mix_r", None, persistent=False)
        self.register_buffer("_int_time_mix_exp", None, persistent=False)
        self.register_buffer("_int_one_tm", None, persistent=False)

    def set_deploy_mode(self, enable: bool = True):
        self.deploy_mode = bool(enable)

    def _record(self, tag: str, x: torch.Tensor):
        root = getattr(self, "_root", None)
        if root is not None and getattr(root, "_calib_enabled", False):
            root._calib_update(tag, x)

    def forward(self, x: torch.Tensor):
        xx = x.permute(0, 2, 1)
        pad = (self.kernel_size, -1)
        xx = F.pad(xx, pad)
        xx = self.time_shift(xx)
        xx = xx.permute(0, 2, 1)

        xk = x * self.time_mix_k + xx * (1 - self.time_mix_k)
        xr = x * self.time_mix_r + xx * (1 - self.time_mix_r)

        k_val = self.key(xk)
        k_val = torch.clamp(k_val, max=10.0)

        kv = self.value(torch.square(torch.relu(k_val)))

        gate_in = self.receptance(xr)
        if self.deploy_mode:
            gate = F.hardsigmoid(gate_in)
        else:
            gate = F.hardsigmoid(gate_in) if self.use_hsigmoid else torch.sigmoid(gate_in)

        return gate * kv

    def forward_int(self, x_i: torch.Tensor, exp_x: int, bits_x: int, res_exp: int, res_bits: int, gate_bits: int) -> torch.Tensor:
        x_i = x_i.to(torch.int32)
        B, T, C = x_i.shape
        device = x_i.device

        xx = x_i.permute(0, 2, 1)
        xx = F.pad(xx, (self.kernel_size, -1))

        w = self.time_shift._int_w
        wexp = int(self.time_shift._int_w_exp.item())
        wb = self.time_shift._int_b
        bexp = int(self.time_shift._int_b_exp.item()) if wb is not None else None

        K = self.kernel_size
        out = torch.zeros((B, C, T), dtype=torch.int64, device=device)
        for i in range(K):
            out += xx[:, :, i:i + T].to(torch.int64) * w[:, 0, i].view(1, C, 1).to(torch.int64)
        if wb is not None:
            b_aligned = requant_pow2(wb.view(1, C, 1).to(torch.int32), bexp, exp_x + wexp, 32, signed=True).to(torch.int64)
            out += b_aligned
        xx_i = requant_pow2(out.to(torch.int32), exp_x + wexp, exp_x, bits_x, signed=True)
        xx_i = xx_i.permute(0, 2, 1)

        tm_exp = int(self._int_time_mix_exp.item())
        one_tm = self._int_one_tm

        def _mix(xa: torch.Tensor, xb: torch.Tensor, tm: torch.Tensor) -> torch.Tensor:
            tm64 = tm.to(torch.int64)
            omt64 = (one_tm - tm).to(torch.int64)
            s = xa.to(torch.int64) * tm64 + xb.to(torch.int64) * omt64
            sh = -tm_exp
            s2 = rshift_rne(s, sh).to(torch.int64)
            return sat_signed(s2, bits_x).to(torch.int32)

        xk_i = _mix(x_i, xx_i, self._int_time_mix_k)
        xr_i = _mix(x_i, xx_i, self._int_time_mix_r)

        k_i = linear_int(self.key, xk_i, exp_x, exp_x, bits_x, signed=True)
        k_relu = torch.clamp(k_i.to(torch.int64), 0, _qmax_signed(bits_x))
        k_sq = k_relu * k_relu
        exp_sq = exp_x + exp_x
        k_sq_q = requant_pow2(k_sq.to(torch.int32), exp_sq, exp_x, bits_x, signed=True)

        kv_i = linear_int(self.value, k_sq_q, exp_x, exp_x, bits_x, signed=True)

        gate_in = linear_int(self.receptance, xr_i, exp_x, exp_x, bits_x, signed=True)
        gate_i, exp_gate = hardsigmoid_int(gate_in, exp_x, gate_bits)

        prod = kv_i.to(torch.int64) * gate_i.to(torch.int64)
        exp_prod = exp_x + exp_gate
        out_i = requant_pow2(prod.to(torch.int32), exp_prod, res_exp, res_bits, signed=True)
        return out_i


class Block(nn.Module):
    def __init__(self, in_dim: int, layer_num: int, layer_id: int, kernel_size: int, hidden_sz: int, use_hsigmoid: bool):
        super().__init__()
        self.layer_id = layer_id
        self.att = RWKV_TimeMix_Quan(layer_num, in_dim, layer_id, kernel_size, use_hsigmoid)
        self.ffn = RWKV_ChannelMix_Quan(layer_num, in_dim, layer_id, kernel_size, hidden_sz, use_hsigmoid)

    def set_deploy_mode(self, enable: bool = True, preexp_w: bool = True):
        self.att.set_deploy_mode(enable=enable, preexp_w=preexp_w)
        self.ffn.set_deploy_mode(enable=enable)

    def forward(self, x):
        att_out = self.att(x)
        att_out = torch.clamp(att_out, min=-30.0, max=30.0)
        x = x + att_out

        root = getattr(self, "_root", None)
        if root is not None and getattr(root, "_calib_enabled", False):
            root._calib_update("after_residual_add", x)

        ffn_out = self.ffn(x)
        ffn_out = torch.clamp(ffn_out, min=-30.0, max=30.0)
        x = x + ffn_out

        if root is not None and getattr(root, "_calib_enabled", False):
            root._calib_update("after_residual_add", x)
        return x

    def forward_int(self, x_i: torch.Tensor, exp_x: int, bits_x: int, qctx: Dict[str, Any], lut: _WKVIntLUT) -> torch.Tensor:
        att_i = self.att.forward_int(
            x_i=x_i, exp_x=exp_x, bits_x=bits_x,
            res_exp=qctx["res_exp"], res_bits=qctx["res_bits"],
            cfg=qctx["att_cfg"],
            lut=lut,
        )
        x_i = sat_signed((x_i.to(torch.int64) + att_i.to(torch.int64)), qctx["res_bits"]).to(torch.int32)
        root = getattr(self, "_root", None)
        if root is not None and getattr(root, "_dump_enabled", False):
            root._dump_tensor("after_residual_add", x_i, qctx["res_exp"])

        ffn_i = self.ffn.forward_int(
            x_i=x_i, exp_x=qctx["res_exp"], bits_x=qctx["res_bits"],
            res_exp=qctx["res_exp"], res_bits=qctx["res_bits"],
            gate_bits=qctx["gate_bits"],
        )
        x_i = sat_signed((x_i.to(torch.int64) + ffn_i.to(torch.int64)), qctx["res_bits"]).to(torch.int32)
        if root is not None and getattr(root, "_dump_enabled", False):
            root._dump_tensor("after_residual_add", x_i, qctx["res_exp"])
        return x_i


def linear_int(mod: nn.Linear, x_i: torch.Tensor, exp_x: int, exp_out: int, out_bits: int, signed: bool = True) -> torch.Tensor:
    W = mod._int_w                          # int32
    wexp = int(mod._int_w_exp.item())
    x32 = x_i.to(torch.int32)

    BT = x32.shape[0] * x32.shape[1]
    In = x32.shape[2]
    Out = W.shape[0]
    x2 = x32.reshape(BT, In)

    acc = (x2.float() @ W.float().t()).to(torch.int64)

    acc = acc.reshape(x32.shape[0], x32.shape[1], Out)

    exp_acc = exp_x + wexp

    b = getattr(mod, "_int_b", None)
    if b is not None:
        bexp = int(mod._int_b_exp.item())
        b_aligned = requant_pow2(b.to(torch.int32), bexp, exp_acc, 32, signed=True).to(torch.int64)
        acc = acc + b_aligned.view(1, 1, Out).to(torch.int64)

    y = requant_pow2(acc.to(torch.int32), exp_acc, exp_out, out_bits, signed=signed)
    return y


class RWKVCNN_Quan(nn.Module):
    def __init__(self, params: dict):
        super().__init__()
        self.in_dim = params["in_dim"]
        self.model_dim = params["model_dim"]
        self.layer_num = params["layer_num"]
        self.out_dim = params["out_dim"]
        self.kernel_size = params["kernel_size"]
        self.init = params.get("init", True)
        self.hidden_sz = params.get("hidden_sz", self.model_dim * 3)
        self.use_hsigmoid = params.get("use_hsigmoid", True)

        self.step = 0
        global DEBUG
        # DEBUG = params["debug"]
        DEBUG = False

        self.input_proj = nn.Linear(self.in_dim, self.model_dim, bias=True)
        self.blocks = nn.Sequential(*[
            Block(self.model_dim, self.layer_num, i, self.kernel_size, self.hidden_sz, self.use_hsigmoid)
            for i in range(self.layer_num)
        ])
        self.output_proj = nn.Linear(self.model_dim, self.out_dim, bias=True)

        if self.init:
            RWKV_Init(self)

        root_ref = weakref.proxy(self)
        for m in self.modules():
            object.__setattr__(m, "_root", root_ref)

        self.qparams = _parse_quant_params(params)

        self._calib_enabled = False
        self._stats: Dict[str, _StatBuf] = {}
        self._act_exp: Dict[str, int] = {}
        self._dump_enabled = False
        self._dump: Dict[str, Tuple[torch.Tensor, int]] = {}

        self._int_ready = False
        self._int_enabled = False
        self._wkv_lut: Optional[_WKVIntLUT] = None

    def set_deploy_mode(self, enable: bool = True, preexp_w: bool = True):
        for m in self.modules():
            if isinstance(m, RWKV_TimeMix_Quan):
                m.set_deploy_mode(enable=enable, preexp_w=preexp_w)
            elif isinstance(m, RWKV_ChannelMix_Quan):
                m.set_deploy_mode(enable=enable)

    def input_preprocess(self, x):
        return x

    def _calib_update(self, tag: str, x: torch.Tensor):
        if tag not in self._stats:
            self._stats[tag] = _StatBuf(
                clip_method=self.qparams["calib"]["clip_method"],
                percentile=self.qparams["calib"]["percentile"],
            )
        self._stats[tag].update(x)

    @torch.no_grad()
    def calibrate_activations(self, data_loader, device: torch.device, num_batches: Optional[int] = None):
        root_ref = weakref.proxy(self)
        for m in self.modules():
            object.__setattr__(m, "_root", root_ref)

        self.eval()
        self._stats = {}
        self._calib_enabled = True
        n = int(num_batches or self.qparams["calib"]["num_batches"])
        used = 0
        for batch in data_loader:
            if isinstance(batch, (list, tuple)) and len(batch) >= 1:
                x = batch[0]
            elif isinstance(batch, dict):
                x = batch["x"]
            else:
                x = batch
            x = x.to(device)
            _ = self.forward(x)
            used += 1
            if used >= n:
                break
        self._calib_enabled = False

        act_bits = int(self.qparams["act_bits"])
        act_override: Dict[str, int] = dict(self.qparams.get("act_override", {}))
        act_points = set(self.qparams.get("act_points", []))

        def bits_for(tag: str) -> int:
            return int(act_override.get(tag, act_bits))

        def get_amax(tag: str) -> float:
            if tag in self._stats:
                v = self._stats[tag].get_amax()
                if not math.isfinite(v) or v > 1e30:
                    print(f"[WARN] tag '{tag}' amax={v:.3e} is NaN-polluted, ignored")
                    return 0.0
                return v
            return 0.0

        res_tag = "after_residual_add"
        if get_amax(res_tag) <= 0.0:
            res_tag = "after_input_proj"
        res_bits = bits_for("after_residual_add")
        res_amax = max(get_amax(res_tag), 1e-6)
        res_exp = choose_pow2_exp(res_amax, _qmax_signed(res_bits), FIXED_RULES["zfb_exp"], FIXED_RULES["min_exp"], FIXED_RULES["max_exp"])
        if res_exp >= 0:
            fallback_amax = max(get_amax("after_input_proj"), 1e-6)
            res_exp_fb = choose_pow2_exp(fallback_amax, _qmax_signed(res_bits), FIXED_RULES["zfb_exp"], FIXED_RULES["min_exp"], FIXED_RULES["max_exp"])
            print(f"[WARN] res_exp={res_exp} >= 0 (likely NaN-polluted), "
                  f"fallback to after_input_proj exp={res_exp_fb}")
            res_exp = res_exp_fb

        self._act_exp["residual"] = res_exp

        for base in ["after_input_proj", "after_time_shift", "after_mul", "after_residual_add"]:
            if base in act_points or base == "after_residual_add":
                b = bits_for(base)
                amax = max(get_amax(base), res_amax)
                self._act_exp[base] = res_exp if base in ("after_input_proj", "after_time_shift", "after_residual_add") else choose_pow2_exp(amax, _qmax_signed(b), FIXED_RULES["zfb_exp"], FIXED_RULES["min_exp"], FIXED_RULES["max_exp"])

        if "after_kvr" in act_points:
            kb = int(self.qparams["wkv_int"]["fmt"].get("k_bits", act_bits))
            vb = int(self.qparams["wkv_int"]["fmt"].get("v_bits", act_bits))
            rb = bits_for("after_kvr")
            k_amax = max(get_amax("after_kvr.k"), 1e-6)
            v_amax = max(get_amax("after_kvr.v"), 1e-6)
            r_amax = max(get_amax("after_kvr.r"), 1e-6)

            for subtag, amax_val, bits_val in [
                ("after_kvr.k", k_amax, kb),
                ("after_kvr.v", v_amax, vb),
                ("after_kvr.r", r_amax, rb),
            ]:
                if amax_val < 1e-5:
                    print(f"[WARN] {subtag} amax={amax_val:.2e} suspicious, "
                          f"fallback to res_amax={res_amax:.4f}")
                    amax_val = res_amax
                exp_val = choose_pow2_exp(amax_val, _qmax_signed(bits_val), FIXED_RULES["zfb_exp"], FIXED_RULES["min_exp"], FIXED_RULES["max_exp"])
                if exp_val > 0:
                    print(f"[WARN] {subtag} exp={exp_val} > 0, clamp to res_exp={res_exp}")
                    exp_val = res_exp
                self._act_exp[subtag] = exp_val
                if DEBUG:
                    print(f"[DIAG] {subtag}: amax={amax_val:.4f}  bits={bits_val}  exp={exp_val}")

        gb = bits_for("after_gate")
        self._act_exp["after_gate"] = -gb

    def enable_dump(self, enable: bool = True):
        self._dump_enabled = bool(enable)
        if not self._dump_enabled:
            self._dump = {}

    def _dump_tensor(self, tag: str, q: torch.Tensor, exp: int):
        self._dump[tag] = (q.detach().cpu(), int(exp))

    def get_dump(self) -> Dict[str, Tuple[torch.Tensor, int]]:
        return dict(self._dump)

    def _validate_bit_override(self, bit_override: Dict[str, int]):
        names = []
        for n, m in self.named_modules():
            if isinstance(m, (nn.Linear, nn.Conv1d)):
                names.append(n)
        name_set = set(names)
        bad = [k for k in bit_override.keys() if k not in name_set]
        if bad:
            msg_lines = ["bit_override contains unknown module keys (strict mode):"]
            for k in bad:
                sugg = difflib.get_close_matches(k, names, n=5, cutoff=0.4)
                msg_lines.append(f"  {k}  (did you mean: {sugg} ?)")
            raise ValueError("\n".join(msg_lines))

    @torch.no_grad()
    def prepare_int_infer(self, require_calib: bool = True):
        if require_calib and (len(self._act_exp) == 0):
            raise RuntimeError("Activation calibration is required. Call calibrate_activations() first.")
        q = self.qparams
        w_bits = int(q["w_bits"])
        act_bits = int(q["act_bits"])
        bit_override: Dict[str, int] = dict(q.get("bit_override", {}))
        self._validate_bit_override(bit_override)

        wkv_cfg = q["wkv_int"]
        exp_cfg = wkv_cfg["exp_approx"]
        lut_size = int(exp_cfg.get("lut_size", 256))
        e_frac = int(exp_cfg.get("out_bits", 16))
        clamp_in = exp_cfg.get("clamp_in", [-12.0, 0.0])
        min_delta = float(clamp_in[0])
        max_delta = float(clamp_in[1])
        if max_delta != 0.0:
            max_delta = 0.0
        qmax_e = _qmax_unsigned(e_frac)
        xs = torch.linspace(min_delta, 0.0, steps=lut_size, dtype=torch.float32)
        vals = torch.exp(xs)
        lut = torch.round(vals * qmax_e).to(torch.int32)
        self._wkv_lut_raw = lut
        self._wkv_min_delta = min_delta
        self._wkv_lut_size = lut_size
        self._wkv_e_frac = e_frac

        for name, mod in self.named_modules():
            if not isinstance(mod, (nn.Linear, nn.Conv1d)):
                continue
            bits = int(bit_override.get(name, w_bits))
            w = mod.weight.detach().float()
            amax = float(w.abs().max().item())
            exp_w = choose_pow2_exp(amax, _qmax_signed(bits), FIXED_RULES["zfb_exp"], FIXED_RULES["min_exp"], FIXED_RULES["max_exp"])
            w_i = quantize_pow2(w, bits=bits, exp=exp_w, signed=True)

            mod.register_buffer("_int_w", w_i, persistent=False)
            mod.register_buffer("_int_w_exp", torch.tensor([exp_w], dtype=torch.int32), persistent=False)
            mod.register_buffer("_int_w_bits", torch.tensor([bits], dtype=torch.int32), persistent=False)

            if getattr(mod, "bias", None) is not None and mod.bias is not None:
                b = mod.bias.detach().float()
                exp_b = exp_w
                b_i = quantize_pow2(b, bits=min(31, bits + 8), exp=exp_b, signed=True)
                mod.register_buffer("_int_b", b_i, persistent=False)
                mod.register_buffer("_int_b_exp", torch.tensor([exp_b], dtype=torch.int32), persistent=False)
            else:
                mod.register_buffer("_int_b", None, persistent=False)
                mod.register_buffer("_int_b_exp", torch.tensor([0], dtype=torch.int32), persistent=False)

        tm_exp = -w_bits
        one_tm = torch.tensor([_qmax_unsigned(w_bits)], dtype=torch.int32)
        for m in self.modules():
            if isinstance(m, RWKV_TimeMix_Quan):
                m.register_buffer("_int_time_mix_exp", torch.tensor([tm_exp], dtype=torch.int32), persistent=False)
                m.register_buffer("_int_one_tm", one_tm.clone(), persistent=False)
                m.register_buffer("_int_time_mix_k", quantize_pow2(m.time_mix_k.detach().float(), w_bits, tm_exp, signed=False), persistent=False)
                m.register_buffer("_int_time_mix_v", quantize_pow2(m.time_mix_v.detach().float(), w_bits, tm_exp, signed=False), persistent=False)
                m.register_buffer("_int_time_mix_r", quantize_pow2(m.time_mix_r.detach().float(), w_bits, tm_exp, signed=False), persistent=False)
            elif isinstance(m, RWKV_ChannelMix_Quan):
                m.register_buffer("_int_time_mix_exp", torch.tensor([tm_exp], dtype=torch.int32), persistent=False)
                m.register_buffer("_int_one_tm", one_tm.clone(), persistent=False)
                m.register_buffer("_int_time_mix_k", quantize_pow2(m.time_mix_k.detach().float(), w_bits, tm_exp, signed=False), persistent=False)
                m.register_buffer("_int_time_mix_r", quantize_pow2(m.time_mix_r.detach().float(), w_bits, tm_exp, signed=False), persistent=False)

        fmt = wkv_cfg["fmt"]
        k_bits = int(fmt.get("k_bits", act_bits))
        v_bits = int(fmt.get("v_bits", act_bits))
        u_bits = int(fmt.get("u_bits", act_bits))
        wq_bits = int(fmt.get("w_bits", int(q.get("time_decay_w_exp", w_bits))))
        exp_v = int(self._act_exp.get("after_kvr.v", self._act_exp.get("residual", - (act_bits - 1))))
        exp_r = int(self._act_exp.get("after_kvr.r", self._act_exp.get("residual", - (act_bits - 1))))
        # exp_mul = int(self._act_exp.get("after_mul", self._act_exp.get("residual", - (act_bits - 1))))
        exp_k_cal = int(self._act_exp.get("after_kvr.k", 0))

        if DEBUG:
            print("[DIAG] _act_exp contents:", dict(self._act_exp))
            print(f"[DIAG] exp_v={exp_v}  exp_r={exp_r}  exp_k_cal={exp_k_cal}")

        exp_log_global = exp_k_cal
        for m in self.modules():
            if isinstance(m, RWKV_TimeMix_Quan):
                u = m.time_first.detach().float()
                u_amax = float(u.abs().max().item())
                exp_u = choose_pow2_exp(u_amax, _qmax_signed(u_bits), FIXED_RULES["zfb_exp"], FIXED_RULES["min_exp"], FIXED_RULES["max_exp"])
                wexp_f = -torch.exp(m.time_decay.detach().float())
                w_amax = float(wexp_f.abs().max().item())
                exp_w = choose_pow2_exp(w_amax, _qmax_signed(wq_bits), FIXED_RULES["zfb_exp"], FIXED_RULES["min_exp"], FIXED_RULES["max_exp"])

                if DEBUG:
                    print(f"[DIAG] layer {m.layer_id}: "
                          f"u_amax={u_amax:.4f} exp_u={exp_u}  "
                          f"w_amax={w_amax:.4f} exp_w={exp_w}  "
                          f"time_decay range=[{float(m.time_decay.min()):.3f},{float(m.time_decay.max()):.3f}]")

                exp_log_global = max(exp_log_global, exp_u, exp_w)
        if DEBUG:
            print(f"[DIAG] exp_log_global final = {exp_log_global}")

        min_delta_i = int(round(self._wkv_min_delta / (2.0 ** exp_log_global)))
        step_real = (0.0 - self._wkv_min_delta) / max(1, (self._wkv_lut_size - 1))
        step_i = int(round(step_real / (2.0 ** exp_log_global)))
        step_i = max(step_i, 1)
        self._wkv_lut = _WKVIntLUT(self._wkv_lut_raw, min_delta_i=min_delta_i, step_i=step_i, e_frac=self._wkv_e_frac)

        self.register_buffer("_int_wkv_lut", self._wkv_lut_raw, persistent=False)
        self.register_buffer("_int_wkv_min_delta_i", torch.tensor([min_delta_i], dtype=torch.int32), persistent=False)
        self.register_buffer("_int_wkv_step_i", torch.tensor([step_i], dtype=torch.int32), persistent=False)
        self.register_buffer("_int_wkv_e_frac", torch.tensor([self._wkv_e_frac], dtype=torch.int32), persistent=False)
        self.register_buffer("_int_wkv_log_exp", torch.tensor([exp_log_global], dtype=torch.int32), persistent=False)

        for m in self.modules():
            if isinstance(m, RWKV_TimeMix_Quan):
                m.register_buffer("_int_log_exp", torch.tensor([exp_log_global], dtype=torch.int32), persistent=False)
                m.register_buffer("_int_time_first", quantize_pow2(m.time_first.detach().float(), u_bits, exp_log_global, signed=True), persistent=False)
                wexp_f = -torch.exp(m.time_decay.detach().float())
                m.register_buffer("_int_time_decay_wexp", quantize_pow2(wexp_f, wq_bits, exp_log_global, signed=True), persistent=False)

        gate_bits_val = int(self.qparams.get("act_override", {}).get("after_gate", act_bits))
        exp_gate_val = -gate_bits_val
        exp_mul_natural = exp_v + exp_gate_val

        exp_mul_from_calib = int(self._act_exp.get("after_mul", exp_mul_natural))
        exp_mul_final = exp_mul_from_calib

        if DEBUG:
            print(f"[INFO] exp_mul_final={exp_mul_final}  (natural={exp_mul_natural}, calib={exp_mul_from_calib})")

        self._int_ctx = {
            "res_exp": int(self._act_exp.get("residual", -(act_bits - 1))),
            "res_bits": int(self.qparams.get("act_override", {}).get("after_residual_add", act_bits)),
            "att_cfg": {
                "k_bits": k_bits,
                "v_bits": v_bits,
                "r_bits": int(self.qparams.get("act_override", {}).get("after_kvr", act_bits)),
                "exp_v": exp_v,
                "exp_r": exp_r,
                "exp_mul": exp_mul_final,
                "gate_bits": int(self.qparams.get("act_override", {}).get("after_gate", act_bits)),
                "mul_bits": int(self.qparams.get("act_override", {}).get("after_mul", act_bits)),
                "p_bits": int(wkv_cfg["acc"].get("p_bits", 16)),
                "a_bits": int(wkv_cfg["acc"].get("a_bits", 24)),
                "b_bits": int(wkv_cfg["acc"].get("b_bits", 24)),
            },
            "gate_bits": int(self.qparams.get("act_override", {}).get("after_gate", act_bits)),
        }

        self._fix_bias_domain(self.input_proj, self._int_ctx["res_exp"])
        out_bits = int(self.qparams["io_int"]["out_bits"])
        out_exp = -(out_bits - 1)
        self._fix_bias_domain(self.output_proj, out_exp)
        for name, mod in self.named_modules():
            if isinstance(mod, nn.Conv1d) and name.endswith("time_shift"):
                self._fix_bias_domain(mod, self._int_ctx["res_exp"])

        self._int_ready = True

        device = next(self.parameters()).device
        self._move_int_buffers(device)

    def _move_int_buffers(self, device: torch.device):
        for m in self.modules():
            # 处理 registered buffers
            for name in list(m._buffers.keys()):
                if name.startswith("_int_"):
                    buf = m._buffers[name]
                    if buf is not None:
                        m._buffers[name] = buf.to(device)
            # 处理普通属性（以防遗漏）
            for attr in list(vars(m).keys()):
                if attr.startswith("_int_") and attr not in m._buffers:
                    v = getattr(m, attr)
                    if isinstance(v, torch.Tensor):
                        setattr(m, attr, v.to(device))
        if self._wkv_lut is not None:
            self._wkv_lut.lut = self._wkv_lut.lut.to(device)

    def _fix_bias_domain(self, mod: nn.Module, exp_out: int):
        """将模块的量化 bias 重新对齐到 exp_out 域"""
        b = getattr(mod, "_int_b", None)
        if b is None:
            return
        bexp = int(mod._int_b_exp.item())
        wexp = int(mod._int_w_exp.item())
        if bexp != wexp:
            bits_b = max(int(b.abs().max().item()).bit_length() + 1, 16)
            mod._int_b = requant_pow2(b, bexp, wexp, bits_b, signed=True)
            mod._int_b_exp = torch.tensor([wexp], dtype=torch.int32, device=b.device)

    def enable_int_infer(self, enable: bool = True):
        if enable and not self._int_ready:
            raise RuntimeError("INT inference not prepared. Call prepare_int_infer() first.")
        self._int_enabled = bool(enable)

    @torch.no_grad()
    def forward_int(self, x: torch.Tensor) -> Tuple[torch.Tensor, torch.Tensor, int]:
        if not self._int_ready:
            raise RuntimeError("INT inference not prepared. Call prepare_int_infer() first.")
        q = self.qparams
        io = q["io_int"]
        in_bits = int(io["in_bits"])
        out_bits = int(io["out_bits"])
        exp_in = -(in_bits - 1)
        exp_out = -(out_bits - 1)

        x_f = x.detach().float()
        x_i = quantize_pow2(x_f, in_bits, exp_in, signed=True)

        res_exp = self._int_ctx["res_exp"]
        res_bits = self._int_ctx["res_bits"]
        h_i = linear_int(self.input_proj, x_i, exp_in, res_exp, res_bits, signed=True)

        if self._dump_enabled:
            self._dump_tensor("after_input_proj", h_i, res_exp)

        for blk in self.blocks:
            h_i = blk.forward_int(h_i, res_exp, res_bits, self._int_ctx, self._wkv_lut)

        y_i = linear_int(self.output_proj, h_i, res_exp, exp_out, out_bits, signed=True)

        y_f = dequantize_pow2(y_i, exp_out)
        return y_f.to(x.dtype), y_i, exp_out

    def forward(self, x):
        x = self.input_preprocess(x)
        if self._int_enabled:
            y_f, _, _ = self.forward_int(x)
            return y_f

        x = self.input_proj(x)
        if self._calib_enabled:
            self._calib_update("after_input_proj", x)
        x = self.blocks(x)
        x = self.output_proj(x)

        if self._calib_enabled and not torch.isfinite(x).all():
            import warnings
            warnings.warn(f"[RWKVCNN] output contains nan/inf during calibration, "
                          f"nan_frac={float((~torch.isfinite(x)).float().mean()):.3f}")
        return x


def _parse_quant_params(params: Dict[str, Any]) -> Dict[str, Any]:
    default_bits = int(params.get("w_bits", params.get("default_bits", 8)))
    act_bits = int(params.get("act_bits", params.get("default_bits", default_bits)))
    w_bits = int(params.get("w_bits", default_bits))
    time_decay_w_exp = int(params.get("time_decay_w_exp", w_bits))

    bit_override = dict(params.get("bit_override", {}))
    act_points = list(params.get("act_points", []))
    act_override = dict(params.get("act_override", {}))
    calib = dict(params.get("calib", {}))
    calib.setdefault("num_batches", 200)
    calib.setdefault("clip_method", "percentile")
    calib.setdefault("percentile", 99.9)

    wkv_int = params.get("wkv_int", None)
    io_int = params.get("io_int", None)

    if wkv_int is None:
        wkv_int = {
            "fmt": {
                "k_bits": int(params.get("k_bits", act_bits)),
                "v_bits": int(params.get("v_bits", act_bits)),
                "u_bits": int(params.get("u_bits", act_bits)),
                "w_bits": int(params.get("w_bits_wkv", time_decay_w_exp)),
                "out_bits": int(params.get("out_bits_wkv", act_bits)),
            },
            "acc": dict(params.get("acc", {"a_bits": 24, "b_bits": 24, "p_bits": 16})),
            "exp_approx": dict(params.get("exp_approx", {"lut_size": 256, "out_bits": 16, "clamp_in": [-12.0, 0.0]})),
        }
    else:
        wkv_int = dict(wkv_int)
        wkv_int.setdefault("fmt", {"k_bits": act_bits, "v_bits": act_bits, "u_bits": act_bits, "w_bits": time_decay_w_exp, "out_bits": act_bits})
        wkv_int.setdefault("acc", {"a_bits": 24, "b_bits": 24, "p_bits": 16})
        wkv_int.setdefault("exp_approx", {"lut_size": 256, "out_bits": 16, "clamp_in": [-12.0, 0.0]})

    if io_int is None:
        io_int = {
            "in_bits": int(params.get("in_bits", 12)),
            "out_bits": int(params.get("out_bits", 12)),
        }
    else:
        io_int = dict(io_int)
        io_int.setdefault("in_bits", 12)
        io_int.setdefault("out_bits", 12)

    return {
        "w_bits": w_bits,
        "act_bits": act_bits,
        "time_decay_w_exp": time_decay_w_exp,
        "bit_override": bit_override,
        "act_points": act_points,
        "act_override": act_override,
        "calib": calib,
        "wkv_int": wkv_int,
        "io_int": io_int,
    }


if __name__ == "__main__":
    import argparse
    import torch
    if torch.cuda.is_available():
        cap = torch.cuda.get_device_capability()
        os.environ["TORCH_CUDA_ARCH_LIST"] = f"{cap[0]}.{cap[1]}"

    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument("--B", type=int, default=2)
    parser.add_argument("--T", type=int, default=16)
    parser.add_argument("--trials", type=int, default=3)
    parser.add_argument("--calib_batches", type=int, default=2)
    parser.add_argument("--device", type=str, default="cuda")
    args, _unknown = parser.parse_known_args()

    torch.manual_seed(args.seed)
    device = torch.device(args.device)

    params = {
        "in_dim": 2,
        "model_dim": 6,
        "layer_num": 2,
        "out_dim": 2,
        "kernel_size": 4,
        "hidden_sz": 18,
        "init": True,
        "use_hsigmoid": True,

        "w_bits": 8,
        "act_bits": 8,
        "time_decay_w_exp": 8,
        "bit_override": {
            "input_proj": 12,
            "blocks.0.att.key": 4,
            "blocks.0.att.receptance": 4,
            "blocks.0.att.time_shift": 4,
        },
        "act_points": ["after_input_proj", "after_time_shift", "after_kvr", "after_gate", "after_mul", "after_residual_add"],
        "act_override": {},
        "calib": {"num_batches": args.calib_batches, "clip_method": "maxabs", "percentile": 99.9},
        "io_int": {"in_bits": 12, "out_bits": 12},
        "wkv_int": {
            "fmt": {"k_bits": 12, "v_bits": 12, "u_bits": 12, "w_bits": 12, "out_bits": 12},
            "acc": {"a_bits": 24, "b_bits": 24, "p_bits": 16},
            "exp_approx": {"lut_size": 256, "out_bits": 16, "clamp_in": [-12.0, 0.0]},
        },
    }

    _rq_stat = {"n": 0, "max_abs_delta": 0, "hist": {}}
    _rs_stat = {"n_big": 0, "max_sh": 0}

    _orig_requant_pow2 = requant_pow2

    def _requant_pow2_monkey(q, exp_in, exp_out, bits, signed=True):
        d = int(exp_in - exp_out)
        _rq_stat["n"] += 1
        ad = abs(d)
        if ad > _rq_stat["max_abs_delta"]:
            _rq_stat["max_abs_delta"] = ad
        _rq_stat["hist"][d] = _rq_stat["hist"].get(d, 0) + 1
        return _orig_requant_pow2(q, exp_in, exp_out, bits, signed=signed)
    globals()["requant_pow2"] = _requant_pow2_monkey

    _orig_rshift_rne = rshift_rne

    def _rshift_rne_monkey(x, sh: int):
        sh_i = int(sh)
        if sh_i >= 64:
            _rs_stat["n_big"] += 1
            _rs_stat["max_sh"] = max(_rs_stat["max_sh"], sh_i)
        return _orig_rshift_rne(x, sh_i)
    globals()["rshift_rne"] = _rshift_rne_monkey

    model = RWKVCNN_Quan(params).to(device)
    model.set_deploy_mode(True, preexp_w=True)

    bad = []
    for n, m in model.named_modules():
        if "_root" in getattr(m, "_modules", {}):
            bad.append(n)
    if len(bad) > 0:
        print("[ERR] _root registered as submodule in:", bad[:10], " ... total:", len(bad))
    else:
        print("[OK] no _root cycle in module tree")

    if DEBUG:
        print("[DIAG] _root check:")
    for name, m in model.named_modules():
        if isinstance(m, RWKV_TimeMix_Quan):
            root = getattr(m, "_root", None)
            if DEBUG:
                print(f"  {name}: _root is model? {root is model}  type={type(root)}")
            break

    import pandas as pd

    _val_csv = os.path.join(
        os.path.dirname(__file__), "..", "..", "data", "OpenDPD", "DPA_200MHz", "val_input.csv"
    )
    _val_csv = os.path.normpath(_val_csv)

    class _RealDL:
        def __init__(self, csv_path: str, B: int, T: int, max_batches: int):
            self.B = B
            self.T = T
            self.max_batches = max_batches
            df = pd.read_csv(csv_path, header=None, comment='#')
            try:
                data = df.values.astype("float32")
            except ValueError:
                df = pd.read_csv(csv_path, header=0, comment='#')
                data = df.values.astype("float32")
            data = data[:, :2]
            self._data = torch.tensor(data, dtype=torch.float32)

        def __iter__(self):
            N = self._data.shape[0]
            seg = self.B * self.T
            max_start = N - seg
            if max_start <= 0:
                raise RuntimeError(
                    f"val_input.csv 数据量不足: N={N} < B*T={seg}"
                )
            count = 0
            step = max(1, max_start // self.max_batches)
            for start in range(0, max_start, step):
                if count >= self.max_batches:
                    break
                chunk = self._data[start: start + seg]
                x = chunk.reshape(self.B, self.T, 2)
                yield x, torch.zeros_like(x), 0
                count += 1

    if os.path.isfile(_val_csv):
        print(f"[INFO] 使用真实验证集: {_val_csv}")
        dl = _RealDL(_val_csv, B=args.B, T=args.T, max_batches=max(3, args.calib_batches))
    else:
        print(f"[WARN] 未找到 {_val_csv}，回退到随机数据")

        class _FakeDL:
            def __iter__(self):
                for _ in range(max(3, args.calib_batches)):
                    x = torch.randn(args.B, args.T, 2, device=device) * 0.2
                    y = torch.randn(args.B, args.T, 2, device=device)
                    yield x, y, 0
        dl = _FakeDL()

    model.enable_int_infer(False)

    model.calibrate_activations(dl, device=device, num_batches=args.calib_batches)
    model.prepare_int_infer(require_calib=True)
    print("[INFO] exp_mul (auto) =", model._int_ctx["att_cfg"]["exp_mul"])
    model.enable_dump(True)
    model.enable_int_infer(True)

    print("\n[INT ctx]")
    try:
        print("  res_exp:", model._int_ctx["res_exp"], "res_bits:", model._int_ctx["res_bits"])
        ac = model._int_ctx["att_cfg"]
        print("  att k_bits/v_bits/r_bits:", ac["k_bits"], ac["v_bits"], ac["r_bits"])
        print("  att gate_bits/mul_bits:", ac["gate_bits"], ac["mul_bits"])
        print("  att exp_v/exp_r/exp_mul:", ac["exp_v"], ac["exp_r"], ac["exp_mul"])
    except Exception as e:
        print("  (cannot print _int_ctx details)", repr(e))

    def _mse(a, b):
        return float(((a - b) ** 2).mean().item())

    def _nmse_db(a, b, eps=1e-12):
        num = ((a - b) ** 2).mean()
        den = (a ** 2).mean().clamp_min(eps)
        return float(10.0 * torch.log10(num / den).item())

    def _tag_bits_signed(tag: str):
        act_bits = int(model.qparams.get("act_bits", 8))
        ov = dict(model.qparams.get("act_override", {}))
        if tag in ("after_input_proj", "after_time_shift", "after_residual_add"):
            return int(model._int_ctx.get("res_bits", act_bits)), True
        if tag == "after_kvr.k":
            return int(model._int_ctx["att_cfg"]["k_bits"]), True
        if tag == "after_kvr.v":
            return int(model._int_ctx["att_cfg"]["v_bits"]), True
        if tag == "after_kvr.r":
            return int(model._int_ctx["att_cfg"]["r_bits"]), True
        if tag == "after_gate":
            return int(model._int_ctx["att_cfg"]["gate_bits"]), False
        if tag == "after_mul":
            return int(model._int_ctx["att_cfg"]["mul_bits"]), True
        return int(ov.get(tag, act_bits)), True

    print("\n[Trials]")
    last_dump = None
    out_bits = int(model.qparams["io_int"]["out_bits"])

    real_data_batches = list(iter(dl))

    for t in range(args.trials):
        torch.manual_seed(args.seed + t)

        x = real_data_batches[t % len(real_data_batches)][0].to(device)

        model.enable_int_infer(False)
        torch.manual_seed(args.seed + t)
        y_ref = model(x).detach()

        model.enable_int_infer(True)
        y_fw = model(x).detach()

        y_f, y_i, e = model.forward_int(x)

        c_fw = float((y_fw - y_f).abs().max().item())

        y_deq = dequantize_pow2(y_i, e).to(device=device, dtype=y_f.dtype)
        c_deq = float((y_deq - y_f).abs().max().item())

        y_ref_f = y_ref.float()
        y_f_f = y_f.float()
        ref_has_nan = not torch.isfinite(y_ref_f).all()
        int_has_nan = not torch.isfinite(y_f_f).all()
        if ref_has_nan:
            print(f"  [WARN] trial {t}: float baseline contains nan/inf!")
        if int_has_nan:
            print(f"  [WARN] trial {t}: int output contains nan/inf!")

        mse = _mse(y_ref_f, y_f_f)
        nmse = _nmse_db(y_ref_f, y_f_f)
        maxe = float((y_ref_f - y_f_f).abs().max().item())

        y_ref_i = quantize_pow2(y_ref_f.detach(), out_bits, e, signed=True)
        mismatch = float((y_ref_i != y_i).float().mean().item() * 100.0)

        print(f"  trial {t}: exp_out={e:>3d}  y_int=[{int(y_i.min())},{int(y_i.max())}] "
              f"| fw-vs-fwdint={c_fw:.3e}  deq-vs-yf={c_deq:.3e} "
              f"| float MSE={mse:.3e}  NMSE={nmse:.2f} dB  max|err|={maxe:.3e} "
              f"| int_mismatch={mismatch:.2f}%")

        last_dump = model.get_dump()

    print("\n[Dump analysis]")
    if last_dump is None or len(last_dump) == 0:
        print("  (no dump captured)")
    else:
        for tag, (q, exp) in last_dump.items():
            bits, is_signed = _tag_bits_signed(tag)
            q = q.to(torch.int64)

            if is_signed:
                lo, hi = _qmin_signed(bits), _qmax_signed(bits)
                sat = float(((q == lo) | (q == hi)).float().mean().item() * 100.0)
            else:
                lo, hi = 0, _qmax_unsigned(bits)
                sat = float(((q == lo) | (q == hi)).float().mean().item() * 100.0)

            scale = math.ldexp(1.0, int(exp))
            qmin, qmax = int(q.min().item()), int(q.max().item())
            fmin = float((q.float() * scale).min().item())
            fmax = float((q.float() * scale).max().item())

            extra = ""
            if tag == "after_gate":
                extra = f"  (gate_float_range≈[{fmin:.3f},{fmax:.3f}])"

            print(f"  {tag:18s} bits={bits:2d} exp={int(exp):3d} "
                  f"int=[{qmin:>6d},{qmax:>6d}] float≈[{fmin:+.4f},{fmax:+.4f}] "
                  f"sat@edge={sat:.3f}%{extra}")

    print("\n[Shift / Requant stats]")
    print(f"  requant calls: {_rq_stat['n']}  max|delta|: {_rq_stat['max_abs_delta']}")
    top = sorted(_rq_stat["hist"].items(), key=lambda kv: kv[1], reverse=True)[:8]
    print("  delta histogram (top):", top)
    print(f"  rshift sh>=64 count: {_rs_stat['n_big']}  max_sh_seen: {_rs_stat['max_sh']}")

    print("\n[Done]")
