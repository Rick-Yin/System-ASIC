`timescale 1ns/1ps

module tb_joint_saif;
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

  string input_vec_path;
  string golden_vec_path;
  string output_vec_path;
  string saif_path;

  rwkvcnn_top u_dut (
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
    in_data = '0;
    out_ready = 1'b1;

    input_frames = 0;
    expect_frames = 0;
    send_idx = 0;
    recv_idx = 0;
    mismatches = 0;
    latency_violations = 0;
    cycles = 0;

    if (!$value$plusargs("INPUT_VEC=%s", input_vec_path)) begin
      input_vec_path = "vsrc/Joint-CFR-DPD/tb/top/vectors/input_packed.vec";
    end
    if (!$value$plusargs("GOLDEN_VEC=%s", golden_vec_path)) begin
      golden_vec_path = "vsrc/Joint-CFR-DPD/tb/top/vectors/golden_output_packed.vec";
    end
    if (!$value$plusargs("OUTPUT_FILE=%s", output_vec_path)) begin
      output_vec_path = "joint_gate_output.vec";
    end
    if (!$value$plusargs("SAIF_FILE=%s", saif_path)) begin
      saif_path = "joint.saif";
    end

    in_fd = $fopen(input_vec_path, "r");
    if (in_fd == 0) begin
      $display("[JOINT][FAIL] cannot open input vector file: %s", input_vec_path);
      $finish;
    end

    exp_fd = $fopen(golden_vec_path, "r");
    if (exp_fd == 0) begin
      $display("[JOINT][FAIL] cannot open golden vector file: %s", golden_vec_path);
      $finish;
    end

    out_fd = $fopen(output_vec_path, "w");
    if (out_fd == 0) begin
      $display("[JOINT][FAIL] cannot open output dump file: %s", output_vec_path);
      $finish;
    end

    begin : read_input_loop
      forever begin
        if (input_frames >= MAX_FRAMES) begin
          $display("[JOINT][FAIL] input frames exceed MAX_FRAMES=%0d", MAX_FRAMES);
          $finish;
        end
        scan_rc = $fscanf(in_fd, "%h\n", input_mem[input_frames]);
        if (scan_rc == -1) begin
          disable read_input_loop;
        end
        if (scan_rc != 1) begin
          $display("[JOINT][FAIL] malformed input vector row, scan_rc=%0d", scan_rc);
          $finish;
        end
        input_frames = input_frames + 1;
      end
    end
    $fclose(in_fd);

    begin : read_expect_loop
      forever begin
        if (expect_frames >= MAX_FRAMES) begin
          $display("[JOINT][FAIL] golden frames exceed MAX_FRAMES=%0d", MAX_FRAMES);
          $finish;
        end
        scan_rc = $fscanf(exp_fd, "%h\n", expect_mem[expect_frames]);
        if (scan_rc == -1) begin
          disable read_expect_loop;
        end
        if (scan_rc != 1) begin
          $display("[JOINT][FAIL] malformed golden vector row, scan_rc=%0d", scan_rc);
          $finish;
        end
        expect_frames = expect_frames + 1;
      end
    end
    $fclose(exp_fd);

    if (input_frames <= 0) begin
      $display("[JOINT][FAIL] empty input vectors");
      $finish;
    end

    if (input_frames != expect_frames) begin
      $display("[JOINT][FAIL] frame count mismatch: input=%0d expect=%0d", input_frames, expect_frames);
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
      in_data <= '0;
      send_idx <= 0;
    end else begin
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
    end else if (out_valid && out_ready) begin
      $fwrite(out_fd, "%h\n", out_data);

      if (recv_idx >= expect_frames) begin
        mismatches <= mismatches + 1;
        $display("[JOINT][ERR] extra output idx=%0d got=%h", recv_idx, out_data);
      end else if (out_data !== $signed(expect_mem[recv_idx])) begin
        mismatches <= mismatches + 1;
        $display("[JOINT][ERR] mismatch idx=%0d got=%h exp=%h", recv_idx, out_data, $signed(expect_mem[recv_idx]));
      end

      if (recv_idx < input_frames) begin
        latency_cycles = cycles - issue_cycle[recv_idx];
        if (latency_cycles > MAX_LATENCY_CYCLES) begin
          latency_violations <= latency_violations + 1;
          $display("[JOINT][ERR] latency violation idx=%0d latency=%0d max=%0d", recv_idx, latency_cycles, MAX_LATENCY_CYCLES);
        end
      end

      recv_idx <= recv_idx + 1;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      cycles <= 0;
    end else begin
      cycles <= cycles + 1;

      if (cycles > TIMEOUT_CYCLES) begin
        $display("[JOINT][FAIL] timeout cycles=%0d send=%0d/%0d recv=%0d/%0d mismatches=%0d latency_viol=%0d",
          cycles, send_idx, input_frames, recv_idx, expect_frames, mismatches, latency_violations);
        stop_and_report();
        $fclose(out_fd);
        $finish;
      end

      if ((send_idx == input_frames) && (recv_idx == expect_frames) && !out_valid) begin
        stop_and_report();
        if ((mismatches == 0) && (latency_violations == 0)) begin
          $display("[JOINT][PASS] frames=%0d mismatches=%0d latency_viol=%0d", expect_frames, mismatches, latency_violations);
        end else begin
          $display("[JOINT][FAIL] frames=%0d mismatches=%0d latency_viol=%0d", expect_frames, mismatches, latency_violations);
        end
        $fclose(out_fd);
        $finish;
      end
    end
  end
endmodule
