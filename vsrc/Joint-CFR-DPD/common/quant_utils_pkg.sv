package quant_utils_pkg;

  function automatic logic signed [63:0] qmax_signed64(input int bits);
    logic signed [63:0] v;
    begin
      if (bits <= 1) begin
        v = 64'sd0;
      end else if (bits >= 63) begin
        v = 64'sh3FFF_FFFF_FFFF_FFFF;
      end else begin
        v = (64'sd1 <<< (bits - 1)) - 64'sd1;
      end
      qmax_signed64 = v;
    end
  endfunction

  function automatic logic signed [63:0] qmin_signed64(input int bits);
    logic signed [63:0] v;
    begin
      if (bits <= 1) begin
        v = -64'sd1;
      end else if (bits >= 63) begin
        v = -64'sh4000_0000_0000_0000;
      end else begin
        v = - (64'sd1 <<< (bits - 1));
      end
      qmin_signed64 = v;
    end
  endfunction

  function automatic logic [63:0] qmax_unsigned64(input int bits);
    logic [63:0] v;
    begin
      if (bits <= 0) begin
        v = 64'd0;
      end else if (bits >= 63) begin
        v = 64'h7FFF_FFFF_FFFF_FFFF;
      end else begin
        v = (64'd1 <<< bits) - 64'd1;
      end
      qmax_unsigned64 = v;
    end
  endfunction

  function automatic logic signed [31:0] sat_signed32(input logic signed [63:0] x, input int bits);
    logic signed [63:0] lo, hi, y;
    begin
      lo = qmin_signed64(bits);
      hi = qmax_signed64(bits);
      if (x > hi) begin
        y = hi;
      end else if (x < lo) begin
        y = lo;
      end else begin
        y = x;
      end
      sat_signed32 = y[31:0];
    end
  endfunction

  function automatic logic [31:0] sat_unsigned32(input logic signed [63:0] x, input int bits);
    logic [63:0] hi;
    logic signed [63:0] y;
    begin
      hi = qmax_unsigned64(bits);
      if (x < 0) begin
        y = 64'sd0;
      end else if ($unsigned(x) > hi) begin
        y = $signed(hi);
      end else begin
        y = x;
      end
      sat_unsigned32 = y[31:0];
    end
  endfunction

  function automatic logic signed [63:0] sat_signed64(input logic signed [63:0] x, input int bits);
    logic signed [63:0] lo, hi, y;
    begin
      lo = qmin_signed64(bits);
      hi = qmax_signed64(bits);
      if (x > hi) begin
        y = hi;
      end else if (x < lo) begin
        y = lo;
      end else begin
        y = x;
      end
      sat_signed64 = y;
    end
  endfunction

  function automatic logic [63:0] sat_unsigned64(input logic signed [63:0] x, input int bits);
    logic [63:0] hi;
    logic [63:0] y;
    begin
      hi = qmax_unsigned64(bits);
      if (x < 0) begin
        y = 64'd0;
      end else if ($unsigned(x) > hi) begin
        y = hi;
      end else begin
        y = $unsigned(x);
      end
      sat_unsigned64 = y;
    end
  endfunction

  function automatic logic [63:0] abs64(input logic signed [63:0] x);
    begin
      if (x < 0) begin
        abs64 = $unsigned(-x);
      end else begin
        abs64 = $unsigned(x);
      end
    end
  endfunction

  function automatic logic signed [63:0] rshift_rne64(input logic signed [63:0] x, input int sh);
    logic neg;
    logic [63:0] ax;
    logic [63:0] half;
    logic [63:0] mask;
    logic [63:0] r;
    logic [63:0] q;
    logic [63:0] q2;
    logic inc;
    begin
      if (sh <= 0) begin
        rshift_rne64 = x;
      end else if (sh >= 62) begin
        rshift_rne64 = 64'sd0;
      end else begin
        neg = (x < 0);
        ax = abs64(x);
        half = 64'd1 <<< (sh - 1);
        mask = (64'd1 <<< sh) - 64'd1;
        r = ax & mask;
        q = ax >> sh;
        inc = (r > half) || ((r == half) && ((q & 64'd1) == 64'd1));
        q2 = q + (inc ? 64'd1 : 64'd0);
        if (neg) begin
          rshift_rne64 = -$signed(q2);
        end else begin
          rshift_rne64 = $signed(q2);
        end
      end
    end
  endfunction

  function automatic logic signed [63:0] div_rne64(input logic signed [63:0] x, input logic signed [63:0] d);
    logic neg;
    logic [63:0] ax;
    logic [63:0] ad;
    logic [63:0] q;
    logic [63:0] r;
    logic [63:0] two_r;
    logic inc;
    logic [63:0] q2;
    begin
      if (d == 0) begin
        div_rne64 = 64'sd0;
      end else begin
        neg = ((x < 0) ^ (d < 0));
        ax = abs64(x);
        ad = abs64(d);
        q = ax / ad;
        r = ax - q * ad;
        two_r = r << 1;
        inc = (two_r > ad) || ((two_r == ad) && ((q & 64'd1) == 64'd1));
        q2 = q + (inc ? 64'd1 : 64'd0);
        if (neg) begin
          div_rne64 = -$signed(q2);
        end else begin
          div_rne64 = $signed(q2);
        end
      end
    end
  endfunction

  function automatic int wkv_lut_lookup_idx(
    input logic signed [31:0] delta_i,
    input logic signed [31:0] min_delta_i,
    input logic signed [31:0] step_i,
    input int lut_numel
  );
    int idx;
    logic signed [63:0] q;
    logic signed [63:0] num;
    begin
      if (lut_numel <= 0) begin
        idx = 0;
      end else begin
        num = $signed(delta_i) - $signed(min_delta_i);
        if (step_i == 0) begin
          idx = 0;
        end else begin
          q = div_rne64(num, $signed(step_i));
          idx = q;
        end

        if (idx < 0) begin
          idx = 0;
        end else if (idx >= lut_numel) begin
          idx = lut_numel - 1;
        end
      end
      wkv_lut_lookup_idx = idx;
    end
  endfunction

  function automatic logic signed [31:0] requant_pow2_signed(
    input logic signed [63:0] x,
    input int exp_in,
    input int exp_out,
    input int bits
  );
    logic signed [63:0] y;
    logic signed [63:0] y_shifted;
    int delta;
    begin
      delta = exp_in - exp_out;
      if (delta > 0) begin
        if (delta >= 62) begin
          y = (x < 0) ? qmin_signed64(bits) : qmax_signed64(bits);
        end else begin
          y_shifted = x <<< delta;
          if ((y_shifted >>> delta) != x) begin
            y = (x < 0) ? qmin_signed64(bits) : qmax_signed64(bits);
          end else begin
            y = y_shifted;
          end
        end
      end else if (delta < 0) begin
        y = rshift_rne64(x, -delta);
      end else begin
        y = x;
      end
      requant_pow2_signed = sat_signed32(y, bits);
    end
  endfunction

  function automatic logic [31:0] requant_pow2_unsigned(
    input logic signed [63:0] x,
    input int exp_in,
    input int exp_out,
    input int bits
  );
    logic signed [63:0] y;
    logic signed [63:0] y_shifted;
    int delta;
    begin
      delta = exp_in - exp_out;
      if (delta > 0) begin
        if (delta >= 62) begin
          y = (x < 0) ? 64'sd0 : $signed(qmax_unsigned64(bits));
        end else begin
          y_shifted = x <<< delta;
          if ((y_shifted >>> delta) != x) begin
            y = (x < 0) ? 64'sd0 : $signed(qmax_unsigned64(bits));
          end else begin
            y = y_shifted;
          end
        end
      end else if (delta < 0) begin
        y = rshift_rne64(x, -delta);
      end else begin
        y = x;
      end
      requant_pow2_unsigned = sat_unsigned32(y, bits);
    end
  endfunction

  function automatic logic [31:0] hardsigmoid_int_default(
    input logic signed [31:0] x_i,
    input int exp_x,
    input int gate_bits
  );
    int exp_gate;
    int s;
    logic signed [63:0] xi;
    logic signed [63:0] x_scaled;
    logic signed [63:0] div_term;
    logic signed [63:0] y;
    logic [63:0] offset;
    logic [63:0] cmax;
    begin
      exp_gate = -gate_bits;
      s = exp_x - exp_gate;
      xi = $signed(x_i);

      if (s > 0) begin
        if (s >= 62) begin
          x_scaled = (xi < 0) ? -64'sh4000_0000_0000_0000 : 64'sh3FFF_FFFF_FFFF_FFFF;
        end else begin
          x_scaled = xi <<< s;
        end
      end else if (s < 0) begin
        x_scaled = rshift_rne64(xi, -s);
      end else begin
        x_scaled = xi;
      end

      // Torch hard-sigmoid default: clamp(x/6 + 1/2, 0, 1)
      div_term = div_rne64(x_scaled, 64'sd6);
      offset = (64'd1 <<< gate_bits) >> 1;
      y = div_term + $signed(offset);

      cmax = qmax_unsigned64(gate_bits);
      if (y < 0) begin
        hardsigmoid_int_default = 32'd0;
      end else if ($unsigned(y) > cmax) begin
        hardsigmoid_int_default = cmax[31:0];
      end else begin
        hardsigmoid_int_default = y[31:0];
      end
    end
  endfunction

endpackage
