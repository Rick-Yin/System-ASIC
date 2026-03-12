`timescale 1ns/1ps

module tb_rwkvcnn_top_vec;
  import rwkvcnn_pkg::*;

  localparam int S_IDLE = 0;
  localparam int S_IP_WAIT = 2;
  localparam int S_ATT_TS = 3;
  localparam int S_ATT_QK_WAIT = 5;
  localparam int S_ATT_QV_WAIT = 7;
  localparam int S_ATT_QR_WAIT = 9;
  localparam int S_ATT_GATE = 10;
  localparam int S_ATT_WKV = 11;
  localparam int S_ATT_DIV = 12;
  localparam int S_ATT_OUT_WAIT = 14;
  localparam int S_FFN_TS = 15;
  localparam int S_FFN_KEY_WAIT = 17;
  localparam int S_FFN_VAL_WAIT = 19;
  localparam int S_FFN_REC_WAIT = 21;
  localparam int S_FFN_OUT = 22;
  localparam int S_OP_WAIT = 24;
  localparam int S_OUT = 25;

  localparam int LIN_NONE = 0;
  localparam int LIN_IP = 1;
  localparam int LIN_ATT_KEY = 2;
  localparam int LIN_ATT_VALUE = 3;
  localparam int LIN_ATT_REC = 4;
  localparam int LIN_ATT_OUT = 5;
  localparam int LIN_FFN_KEY = 6;
  localparam int LIN_FFN_VAL = 7;
  localparam int LIN_FFN_REC = 8;
  localparam int LIN_OP = 9;

  localparam int INW = IN_DIM * 32;
  localparam int OUTW = OUT_DIM * 32;
  localparam int MAX_FRAMES = 200000;
  localparam int TIMEOUT_CYCLES = 4000000;
  localparam int IP_LINEAR_CYCLES = 1 + (MODEL_DIM * IN_DIM);
  localparam int ATT_LINEAR_CYCLES = 4 * (1 + (MODEL_DIM * MODEL_DIM));
  localparam int FFN_LINEAR_CYCLES =
    (1 + (HIDDEN_SZ * MODEL_DIM)) +
    (1 + (MODEL_DIM * HIDDEN_SZ)) +
    (1 + (MODEL_DIM * MODEL_DIM));
  localparam int BLOCK_NONLINEAR_CYCLES = 6;
  // Each block-local linear op spends one extra cycle in its *_WAIT state because
  // lin_done is observed by the top-level FSM on the following clock edge.
  localparam int BLOCK_LINEAR_WAIT_EXIT_CYCLES = 7;
  localparam int BLOCK_CYCLES =
    ATT_LINEAR_CYCLES + FFN_LINEAR_CYCLES + BLOCK_NONLINEAR_CYCLES + BLOCK_LINEAR_WAIT_EXIT_CYCLES;
  localparam int OP_LINEAR_CYCLES = 1 + (OUT_DIM * MODEL_DIM);
  localparam int EDGE_WAIT_EXIT_CYCLES = 2;
  localparam int MAX_LATENCY_CYCLES =
    1 + IP_LINEAR_CYCLES + (LAYER_NUM * BLOCK_CYCLES) + OP_LINEAR_CYCLES + EDGE_WAIT_EXIT_CYCLES;

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
  integer plusargs_rc;

  integer input_frames;
  integer expect_frames;
  integer send_idx;
  integer recv_idx;
  integer mismatches;
  integer latency_violations;
  integer issue_cycle [0:MAX_FRAMES-1];
  integer latency_cycles;
  integer cycles;
  integer req_frames;
  integer req_max_latency;
  integer req_trace_progress;
  integer req_enable_wave;
  integer req_progress_cycles;
  integer req_timeout_cycles;
  integer max_latency_seen;
  integer max_latency_idx;
  integer coverage_fail;
  integer lin_ip_runs;
  integer lin_att_key_runs;
  integer lin_att_value_runs;
  integer lin_att_rec_runs;
  integer lin_att_out_runs;
  integer lin_ffn_key_runs;
  integer lin_ffn_val_runs;
  integer lin_ffn_rec_runs;
  integer lin_op_runs;
  logic [4:0] prev_state;
  reg [1023:0] input_vec_path;
  reg [1023:0] golden_vec_path;
  reg [1023:0] output_vec_path;
  reg [1023:0] dump_vcd_path;

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

  function automatic [8*20-1:0] state_name(input logic [4:0] state_id);
    begin
      case (state_id)
        S_IDLE: state_name = "S_IDLE";
        S_IP_WAIT: state_name = "S_IP_WAIT";
        S_ATT_TS: state_name = "S_ATT_TS";
        S_ATT_QK_WAIT: state_name = "S_ATT_QK_WAIT";
        S_ATT_QV_WAIT: state_name = "S_ATT_QV_WAIT";
        S_ATT_QR_WAIT: state_name = "S_ATT_QR_WAIT";
        S_ATT_GATE: state_name = "S_ATT_GATE";
        S_ATT_WKV: state_name = "S_ATT_WKV";
        S_ATT_DIV: state_name = "S_ATT_DIV";
        S_ATT_OUT_WAIT: state_name = "S_ATT_OUT_WAIT";
        S_FFN_TS: state_name = "S_FFN_TS";
        S_FFN_KEY_WAIT: state_name = "S_FFN_KEY_WAIT";
        S_FFN_VAL_WAIT: state_name = "S_FFN_VAL_WAIT";
        S_FFN_REC_WAIT: state_name = "S_FFN_REC_WAIT";
        S_FFN_OUT: state_name = "S_FFN_OUT";
        S_OP_WAIT: state_name = "S_OP_WAIT";
        S_OUT: state_name = "S_OUT";
        default: state_name = "S_OTHER";
      endcase
    end
  endfunction

  function automatic [8*20-1:0] lin_stage_name(input logic [3:0] stage_id);
    begin
      case (stage_id)
        LIN_NONE: lin_stage_name = "LIN_NONE";
        LIN_IP: lin_stage_name = "LIN_IP";
        LIN_ATT_KEY: lin_stage_name = "LIN_ATT_KEY";
        LIN_ATT_VALUE: lin_stage_name = "LIN_ATT_VALUE";
        LIN_ATT_REC: lin_stage_name = "LIN_ATT_REC";
        LIN_ATT_OUT: lin_stage_name = "LIN_ATT_OUT";
        LIN_FFN_KEY: lin_stage_name = "LIN_FFN_KEY";
        LIN_FFN_VAL: lin_stage_name = "LIN_FFN_VAL";
        LIN_FFN_REC: lin_stage_name = "LIN_FFN_REC";
        LIN_OP: lin_stage_name = "LIN_OP";
        default: lin_stage_name = "LIN_OTHER";
      endcase
    end
  endfunction

  task automatic dump_runtime_status(input [8*24-1:0] reason);
    begin
      $display(
        "[TOP][DBG] reason=%0s cycle=%0d send=%0d/%0d recv=%0d/%0d state=%0s blk=%0d lin=%0s lin_busy=%0b lin_done=%0b in_valid=%0b in_ready=%0b out_valid=%0b",
        reason,
        cycles,
        send_idx,
        input_frames,
        recv_idx,
        expect_frames,
        state_name(dut.state),
        dut.blk_idx,
        lin_stage_name(dut.lin_stage),
        dut.lin_busy,
        dut.lin_done,
        in_valid,
        in_ready,
        out_valid
      );
      $display(
        "[TOP][DBG] w_addr=%0d b_addr=%0d work0=%0d out0=%0d",
        dut.lin_w_addr,
        dut.lin_b_addr,
        dut.work_vec[0],
        dut.out_vec[0]
      );
    end
  endtask

  task automatic print_stage_summary;
    begin
      $display(
        "[TOP][COV] lin ip=%0d att_key=%0d att_value=%0d att_rec=%0d att_out=%0d ffn_key=%0d ffn_val=%0d ffn_rec=%0d op=%0d",
        lin_ip_runs,
        lin_att_key_runs,
        lin_att_value_runs,
        lin_att_rec_runs,
        lin_att_out_runs,
        lin_ffn_key_runs,
        lin_ffn_val_runs,
        lin_ffn_rec_runs,
        lin_op_runs
      );
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
    req_frames = 0;
    req_max_latency = MAX_LATENCY_CYCLES;
    req_trace_progress = 0;
    req_enable_wave = 0;
    req_progress_cycles = 100000;
    req_timeout_cycles = TIMEOUT_CYCLES;
    max_latency_seen = 0;
    max_latency_idx = -1;
    coverage_fail = 0;
    lin_ip_runs = 0;
    lin_att_key_runs = 0;
    lin_att_value_runs = 0;
    lin_att_rec_runs = 0;
    lin_att_out_runs = 0;
    lin_ffn_key_runs = 0;
    lin_ffn_val_runs = 0;
    lin_ffn_rec_runs = 0;
    lin_op_runs = 0;
    prev_state = S_IDLE;

    input_vec_path = "vsrc/Joint-CFR-DPD/tb/top/vectors/input_packed.vec";
    golden_vec_path = "vsrc/Joint-CFR-DPD/tb/top/vectors/golden_output_packed.vec";
    output_vec_path = "vsrc/Joint-CFR-DPD/tb/top/logs/rtl_output_packed.vec";
    dump_vcd_path = "vsrc/Joint-CFR-DPD/tb/top/logs/tb_rwkvcnn_top_vec.vcd";
    plusargs_rc = $value$plusargs("INPUT_VEC_FILE=%s", input_vec_path);
    plusargs_rc = $value$plusargs("GOLDEN_VEC_FILE=%s", golden_vec_path);
    plusargs_rc = $value$plusargs("OUTPUT_VEC_FILE=%s", output_vec_path);
    plusargs_rc = $value$plusargs("NUM_TEST_FRAMES=%d", req_frames);
    plusargs_rc = $value$plusargs("MAX_FRAME_LATENCY=%d", req_max_latency);
    plusargs_rc = $value$plusargs("TRACE_PROGRESS=%d", req_trace_progress);
    plusargs_rc = $value$plusargs("ENABLE_WAVE=%d", req_enable_wave);
    plusargs_rc = $value$plusargs("PROGRESS_CYCLES=%d", req_progress_cycles);
    plusargs_rc = $value$plusargs("TIMEOUT_CYCLES=%d", req_timeout_cycles);
    plusargs_rc = $value$plusargs("DUMP_VCD_FILE=%s", dump_vcd_path);

    if (req_enable_wave != 0) begin
      $dumpfile(dump_vcd_path);
      $dumpvars(0, tb_rwkvcnn_top_vec);
    end

    in_fd = $fopen(input_vec_path, "r");
    if (in_fd == 0) begin
      $display("[TOP][FAIL] cannot open input vector file");
      $finish;
    end

    exp_fd = $fopen(golden_vec_path, "r");
    if (exp_fd == 0) begin
      $display("[TOP][FAIL] cannot open golden output vector file");
      $finish;
    end

    out_fd = $fopen(output_vec_path, "w");
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

    if (req_frames > 0) begin
      if (req_frames > input_frames) begin
        $display("[TOP][FAIL] NUM_TEST_FRAMES=%0d exceeds loaded frames=%0d", req_frames, input_frames);
        $finish;
      end
      input_frames = req_frames;
      expect_frames = req_frames;
    end

    $display(
      "[TOP][CFG] frames=%0d max_latency=%0d trace=%0d wave=%0d",
      input_frames,
      req_max_latency,
      req_trace_progress,
      req_enable_wave
    );

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
          dump_runtime_status("extra_output");
        end else if (out_data !== $signed(expect_mem[recv_idx])) begin
          mismatches <= mismatches + 1;
          $display(
            "[TOP][ERR] mismatch idx=%0d got=%h exp=%h",
            recv_idx,
            out_data,
            $signed(expect_mem[recv_idx])
          );
          dump_runtime_status("mismatch");
        end

        if (recv_idx < input_frames) begin
          latency_cycles = cycles - issue_cycle[recv_idx];
          if (latency_cycles > max_latency_seen) begin
            max_latency_seen <= latency_cycles;
            max_latency_idx <= recv_idx;
          end
          if (latency_cycles > req_max_latency) begin
            latency_violations <= latency_violations + 1;
            $display(
              "[TOP][ERR] latency violation idx=%0d latency=%0d max=%0d",
              recv_idx, latency_cycles, req_max_latency
            );
            dump_runtime_status("latency");
          end
        end
        recv_idx <= recv_idx + 1;
      end
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      cycles <= 0;
      prev_state <= S_IDLE;
      lin_ip_runs <= 0;
      lin_att_key_runs <= 0;
      lin_att_value_runs <= 0;
      lin_att_rec_runs <= 0;
      lin_att_out_runs <= 0;
      lin_ffn_key_runs <= 0;
      lin_ffn_val_runs <= 0;
      lin_ffn_rec_runs <= 0;
      lin_op_runs <= 0;
      max_latency_seen <= 0;
      max_latency_idx <= -1;
    end else begin
      cycles <= cycles + 1;

      if (dut.state !== prev_state) begin
        if (req_trace_progress != 0) begin
          $display(
            "[TOP][STATE] cycle=%0d send=%0d recv=%0d %0s->%0s blk=%0d",
            cycles,
            send_idx,
            recv_idx,
            state_name(prev_state),
            state_name(dut.state),
            dut.blk_idx
          );
        end
        prev_state <= dut.state;
      end

      if (dut.lin_done) begin
        case (dut.lin_stage)
          LIN_IP: lin_ip_runs <= lin_ip_runs + 1;
          LIN_ATT_KEY: lin_att_key_runs <= lin_att_key_runs + 1;
          LIN_ATT_VALUE: lin_att_value_runs <= lin_att_value_runs + 1;
          LIN_ATT_REC: lin_att_rec_runs <= lin_att_rec_runs + 1;
          LIN_ATT_OUT: lin_att_out_runs <= lin_att_out_runs + 1;
          LIN_FFN_KEY: lin_ffn_key_runs <= lin_ffn_key_runs + 1;
          LIN_FFN_VAL: lin_ffn_val_runs <= lin_ffn_val_runs + 1;
          LIN_FFN_REC: lin_ffn_rec_runs <= lin_ffn_rec_runs + 1;
          LIN_OP: lin_op_runs <= lin_op_runs + 1;
          default: begin
          end
        endcase

        if (req_trace_progress != 0) begin
          $display(
            "[TOP][LIN] cycle=%0d stage=%0s blk=%0d w_addr=%0d b_addr=%0d",
            cycles,
            lin_stage_name(dut.lin_stage),
            dut.blk_idx,
            dut.lin_w_addr,
            dut.lin_b_addr
          );
        end
      end

      if ((req_trace_progress != 0) && (req_progress_cycles > 0) && (cycles != 0) && ((cycles % req_progress_cycles) == 0)) begin
        $display(
          "[TOP][PROGRESS] cycle=%0d send=%0d/%0d recv=%0d/%0d state=%0s blk=%0d",
          cycles,
          send_idx,
          input_frames,
          recv_idx,
          expect_frames,
          state_name(dut.state),
          dut.blk_idx
        );
      end

      if (cycles > req_timeout_cycles) begin
        $display(
          "[TOP][FAIL] timeout cycles=%0d send=%0d/%0d recv=%0d/%0d mismatches=%0d latency_viol=%0d limit=%0d",
          cycles, send_idx, input_frames, recv_idx, expect_frames, mismatches, latency_violations, req_timeout_cycles
        );
        print_stage_summary();
        dump_runtime_status("timeout");
        $fclose(out_fd);
        $finish;
      end

      if ((send_idx == input_frames) && (recv_idx == expect_frames) && !out_valid) begin
        coverage_fail = 0;
        if ((lin_ip_runs == 0) || (lin_att_key_runs == 0) || (lin_att_value_runs == 0) ||
            (lin_att_rec_runs == 0) || (lin_att_out_runs == 0) || (lin_ffn_key_runs == 0) ||
            (lin_ffn_val_runs == 0) || (lin_ffn_rec_runs == 0) || (lin_op_runs == 0)) begin
          coverage_fail = 1;
          $display("[TOP][ERR] missing linear stage coverage");
        end
        print_stage_summary();
        if ((mismatches == 0) && (latency_violations == 0) && (coverage_fail == 0)) begin
          $display(
            "[TOP][PASS] frames=%0d mismatches=%0d latency_viol=%0d max_latency=%0d observed_max_latency=%0d max_latency_idx=%0d",
            expect_frames, mismatches, latency_violations, req_max_latency, max_latency_seen, max_latency_idx
          );
        end else begin
          $display(
            "[TOP][FAIL] frames=%0d mismatches=%0d latency_viol=%0d max_latency=%0d observed_max_latency=%0d max_latency_idx=%0d",
            expect_frames, mismatches, latency_violations, req_max_latency, max_latency_seen, max_latency_idx
          );
          dump_runtime_status("final_fail");
        end
        $fclose(out_fd);
        $finish;
      end
    end
  end

endmodule
