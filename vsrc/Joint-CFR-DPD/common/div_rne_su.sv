module div_rne_su #(
  parameter int X_WIDTH = 24,
  parameter int D_WIDTH = 24,
  parameter int Q_WIDTH = 32
) (
  input  logic signed [X_WIDTH-1:0] x,
  input  logic [D_WIDTH-1:0] d,
  output logic signed [Q_WIDTH-1:0] q
);
  logic neg;
  logic [X_WIDTH-1:0] ax;
  logic [D_WIDTH:0] rem;
  logic [X_WIDTH-1:0] quot;
  logic [D_WIDTH:0] two_r;
  logic inc;
  logic [X_WIDTH-1:0] quot_rounded;
  logic signed [Q_WIDTH-1:0] q_mag;
  integer bit_idx;

  always @* begin
    q = '0;
    neg = 1'b0;
    ax = '0;
    rem = '0;
    quot = '0;
    two_r = '0;
    inc = 1'b0;
    quot_rounded = '0;
    q_mag = '0;
    bit_idx = 0;

    if (d != '0) begin
      neg = (x < 0);
      if (neg) begin
        ax = $unsigned(-x);
      end else begin
        ax = $unsigned(x);
      end

      for (bit_idx = X_WIDTH - 1; bit_idx >= 0; bit_idx = bit_idx - 1) begin
        rem = {rem[D_WIDTH-1:0], ax[bit_idx]};
        if (rem >= {1'b0, d}) begin
          rem = rem - {1'b0, d};
          quot[bit_idx] = 1'b1;
        end
      end

      two_r = {rem[D_WIDTH-1:0], 1'b0};
      inc = (two_r > {1'b0, d}) || ((two_r == {1'b0, d}) && quot[0]);
      quot_rounded = quot + (inc ? {{(X_WIDTH-1){1'b0}}, 1'b1} : {X_WIDTH{1'b0}});
      q_mag[X_WIDTH-1:0] = quot_rounded;

      if (neg) begin
        q = -q_mag;
      end else begin
        q = q_mag;
      end
    end
  end
endmodule
