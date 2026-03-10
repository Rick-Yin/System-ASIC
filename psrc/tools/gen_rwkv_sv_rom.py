import json
import pathlib
import struct
from typing import List, Dict, Any

MANIFEST_PATH = pathlib.Path("vsrc/rom/manifest.json")
BIN_DIR = pathlib.Path("vsrc/rom/bin")
OUT_PKG_PATH = pathlib.Path("vsrc/Joint-CFR-DPD/include/rwkvcnn_pkg.sv")
OUT_MAP_PATH = pathlib.Path("vsrc/Joint-CFR-DPD/rom/rwkv_tensor_map.sv")
OUT_ROM_PATH = pathlib.Path("vsrc/Joint-CFR-DPD/rom/rwkv_rom_bank.sv")


def sanitize(name: str) -> str:
    out = []
    for ch in name:
        if ch.isalnum():
            out.append(ch.upper())
        else:
            out.append("_")
    s = "".join(out)
    while "__" in s:
        s = s.replace("__", "_")
    return s.strip("_")


def read_int32_le(path: pathlib.Path, numel: int) -> List[int]:
    raw = path.read_bytes()
    if len(raw) != numel * 4:
        raise ValueError(f"{path} size mismatch: got {len(raw)} bytes, expected {numel*4}")
    vals = list(struct.unpack("<" + "i" * numel, raw))
    return vals


def sv_int32(v: int) -> str:
    iv = int(v)
    if iv < 0:
        return f"-32'sd{abs(iv)}"
    return f"32'sd{iv}"


def parse_model_dims(tensors: List[Dict[str, Any]]) -> Dict[str, int]:
    by_name = {t["name"]: t for t in tensors}
    input_w = by_name["input_proj.w"]["shape"]
    output_w = by_name["output_proj.w"]["shape"]
    ffn_key = by_name["blocks.0.ffn.key.w"]["shape"]
    ts_w = by_name["blocks.0.att.time_shift.w"]["shape"]

    layer_ids = set()
    for t in tensors:
        n = t["name"]
        if n.startswith("blocks."):
            try:
                lid = int(n.split(".")[1])
                layer_ids.add(lid)
            except (IndexError, ValueError):
                pass

    return {
        "MODEL_DIM": int(input_w[0]),
        "IN_DIM": int(input_w[1]),
        "OUT_DIM": int(output_w[0]),
        "LAYER_NUM": (max(layer_ids) + 1) if layer_ids else 0,
        "HIDDEN_SZ": int(ffn_key[0]),
        "KERNEL_SIZE": int(ts_w[2]),
    }


