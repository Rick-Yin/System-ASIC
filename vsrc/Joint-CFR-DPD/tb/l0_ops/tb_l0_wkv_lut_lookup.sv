`timescale 1ns/1ps

module tb_l0_wkv_lut_lookup;
  import quant_utils_pkg::*;
  import l0_case_pkg::*;

  localparam int LUT_NUMEL = 256;

  integer fd;
  integer scan_rc;
  integer case_cnt;
  integer mismatches;
  integer plusargs_rc;

  logic signed [31:0] lut [0:LUT_NUMEL-1];

  logic [31:0] delta_u;
  logic [31:0] min_delta_u;
  logic [31:0] step_u;
  logic [31:0] exp_idx_u;
  logic [31:0] exp_val_u;

  integer idx;
  logic [31:0] idx_u;
  logic signed [31:0] val;
  integer i;
  reg [1023:0] vector_path;

  initial begin
    for (i = 0; i < LUT_NUMEL; i++) begin
      lut[i] = $signed((i * 3) - 500);
    end

    case_cnt = 0;
    mismatches = 0;
    vector_path = "vsrc/Joint-CFR-DPD/tb/l0_ops/vectors/wkv_lut_lookup.vec";
    plusargs_rc = $value$plusargs("VECTOR_FILE=%s", vector_path);

    fd = $fopen(vector_path, "r");
    if (fd == 0) begin
      $display("[L0][FAIL] op=wkv_lut_lookup cannot open vector file");
      $finish;
    end

    begin : read_loop
      forever begin
        scan_rc = $fscanf(fd, "%h %h %h %h %h\n", delta_u, min_delta_u, step_u, exp_idx_u, exp_val_u);
        if (scan_rc == -1) begin
          disable read_loop;
        end
        if (scan_rc != 5) begin
          $display("[L0][FAIL] op=wkv_lut_lookup malformed vector row, scan_rc=%0d", scan_rc);
          $finish;
        end

        idx = wkv_lut_lookup_idx(
          $signed(delta_u),
          $signed(min_delta_u),
          $signed(step_u),
          LUT_NUMEL
        );
        idx_u = idx[31:0];
        val = lut[idx];

        if ((idx_u !== exp_idx_u) || (val !== $signed(exp_val_u))) begin
          mismatches = mismatches + 1;
        end
        case_cnt = case_cnt + 1;
      end
    end
    $fclose(fd);

    l0_report("wkv_lut_lookup", case_cnt, mismatches);
    $finish;
  end

endmodule
