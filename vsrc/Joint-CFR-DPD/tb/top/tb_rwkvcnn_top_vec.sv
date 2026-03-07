`timescale 1ns/1ps

module tb_rwkvcnn_top_vec;
  import rwkvcnn_pkg::*;

  localparam int INW = IN_DIM * 32;
  localparam int OUTW = OUT_DIM * 32;
  localparam int MAX_FRAMES = 200000;
  localparam int TIMEOUT_CYCLES = 4000000;
  localparam int MAX_LATENCY_CYCLES = 12;

  logic clk;
  logic rst_n;

  logic in_valid;
  logic in_ready;
  logic signed [INW-1:0] in_data;

  logic out_valid;
  logic out_ready;
  logic signed [OUTW-1:0] out_data;

  logic [INW-1:0] input_mem [0:MAX_FRAMES-1];
  logic [OUTW-1:0] expect_mem [0:MAX_FRAMES-1];

  integer in_fd;
  integer exp_fd;
  integer out_fd;
  integer scan_rc;

  integer input_frames;
  integer expect_frames;
  integer send_idx;
  integer recv_idx;
  integer mismatches;
  integer latency_violations;
  integer issue_cycle [0:MAX_FRAMES-1];
  integer latency_cycles;
  integer cycles;

  rwkvcnn_top dut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_ready(in_ready),
    .in_data(in_data),
    .out_valid(out_valid),
    .out_ready(out_ready),
    .out_data(out_data)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    in_valid = 1'b0;
    in_data = '0;
    out_ready = 1'b1;

    input_frames = 0;
    expect_frames = 0;
    send_idx = 0;
    recv_idx = 0;
    mismatches = 0;
    latency_violations = 0;
    cycles = 0;

    in_fd = $fopen("vsrc/Joint-CFR-DPD/tb/top/vectors/input_packed.vec", "r");
    if (in_fd == 0) begin
      $display("[TOP][FAIL] cannot open input vector file");
      $finish;
    end

    exp_fd = $fopen("vsrc/Joint-CFR-DPD/tb/top/vectors/golden_output_packed.vec", "r");
    if (exp_fd == 0) begin
      $display("[TOP][FAIL] cannot open golden output vector file");
      $finish;
    end

    out_fd = $fopen("vsrc/Joint-CFR-DPD/tb/top/logs/rtl_output_packed.vec", "w");
    if (out_fd == 0) begin
      $display("[TOP][FAIL] cannot open rtl output dump file");
      $finish;
    end

    begin : read_input_loop
      forever begin
        if (input_frames >= MAX_FRAMES) begin
          $display("[TOP][FAIL] input frame exceeds MAX_FRAMES=%0d", MAX_FRAMES);
          $finish;
        end
        scan_rc = $fscanf(in_fd, "%h\n", input_mem[input_frames]);
        if (scan_rc == -1) begin
          disable read_input_loop;
        end
        if (scan_rc != 1) begin
          $display("[TOP][FAIL] malformed input vector row, scan_rc=%0d", scan_rc);
          $finish;
        end
        input_frames = input_frames + 1;
      end
    end
    $fclose(in_fd);

    begin : read_expect_loop
      forever begin
        if (expect_frames >= MAX_FRAMES) begin
          $display("[TOP][FAIL] golden frame exceeds MAX_FRAMES=%0d", MAX_FRAMES);
          $finish;
        end
        scan_rc = $fscanf(exp_fd, "%h\n", expect_mem[expect_frames]);
        if (scan_rc == -1) begin
          disable read_expect_loop;
        end
        if (scan_rc != 1) begin
          $display("[TOP][FAIL] malformed golden row, scan_rc=%0d", scan_rc);
          $finish;
        end
        expect_frames = expect_frames + 1;
      end
    end
    $fclose(exp_fd);

    if (input_frames <= 0) begin
      $display("[TOP][FAIL] empty input vectors");
      $finish;
    end

    if (input_frames != expect_frames) begin
      $display("[TOP][FAIL] frame count mismatch: input=%0d expect=%0d", input_frames, expect_frames);
      $finish;
    end

    repeat (5) @(posedge clk);
    rst_n = 1'b1;
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      in_valid <= 1'b0;
      in_data <= '0;
      send_idx <= 0;
    end else begin
      // Hold input stable until handshake to avoid dropping frames when in_ready deasserts.
      if (in_valid && in_ready) begin
        issue_cycle[send_idx] = cycles;
        send_idx <= send_idx + 1;
        if ((send_idx + 1) < input_frames) begin
          in_valid <= 1'b1;
          in_data <= $signed(input_mem[send_idx + 1]);
        end else begin
          in_valid <= 1'b0;
        end
      end else if (!in_valid && (send_idx < input_frames)) begin
        in_valid <= 1'b1;
        in_data <= $signed(input_mem[send_idx]);
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      recv_idx <= 0;
      mismatches <= 0;
      latency_violations <= 0;
    end else begin
      if (out_valid && out_ready) begin
        $fwrite(out_fd, "%h\n", out_data);

        if (recv_idx >= expect_frames) begin
          mismatches <= mismatches + 1;
          $display("[TOP][ERR] extra output frame idx=%0d got=%h", recv_idx, out_data);
        end else if (out_data !== $signed(expect_mem[recv_idx])) begin
          mismatches <= mismatches + 1;
          $display(
            "[TOP][ERR] mismatch idx=%0d got=%h exp=%h",
            recv_idx,
            out_data,
            $signed(expect_mem[recv_idx])
          );
        end

        if (recv_idx < input_frames) begin
          latency_cycles = cycles - issue_cycle[recv_idx];
          if (latency_cycles > MAX_LATENCY_CYCLES) begin
            latency_violations <= latency_violations + 1;
            $display(
              "[TOP][ERR] latency violation idx=%0d latency=%0d max=%0d",
              recv_idx, latency_cycles, MAX_LATENCY_CYCLES
            );
          end
        end
        recv_idx <= recv_idx + 1;
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      cycles <= 0;
    end else begin
      cycles <= cycles + 1;

      if (cycles > TIMEOUT_CYCLES) begin
        $display(
          "[TOP][FAIL] timeout cycles=%0d send=%0d/%0d recv=%0d/%0d mismatches=%0d latency_viol=%0d",
          cycles, send_idx, input_frames, recv_idx, expect_frames, mismatches, latency_violations
        );
        $fclose(out_fd);
        $finish;
      end

      if ((send_idx == input_frames) && (recv_idx == expect_frames) && !out_valid) begin
        if ((mismatches == 0) && (latency_violations == 0)) begin
          $display(
            "[TOP][PASS] frames=%0d mismatches=%0d latency_viol=%0d max_latency=%0d",
            expect_frames, mismatches, latency_violations, MAX_LATENCY_CYCLES
          );
        end else begin
          $display(
            "[TOP][FAIL] frames=%0d mismatches=%0d latency_viol=%0d max_latency=%0d",
            expect_frames, mismatches, latency_violations, MAX_LATENCY_CYCLES
          );
        end
        $fclose(out_fd);
        $finish;
      end
    end
  end

endmodule
