`timescale 1ns/1ps

module tb_l0_hardsigmoid_int_default;
  import quant_utils_pkg::*;
  import l0_case_pkg::*;

  integer fd;
  integer scan_rc;
  integer case_cnt;
  integer mismatches;
  integer plusargs_rc;

  logic [31:0] x_u;
  logic [31:0] exp_x_u;
  logic [31:0] gate_bits_u;
  logic [31:0] exp_u;
  logic [31:0] got;

  integer exp_x_i;
  reg [1023:0] vector_path;

  initial begin
    case_cnt = 0;
    mismatches = 0;
    vector_path = "vsrc/Joint-CFR-DPD/tb/l0_ops/vectors/hardsigmoid_int_default.vec";
    plusargs_rc = $value$plusargs("VECTOR_FILE=%s", vector_path);

    fd = $fopen(vector_path, "r");
    if (fd == 0) begin
      $display("[L0][FAIL] op=hardsigmoid_int_default cannot open vector file");
      $finish;
    end

    begin : read_loop
      forever begin
        scan_rc = $fscanf(fd, "%h %h %h %h\n", x_u, exp_x_u, gate_bits_u, exp_u);
        if (scan_rc == -1) begin
          disable read_loop;
        end
        if (scan_rc != 4) begin
          $display("[L0][FAIL] op=hardsigmoid_int_default malformed vector row, scan_rc=%0d", scan_rc);
          $finish;
        end

        exp_x_i = $signed(exp_x_u);
        got = hardsigmoid_int_default($signed(x_u), exp_x_i, gate_bits_u);
        if (got !== exp_u) begin
          mismatches = mismatches + 1;
        end
        case_cnt = case_cnt + 1;
      end
    end
    $fclose(fd);

    l0_report("hardsigmoid_int_default", case_cnt, mismatches);
    $finish;
  end

endmodule
