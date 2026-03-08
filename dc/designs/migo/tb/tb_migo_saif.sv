`timescale 1ns/1ps

module tb_migo_saif;
  localparam int BX = 8;
  localparam int BY = 9;
  localparam int TOTAL_SAMPLES = 512;
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

  string output_path;
  string saif_path;

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
    end else if (sent_samples < TOTAL_SAMPLES) begin
      if (((sent_samples + cycles) % GAP_PERIOD) == 0) begin
        in_valid <= 1'b0;
        x_in <= '0;
      end else begin
        in_valid <= 1'b1;
        x_in <= sample_for_idx(sent_samples);
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

      if ((sent_samples >= TOTAL_SAMPLES) && (idle_cycles_after_send >= FLUSH_CYCLES)) begin
        stop_and_report();
        if (error_count == 0) begin
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
