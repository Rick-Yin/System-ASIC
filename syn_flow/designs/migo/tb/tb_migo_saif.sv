`timescale 1ns/1ps

module tb_migo_saif;
  localparam int BX = 8;
  localparam int BY = 9;
  localparam int DEFAULT_TOTAL_SAMPLES = 512;
  localparam int MAX_SAMPLES = 4096;
  localparam int GAP_PERIOD = 9;
  localparam int FLUSH_CYCLES = 96;
  localparam int TIMEOUT_CYCLES = 4000;

  logic clk;
  logic rst_n;
  logic in_valid;
  logic signed [BX-1:0] x_in;
  logic out_valid;
  logic signed [BY-1:0] y_out;

  integer cycles;
  integer sent_samples;
  integer recv_samples;
  integer idle_cycles_after_send;
  integer out_fd;
  integer error_count;
  integer input_samples;
  integer expect_samples;
  integer input_fd;
  integer golden_fd;
  integer scan_rc;
  integer input_mem [0:MAX_SAMPLES-1];
  integer golden_mem [0:MAX_SAMPLES-1];
  bit use_external_input;
  bit use_golden_check;

  string output_path;
  string saif_path;
  string input_path;
  string golden_path;

  MIGO_method_migo_n_161_q_bit_8_wp_pi_0_047_width_pi_0_031_alpha_p_0_1_alpha_s_0_1_lam1_1_2_lam2_1_e_topk_4_e_d_max_2_e_e_max_4 u_dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .x_in(x_in),
    .out_valid(out_valid),
    .y_out(y_out)
  );

  always #5 clk = ~clk;

  function automatic logic signed [BX-1:0] sample_for_idx(input int idx);
    logic signed [BX-1:0] sample_value;
    int centered;
    begin
      if (idx == 0) begin
        sample_value = 8'sd64;
      end else if (idx < 48) begin
        sample_value = '0;
      end else if (idx < 160) begin
        sample_value = idx[0] ? -8'sd128 : 8'sd127;
      end else if (idx < 256) begin
        centered = idx - 208;
        sample_value = centered;
      end else begin
        sample_value = $signed($urandom_range(255, 0)) - 8'sd128;
      end
      return sample_value;
    end
  endfunction

  function automatic logic signed [BX-1:0] cast_x(input integer value);
    return value;
  endfunction

  function automatic logic signed [BY-1:0] cast_y(input integer value);
    return value;
  endfunction

  task automatic stop_and_report;
    begin
`ifdef SYNOPSYS_SAIF
      $toggle_stop();
      $toggle_report(saif_path, 1.0e-9, u_dut);
`endif
    end
  endtask

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    in_valid = 1'b0;
    x_in = '0;
    cycles = 0;
    sent_samples = 0;
    recv_samples = 0;
    idle_cycles_after_send = 0;
    error_count = 0;
    input_samples = DEFAULT_TOTAL_SAMPLES;
    expect_samples = 0;
    use_external_input = 1'b0;
    use_golden_check = 1'b0;

    if (!$value$plusargs("OUTPUT_FILE=%s", output_path)) begin
      output_path = "migo_output.vec";
    end
    if (!$value$plusargs("SAIF_FILE=%s", saif_path)) begin
      saif_path = "migo.saif";
    end

    out_fd = $fopen(output_path, "w");
    if (out_fd == 0) begin
      $display("[MIGO][FAIL] cannot open output file: %s", output_path);
      $finish;
    end

    if ($value$plusargs("INPUT_FILE=%s", input_path)) begin
      use_external_input = 1'b1;
      input_fd = $fopen(input_path, "r");
      if (input_fd == 0) begin
        $display("[MIGO][FAIL] cannot open input file: %s", input_path);
        $finish;
      end
      input_samples = 0;
      begin : read_input_loop
        forever begin
          if (input_samples >= MAX_SAMPLES) begin
            $display("[MIGO][FAIL] input vector exceeds MAX_SAMPLES=%0d", MAX_SAMPLES);
            $finish;
          end
          scan_rc = $fscanf(input_fd, "%d\n", input_mem[input_samples]);
          if (scan_rc == -1) begin
            disable read_input_loop;
          end
          if (scan_rc != 1) begin
            $display("[MIGO][FAIL] malformed input row, scan_rc=%0d", scan_rc);
            $finish;
          end
          input_samples = input_samples + 1;
        end
      end
      $fclose(input_fd);
    end

    if ($value$plusargs("GOLDEN_FILE=%s", golden_path)) begin
      use_golden_check = 1'b1;
      golden_fd = $fopen(golden_path, "r");
      if (golden_fd == 0) begin
        $display("[MIGO][FAIL] cannot open golden file: %s", golden_path);
        $finish;
      end
      expect_samples = 0;
      begin : read_golden_loop
        forever begin
          if (expect_samples >= MAX_SAMPLES) begin
            $display("[MIGO][FAIL] golden vector exceeds MAX_SAMPLES=%0d", MAX_SAMPLES);
            $finish;
          end
          scan_rc = $fscanf(golden_fd, "%d\n", golden_mem[expect_samples]);
          if (scan_rc == -1) begin
            disable read_golden_loop;
          end
          if (scan_rc != 1) begin
            $display("[MIGO][FAIL] malformed golden row, scan_rc=%0d", scan_rc);
            $finish;
          end
          expect_samples = expect_samples + 1;
        end
      end
      $fclose(golden_fd);
    end

    if (input_samples <= 0) begin
      $display("[MIGO][FAIL] empty input vectors");
      $finish;
    end
    if (use_golden_check && (expect_samples != input_samples)) begin
      $display("[MIGO][FAIL] input/golden length mismatch: input=%0d golden=%0d", input_samples, expect_samples);
      $finish;
    end

    repeat (5) @(posedge clk);
    rst_n = 1'b1;

`ifdef SYNOPSYS_SAIF
    $set_toggle_region(u_dut);
    $toggle_start();
