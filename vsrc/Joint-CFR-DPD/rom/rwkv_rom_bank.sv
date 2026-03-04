module rwkv_rom_bank (
  input  logic [7:0] rom_id,
  input  logic [15:0] addr,
  output logic signed [31:0] rdata
);
  import rwkvcnn_pkg::*;

  always_comb begin
    rdata = rom_read(rom_id, addr);
  end

endmodule
