`timescale 1ns/1ps

module tb_div_rne_su;
  import quant_utils_pkg::*;

  localparam int X_WIDTH = 24;
  localparam int D_WIDTH = 24;
  localparam int Q_WIDTH = 32;
  localparam int RANDOM_CASES = 128;

  logic signed [X_WIDTH-1:0] x;
  logic [D_WIDTH-1:0] d;
  logic signed [Q_WIDTH-1:0] q;

  integer errors;
  integer idx;
  integer seed;
  logic signed [63:0] ref_q64;
  logic signed [Q_WIDTH-1:0] ref_q;

  task automatic check_case(
    input signed [X_WIDTH-1:0] case_x,
    input [D_WIDTH-1:0] case_d
  );
    begin
      x = case_x;
      d = case_d;
      #1;
      ref_q64 = div_rne64(
        {{(64-X_WIDTH){case_x[X_WIDTH-1]}}, case_x},
        $signed({{(64-D_WIDTH){1'b0}}, case_d})
      );
      ref_q = ref_q64[Q_WIDTH-1:0];

      if (q !== ref_q) begin
        errors = errors + 1;
        $display("[DIVSU][ERR] x=%0d d=%0d got=%0d exp=%0d", case_x, case_d, q, ref_q);
      end
    end
  endtask

  div_rne_su #(
    .X_WIDTH(X_WIDTH),
    .D_WIDTH(D_WIDTH),
    .Q_WIDTH(Q_WIDTH)
  ) dut (
    .x(x),
    .d(d),
    .q(q)
  );

  initial begin
    x = '0;
    d = '0;
    errors = 0;
    seed = 32'h1bad_c0de;

    check_case(24'sd0, 24'd0);
    check_case(24'sd0, 24'd1);
    check_case(24'sd1, 24'd1);
    check_case(-24'sd1, 24'd1);
    check_case(24'sd7, 24'd2);
    check_case(-24'sd7, 24'd2);
    check_case(24'sd9, 24'd6);
    check_case(24'sd15, 24'd6);
    check_case(-24'sd15, 24'd6);
    check_case(24'sd17, 24'd6);
    check_case(24'sd12345, 24'd37);
    check_case(-24'sd12345, 24'd37);
    check_case(24'sh7fffff, 24'd1);
    check_case(-24'sh800000, 24'd1);
    check_case(24'sh7fffff, 24'd3);
    check_case(-24'sh800000, 24'd3);
    check_case(24'sd25, 24'd10);
    check_case(24'sd35, 24'd10);
    check_case(-24'sd25, 24'd10);
    check_case(-24'sd35, 24'd10);

    for (idx = 0; idx < RANDOM_CASES; idx++) begin
      check_case($random(seed), $random(seed));
      if (d == {D_WIDTH{1'b0}}) begin
        d = {{(D_WIDTH-1){1'b0}}, 1'b1};
        check_case(x, d);
      end
    end

    if (errors == 0) begin
      $display("[DIVSU][PASS] errors=%0d", errors);
    end else begin
      $display("[DIVSU][FAIL] errors=%0d", errors);
    end
    $finish;
  end

endmodule