def emit_pkg(manifest: Dict[str, Any], tensors: List[Dict[str, Any]], tensor_vals: Dict[str, List[int]], out_path: pathlib.Path) -> None:
    dims = parse_model_dims(tensors)
    int_ctx = manifest.get("int_ctx", {})
    io = manifest.get("io", {})
    att_cfg = int_ctx.get("att_cfg", {})

    lines: List[str] = []
    lines.append("package rwkvcnn_pkg;")
    lines.append("")
    lines.append("  // Auto-generated from vsrc/rom/manifest.json and vsrc/rom/bin/*.bin")
    lines.append(f"  // MANIFEST_GENERATED_AT: {manifest.get('generated_at_utc', '')}")
    lines.append("")

    for k in ["IN_DIM", "MODEL_DIM", "LAYER_NUM", "OUT_DIM", "KERNEL_SIZE", "HIDDEN_SZ"]:
        lines.append(f"  localparam int {k} = {dims[k]};")
    lines.append("")

    lines.append(f"  localparam int RES_EXP = {int(int_ctx.get('res_exp', -6))};")
    lines.append(f"  localparam int RES_BITS = {int(int_ctx.get('res_bits', 8))};")
    lines.append(f"  localparam int GATE_BITS = {int(int_ctx.get('gate_bits', 8))};")
    lines.append(f"  localparam int K_BITS = {int(att_cfg.get('k_bits', 8))};")
    lines.append(f"  localparam int V_BITS = {int(att_cfg.get('v_bits', 8))};")
    lines.append(f"  localparam int R_BITS = {int(att_cfg.get('r_bits', 8))};")
    lines.append(f"  localparam int EXP_V = {int(att_cfg.get('exp_v', -7))};")
    lines.append(f"  localparam int EXP_R = {int(att_cfg.get('exp_r', -7))};")
    lines.append(f"  localparam int EXP_MUL = {int(att_cfg.get('exp_mul', -6))};")
    lines.append(f"  localparam int MUL_BITS = {int(att_cfg.get('mul_bits', 8))};")
    lines.append(f"  localparam int P_BITS = {int(att_cfg.get('p_bits', 16))};")
    lines.append(f"  localparam int A_BITS = {int(att_cfg.get('a_bits', 24))};")
    lines.append(f"  localparam int B_BITS = {int(att_cfg.get('b_bits', 24))};")
    lines.append(f"  localparam int IO_EXP_IN = {int(io.get('exp_in', -11))};")
    lines.append(f"  localparam int IO_EXP_OUT = {int(io.get('exp_out', -11))};")
    lines.append(f"  localparam int IO_IN_BITS = {int(io.get('in_bits', 12))};")
    lines.append(f"  localparam int IO_OUT_BITS = {int(io.get('out_bits', 12))};")
    lines.append("")

    lines.append(f"  localparam int ROM_COUNT = {len(tensors)};")
    lines.append("")

    for idx, t in enumerate(tensors):
        tname = t["name"]
        sid = sanitize(tname)
        vals = tensor_vals[tname]

        lines.append(f"  localparam int ROM_ID_{sid} = {idx};")
        lines.append(f"  localparam int {sid}_NUMEL = {len(vals)};")
        lines.append(f"  localparam int {sid}_EXP = {int(t.get('exp', 0))};")
        lines.append(f"  localparam int {sid}_LOGICAL_BITS = {int(t.get('logical_bits', 32))};")
        lines.append(f"  localparam bit {sid}_IS_SIGNED = 1'b{1 if t.get('signed', True) else 0};")
        lines.append("")

    lines.append("  function automatic logic signed [31:0] rom_read(input logic [7:0] rom_id, input logic [15:0] addr);")
    lines.append("    logic signed [31:0] v;")
    lines.append("    begin")
    lines.append("      v = 32'sd0;")
    lines.append("      case (rom_id)")
    for t in tensors:
        sid = sanitize(t["name"])
        sv_vals = [sv_int32(v) for v in tensor_vals[t["name"]]]
        lines.append(f"        ROM_ID_{sid}: begin")
        lines.append(f"          if (addr < {sid}_NUMEL) begin")
        lines.append("            case (addr)")
        for vidx, v in enumerate(sv_vals):
            lines.append(f"              16'd{vidx}: v = {v};")
        lines.append("              default: v = 32'sd0;")
        lines.append("            endcase")
        lines.append("          end")
        lines.append("        end")
    lines.append("        default: begin")
    lines.append("          v = 32'sd0;")
    lines.append("        end")
    lines.append("      endcase")
    lines.append("      rom_read = v;")
    lines.append("    end")
    lines.append("  endfunction")
    lines.append("")
    lines.append("endpackage")

    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def emit_tensor_map(tensors: List[Dict[str, Any]], out_path: pathlib.Path) -> None:
    lines: List[str] = []
    lines.append("package rwkv_tensor_map;")
    lines.append("  import rwkvcnn_pkg::*;")
    lines.append("")
    lines.append("  // ROM IDs")
    for t in tensors:
        sid = sanitize(t["name"])
        lines.append(f"  localparam int {sid} = ROM_ID_{sid};")
    lines.append("")
    lines.append("endpackage")
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def emit_rom_bank(tensors: List[Dict[str, Any]], tensor_vals: Dict[str, List[int]], out_path: pathlib.Path) -> None:
    lines: List[str] = []
    lines.extend([
        "module rwkv_rom #(",
        "  parameter int ROM_ID = 0",
        ")(",
        "  input  logic [15:0] addr,",
        "  output logic signed [31:0] rdata",
        ");",
        "  import rwkvcnn_pkg::*;",
        "",
        "  generate",
    ])

    first = True
    for tensor in tensors:
        sid = sanitize(tensor["name"])
        sv_vals = [sv_int32(v) for v in tensor_vals[tensor["name"]]]
        branch = "if" if first else "else if"
        first = False
        lines.append(f"    {branch} (ROM_ID == ROM_ID_{sid}) begin : gen_{sid.lower()}")
        lines.append("      always_comb begin")
        lines.append("        rdata = 32'sd0;")
        lines.append(f"        if (addr < {sid}_NUMEL) begin")
        lines.append("          case (addr)")
        for vidx, value in enumerate(sv_vals):
            lines.append(f"            16'd{vidx}: rdata = {value};")
        lines.append("            default: rdata = 32'sd0;")
        lines.append("          endcase")
        lines.append("        end")
        lines.append("      end")
        lines.append("    end")

    lines.extend([
        "    else begin : gen_default",
        "      always_comb begin",
        "        rdata = 32'sd0;",
        "      end",
        "    end",
        "  endgenerate",
        "",
        "endmodule",
        "",
        "module rwkv_rom_flat #(",
        "  parameter int ROM_ID = 0,",
        "  parameter int LEN = 1",
        ")(",
        "  output wire signed [LEN*32-1:0] data",
        ");",
        "  genvar idx;",
        "  generate",
        "    for (idx = 0; idx < LEN; idx++) begin : gen_words",
        "      localparam logic [15:0] ADDR = idx;",
        "      rwkv_rom #(.ROM_ID(ROM_ID)) u_rom (",
        "        .addr(ADDR),",
        "        .rdata(data[idx*32 +: 32])",
        "      );",
        "    end",
        "  endgenerate",
        "",
        "endmodule",
        "",
        "module rwkv_rom_bank (",
        "  input  logic [7:0] rom_id,",
        "  input  logic [15:0] addr,",
        "  output logic signed [31:0] rdata",
        ");",
        "  import rwkvcnn_pkg::*;",
        "",
        "  always_comb begin",
        "    rdata = rom_read(rom_id, addr);",
        "  end",
        "",
        "endmodule",
    ])
    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    tensors = manifest["tensors"]

    tensor_vals: Dict[str, List[int]] = {}
    for t in tensors:
        name = t["name"]
        bin_name = t["bin_file"]
        numel = int(t["numel"])
        vals = read_int32_le(BIN_DIR / bin_name, numel)
        tensor_vals[name] = vals

    OUT_PKG_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_MAP_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_ROM_PATH.parent.mkdir(parents=True, exist_ok=True)

    emit_pkg(manifest, tensors, tensor_vals, OUT_PKG_PATH)
    emit_tensor_map(tensors, OUT_MAP_PATH)
    emit_rom_bank(tensors, tensor_vals, OUT_ROM_PATH)

    print(f"[OK] Generated {OUT_PKG_PATH}")
    print(f"[OK] Generated {OUT_MAP_PATH}")
    print(f"[OK] Generated {OUT_ROM_PATH}")


if __name__ == "__main__":
    main()