`endif
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      in_valid <= 1'b0;
      x_in <= '0;
    end else if (sent_samples < input_samples) begin
      if (((sent_samples + cycles) % GAP_PERIOD) == 0) begin
        in_valid <= 1'b0;
        x_in <= '0;
      end else begin
        in_valid <= 1'b1;
        x_in <= use_external_input ? cast_x(input_mem[sent_samples]) : sample_for_idx(sent_samples);
        sent_samples <= sent_samples + 1;
      end
    end else begin
      in_valid <= 1'b0;
      x_in <= '0;
      idle_cycles_after_send <= idle_cycles_after_send + 1;
    end
  end

  always @(posedge clk) begin
    if (rst_n && out_valid) begin
      recv_samples <= recv_samples + 1;
      $fwrite(out_fd, "%0d\n", $signed(y_out));
      if (^y_out === 1'bx) begin
        error_count <= error_count + 1;
        $display("[MIGO][ERR] x-state observed at recv_idx=%0d", recv_samples);
      end else if (use_golden_check) begin
        if (recv_samples >= expect_samples) begin
          error_count <= error_count + 1;
          $display("[MIGO][ERR] extra output sample idx=%0d got=%0d", recv_samples, $signed(y_out));
        end else if ($signed(y_out) !== cast_y(golden_mem[recv_samples])) begin
          error_count <= error_count + 1;
          $display(
            "[MIGO][ERR] mismatch idx=%0d got=%0d exp=%0d",
            recv_samples,
            $signed(y_out),
            cast_y(golden_mem[recv_samples])
          );
        end
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      cycles <= 0;
    end else begin
      cycles <= cycles + 1;
      if (cycles > TIMEOUT_CYCLES) begin
        $display("[MIGO][FAIL] timeout cycles=%0d sent=%0d recv=%0d errors=%0d", cycles, sent_samples, recv_samples, error_count);
        stop_and_report();
        $fclose(out_fd);
        $finish;
      end

      if ((sent_samples >= input_samples) && (idle_cycles_after_send >= FLUSH_CYCLES)) begin
        stop_and_report();
        if (use_golden_check && (recv_samples != expect_samples)) begin
          $display("[MIGO][FAIL] recv mismatch sent=%0d recv=%0d expect=%0d errors=%0d",
            sent_samples, recv_samples, expect_samples, error_count);
        end else if (error_count == 0) begin
          $display("[MIGO][PASS] sent=%0d recv=%0d flush=%0d", sent_samples, recv_samples, idle_cycles_after_send);
        end else begin
          $display("[MIGO][FAIL] sent=%0d recv=%0d errors=%0d", sent_samples, recv_samples, error_count);
        end
        $fclose(out_fd);
        $finish;
      end
    end
  end
endmodule
