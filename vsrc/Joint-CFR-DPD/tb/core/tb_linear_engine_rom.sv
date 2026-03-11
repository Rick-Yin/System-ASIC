`timescale 1ns/1ps

module tb_linear_engine_rom;
  import quant_utils_pkg::*;

  localparam int MAX_IN_DIM = 4;
  localparam int MAX_OUT_DIM = 3;
  localparam int MAX_WEIGHT_DEPTH = MAX_IN_DIM * MAX_OUT_DIM;

  logic clk;
  logic rst_n;
  logic start;
  logic signed [31:0] x_vec [0:MAX_IN_DIM-1];
  logic [15:0] in_dim;
  logic [15:0] out_dim;
  logic bias_en;
  logic signed [31:0] exp_x;
  logic signed [31:0] exp_out;
  logic signed [31:0] w_exp;
  logic signed [31:0] b_exp;
  logic [7:0] out_bits;
  logic signed [31:0] w_data;
  logic signed [31:0] b_data;
  logic [15:0] w_addr;
  logic [15:0] b_addr;
  logic busy;
  logic done;
  logic signed [MAX_OUT_DIM*32-1:0] y_bus;

  logic signed [31:0] weights [0:MAX_WEIGHT_DEPTH-1];
  logic signed [31:0] biases [0:MAX_OUT_DIM-1];

  integer cycle;
  integer errors;
  integer i;

  function automatic logic signed [31:0] y_word(input int idx);
    begin
      y_word = y_bus[idx*32 +: 32];
    end
  endfunction

  task automatic clear_case_data;
    begin
      for (i = 0; i < MAX_IN_DIM; i++) begin
        x_vec[i] = '0;
      end
      for (i = 0; i < MAX_WEIGHT_DEPTH; i++) begin
        weights[i] = '0;
      end
      for (i = 0; i < MAX_OUT_DIM; i++) begin
        biases[i] = '0;
      end
      in_dim = '0;
      out_dim = '0;
      bias_en = 1'b0;
      exp_x = 32'sd0;
      exp_out = 32'sd0;
      w_exp = 32'sd0;
      b_exp = 32'sd0;
      out_bits = 8'd32;
    end
  endtask

  task automatic pulse_start;
    begin
      @(posedge clk);
      start <= 1'b1;
      @(posedge clk);
      start <= 1'b0;
    end
  endtask

  task automatic wait_done_or_timeout(input integer timeout_cycles);
    integer remaining;
    begin
      remaining = timeout_cycles;
      while ((done !== 1'b1) && (remaining > 0)) begin
        @(posedge clk);
        remaining = remaining - 1;
      end
      if (done !== 1'b1) begin
        errors = errors + 1;
        $display("[LINROM][ERR] timeout cycle=%0d busy=%0b w_addr=%0d b_addr=%0d", cycle, busy, w_addr, b_addr);
      end
    end
  endtask

  task automatic check_word(input integer idx, input signed [31:0] expect_word);
    begin
      if (y_word(idx) !== expect_word) begin
        errors = errors + 1;
        $display("[LINROM][ERR] y[%0d] got=%0d exp=%0d", idx, y_word(idx), expect_word);
      end
    end
  endtask

  task automatic run_case_bias_enabled;
    begin
      clear_case_data();

      x_vec[0] = 32'sd1;
      x_vec[1] = 32'sd2;
      x_vec[2] = 32'sd3;
      x_vec[3] = 32'sd4;
      in_dim = 16'd4;
      out_dim = 16'd3;
      bias_en = 1'b1;

      weights[0] = 32'sd1;
      weights[1] = 32'sd2;
      weights[2] = 32'sd3;
      weights[3] = 32'sd4;
      weights[4] = -32'sd1;
      weights[5] = 32'sd1;
      weights[6] = 32'sd0;
      weights[7] = 32'sd2;
      weights[8] = 32'sd0;
      weights[9] = -32'sd2;
      weights[10] = 32'sd1;
      weights[11] = -32'sd1;

      biases[0] = 32'sd1;
      biases[1] = -32'sd2;
      biases[2] = 32'sd0;

      pulse_start();
      wait_done_or_timeout(32);
      @(posedge clk);

      check_word(0, 32'sd31);
      check_word(1, 32'sd7);
      check_word(2, -32'sd5);
    end
  endtask

  task automatic run_case_bias_disabled;
    begin
      clear_case_data();

      x_vec[0] = 32'sd4;
      x_vec[1] = -32'sd2;
      in_dim = 16'd2;
      out_dim = 16'd2;
      bias_en = 1'b0;

      weights[0] = 32'sd5;
      weights[1] = -32'sd1;
      weights[2] = 32'sd2;
      weights[3] = 32'sd3;

      pulse_start();
      wait_done_or_timeout(16);
      @(posedge clk);

      check_word(0, 32'sd22);
      check_word(1, 32'sd2);
    end
  endtask

  always #5 clk = ~clk;

  always_comb begin
    if (w_addr < MAX_WEIGHT_DEPTH) begin
      w_data = weights[w_addr];
    end else begin
      w_data = 32'sd0;
    end

    if (b_addr < MAX_OUT_DIM) begin
      b_data = biases[b_addr];
    end else begin
      b_data = 32'sd0;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      cycle <= 0;
    end else begin
      cycle <= cycle + 1;
    end
  end

  linear_engine_rom #(
    .MAX_IN_DIM(MAX_IN_DIM),
    .MAX_OUT_DIM(MAX_OUT_DIM)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .x_vec(x_vec),
    .in_dim(in_dim),
    .out_dim(out_dim),
    .bias_en(bias_en),
    .exp_x(exp_x),
    .exp_out(exp_out),
    .w_exp(w_exp),
    .b_exp(b_exp),
    .out_bits(out_bits),
    .w_data(w_data),
    .b_data(b_data),
    .w_addr(w_addr),
    .b_addr(b_addr),
    .busy(busy),
    .done(done),
    .y_bus(y_bus)
  );

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    start = 1'b0;
    cycle = 0;
    errors = 0;
    clear_case_data();

    repeat (5) @(posedge clk);
    rst_n = 1'b1;

    run_case_bias_enabled();
    run_case_bias_disabled();

    if (errors == 0) begin
      $display("[LINROM][PASS] errors=%0d", errors);
    end else begin
      $display("[LINROM][FAIL] errors=%0d", errors);
    end
    $finish;
  end

endmodule
