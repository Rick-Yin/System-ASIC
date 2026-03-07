`timescale 1ns/1ps

module tb_l0_rshift_rne64;
  import quant_utils_pkg::*;
  import l0_case_pkg::*;

  integer fd;
  integer scan_rc;
  integer case_cnt;
  integer mismatches;

  logic [63:0] x_u;
  logic [31:0] sh_u;
  logic [63:0] exp_u;
  logic signed [63:0] got;
  integer sh_i;

  initial begin
    case_cnt = 0;
    mismatches = 0;

    fd = $fopen("vsrc/Joint-CFR-DPD/tb/l0_ops/vectors/rshift_rne64.vec", "r");
    if (fd == 0) begin
      $display("[L0][FAIL] op=rshift_rne64 cannot open vector file");
      $finish;
    end

    begin : read_loop
      forever begin
        scan_rc = $fscanf(fd, "%h %h %h\n", x_u, sh_u, exp_u);
        if (scan_rc == -1) begin
          disable read_loop;
        end
        if (scan_rc != 3) begin
          $display("[L0][FAIL] op=rshift_rne64 malformed vector row, scan_rc=%0d", scan_rc);
          $finish;
        end

        sh_i = $signed(sh_u);
        got = rshift_rne64($signed(x_u), sh_i);
        if (got !== $signed(exp_u)) begin
          mismatches = mismatches + 1;
        end
        case_cnt = case_cnt + 1;
      end
    end
    $fclose(fd);

    l0_report("rshift_rne64", case_cnt, mismatches);
    $finish;
  end

endmodule
