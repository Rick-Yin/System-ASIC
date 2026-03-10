`timescale 1ns/1ps

module tb_l0_sat_signed32;
  import quant_utils_pkg::*;
  import l0_case_pkg::*;

  integer fd;
  integer scan_rc;
  integer case_cnt;
  integer mismatches;
  integer plusargs_rc;
  reg [1023:0] vector_path;

  logic [63:0] x_u;
  logic [31:0] bits_u;
  logic [31:0] exp_u;
  logic signed [31:0] got;

  initial begin
    case_cnt = 0;
    mismatches = 0;
    vector_path = "vsrc/Joint-CFR-DPD/tb/l0_ops/vectors/sat_signed32.vec";
    plusargs_rc = $value$plusargs("VECTOR_FILE=%s", vector_path);

    fd = $fopen(vector_path, "r");
    if (fd == 0) begin
      $display("[L0][FAIL] op=sat_signed32 cannot open vector file");
      $finish;
    end

    begin : read_loop
      forever begin
        scan_rc = $fscanf(fd, "%h %h %h\n", x_u, bits_u, exp_u);
        if (scan_rc == -1) begin
          disable read_loop;
        end
        if (scan_rc != 3) begin
          $display("[L0][FAIL] op=sat_signed32 malformed vector row, scan_rc=%0d", scan_rc);
          $finish;
        end

        got = sat_signed32($signed(x_u), bits_u);
        if (got !== $signed(exp_u)) begin
          mismatches = mismatches + 1;
        end
        case_cnt = case_cnt + 1;
      end
    end
    $fclose(fd);

    l0_report("sat_signed32", case_cnt, mismatches);
    $finish;
  end

endmodule
