module channelmix_core #(
  parameter int C = 6
) (
  input  logic clk,
  input  logic rst_n,
  input  logic in_valid,
  input  logic signed [31:0] x_in [0:C-1],
  output logic out_valid,
  output logic signed [31:0] x_out [0:C-1]
);
  integer i;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_valid <= 1'b0;
      for (i = 0; i < C; i++) begin
        x_out[i] <= '0;
      end
    end else begin
      out_valid <= in_valid;
      if (in_valid) begin
        for (i = 0; i < C; i++) begin
          x_out[i] <= x_in[i];
        end
      end
    end
  end
endmodule
