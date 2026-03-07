`timescale 1ns/1ps

module tb_l0_requant_pow2_signed;
  import quant_utils_pkg::*;
  import l0_case_pkg::*;

  integer fd;
  integer scan_rc;
  integer case_cnt;
  integer mismatches;

  logic [63:0] x_u;
  logic [31:0] exp_in_u;
  logic [31:0] exp_out_u;
  logic [31:0] bits_u;
  logic [31:0] exp_u;
  logic signed [31:0] got;

  integer exp_in_i;
  integer exp_out_i;

  initial begin
    case_cnt = 0;
    mismatches = 0;

    fd = $fopen("vsrc/Joint-CFR-DPD/tb/l0_ops/vectors/requant_pow2_signed.vec", "r");
    if (fd == 0) begin
      $display("[L0][FAIL] op=requant_pow2_signed cannot open vector file");
      $finish;
    end

    begin : read_loop
      forever begin
        scan_rc = $fscanf(fd, "%h %h %h %h %h\n", x_u, exp_in_u, exp_out_u, bits_u, exp_u);
        if (scan_rc == -1) begin
          disable read_loop;
        end
        if (scan_rc != 5) begin
          $display("[L0][FAIL] op=requant_pow2_signed malformed vector row, scan_rc=%0d", scan_rc);
          $finish;
        end

        exp_in_i = $signed(exp_in_u);
        exp_out_i = $signed(exp_out_u);
        got = requant_pow2_signed($signed(x_u), exp_in_i, exp_out_i, bits_u);
        if (got !== $signed(exp_u)) begin
          mismatches = mismatches + 1;
        end
        case_cnt = case_cnt + 1;
      end
    end
    $fclose(fd);

    l0_report("requant_pow2_signed", case_cnt, mismatches);
    $finish;
  end

endmodule
