`timescale 1ns/1ps

module tb_migo_const_coeff_mac;
  localparam int BX = 8;
  localparam int N = 161;
  localparam int MAX_CASES = 1024;

  logic clk;
  logic rst_n;
  logic in_valid;
  logic signed [BX-1:0] x_in;
  logic out_valid;
  logic signed [8:0] y_out;

  integer vec_fd;
  integer scan_rc;
  integer case_count;
  integer case_idx;
  integer tap_idx;
  integer expected_sum;
  integer mismatches;
  integer taps [0:N-1];
  string vector_path;

  MIGO_method_migo_n_161_q_bit_8_wp_pi_0_047_width_pi_0_031_alpha_p_0_1_alpha_s_0_1_lam1_1_2_lam2_1_e_topk_4_e_d_max_2_e_e_max_4 u_dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .x_in(x_in),
    .out_valid(out_valid),
    .y_out(y_out)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    in_valid = 1'b0;
    x_in = '0;
    mismatches = 0;

    if (!$value$plusargs("VECTOR_FILE=%s", vector_path)) begin
      $display("[MIGO-STRUCT][FAIL] missing VECTOR_FILE plusarg");
      $finish;
    end
    vec_fd = $fopen(vector_path, "r");
    if (vec_fd == 0) begin
      $display("[MIGO-STRUCT][FAIL] cannot open vector file: %s", vector_path);
      $finish;
    end
    scan_rc = $fscanf(vec_fd, "%d\n", case_count);
    if ((scan_rc != 1) || (case_count <= 0) || (case_count > MAX_CASES)) begin
      $display("[MIGO-STRUCT][FAIL] invalid case count: scan_rc=%0d case_count=%0d", scan_rc, case_count);
      $finish;
    end

    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    #1;

    for (case_idx = 0; case_idx < case_count; case_idx = case_idx + 1) begin
      for (tap_idx = 0; tap_idx < N; tap_idx = tap_idx + 1) begin
        scan_rc = $fscanf(vec_fd, "%d", taps[tap_idx]);
        if (scan_rc != 1) begin
          $display("[MIGO-STRUCT][FAIL] malformed tap value case=%0d tap=%0d", case_idx, tap_idx);
          $finish;
        end
      end
      scan_rc = $fscanf(vec_fd, "%d\n", expected_sum);
      if (scan_rc != 1) begin
        $display("[MIGO-STRUCT][FAIL] malformed expected sum case=%0d", case_idx);
        $finish;
      end

      for (tap_idx = 0; tap_idx < N; tap_idx = tap_idx + 1) begin
        u_dut.shift_reg[tap_idx] = taps[tap_idx];
      end
      #1;

      if ($signed(u_dut.final_sum) !== expected_sum) begin
        mismatches = mismatches + 1;
        $display(
          "[MIGO-STRUCT][ERR] item=const_coeff_mac case=%0d got=%0d exp=%0d",
          case_idx, $signed(u_dut.final_sum), expected_sum
        );
      end
    end

    $fclose(vec_fd);
    if (mismatches == 0) begin
      $display("[MIGO-STRUCT][PASS] item=const_coeff_mac cases=%0d mismatches=%0d", case_count, mismatches);
    end else begin
      $display("[MIGO-STRUCT][FAIL] item=const_coeff_mac cases=%0d mismatches=%0d", case_count, mismatches);
    end
    $finish;
  end
endmodule
