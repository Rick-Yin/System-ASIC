module rwkv_rom #(
  parameter int ROM_ID = 0
)(
  input  logic [15:0] addr,
  output logic signed [31:0] rdata
);
  import rwkvcnn_pkg::*;

  generate
    if (ROM_ID == ROM_ID_INPUT_PROJ_W) begin : gen_input_proj_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < INPUT_PROJ_W_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd329;
            16'd1: rdata = -32'sd653;
            16'd2: rdata = 32'sd367;
            16'd3: rdata = -32'sd416;
            16'd4: rdata = -32'sd1045;
            16'd5: rdata = 32'sd1144;
            16'd6: rdata = -32'sd1267;
            16'd7: rdata = -32'sd960;
            16'd8: rdata = -32'sd452;
            16'd9: rdata = 32'sd7;
            16'd10: rdata = 32'sd488;
            16'd11: rdata = -32'sd238;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_INPUT_PROJ_B) begin : gen_input_proj_b
      always_comb begin
        rdata = 32'sd0;
        if (addr < INPUT_PROJ_B_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd55;
            16'd1: rdata = -32'sd22;
            16'd2: rdata = 32'sd18;
            16'd3: rdata = 32'sd66;
            16'd4: rdata = -32'sd16;
            16'd5: rdata = 32'sd29;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_W) begin : gen_blocks_0_att_time_shift_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_ATT_TIME_SHIFT_W_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd7;
            16'd1: rdata = 32'sd5;
            16'd2: rdata = 32'sd72;
            16'd3: rdata = -32'sd99;
            16'd4: rdata = -32'sd29;
            16'd5: rdata = 32'sd80;
            16'd6: rdata = 32'sd125;
            16'd7: rdata = 32'sd18;
            16'd8: rdata = -32'sd32;
            16'd9: rdata = -32'sd7;
            16'd10: rdata = 32'sd22;
            16'd11: rdata = -32'sd114;
            16'd12: rdata = -32'sd88;
            16'd13: rdata = 32'sd24;
            16'd14: rdata = -32'sd31;
            16'd15: rdata = -32'sd118;
            16'd16: rdata = -32'sd62;
            16'd17: rdata = 32'sd66;
            16'd18: rdata = -32'sd66;
            16'd19: rdata = 32'sd49;
            16'd20: rdata = 32'sd106;
            16'd21: rdata = -32'sd8;
            16'd22: rdata = -32'sd50;
            16'd23: rdata = -32'sd99;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_B) begin : gen_blocks_0_att_time_shift_b
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_ATT_TIME_SHIFT_B_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd15;
            16'd1: rdata = 32'sd32;
            16'd2: rdata = -32'sd123;
            16'd3: rdata = -32'sd11;
            16'd4: rdata = -32'sd140;
            16'd5: rdata = 32'sd119;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_ATT_KEY_W) begin : gen_blocks_0_att_key_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_ATT_KEY_W_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd2;
            16'd1: rdata = 32'sd4;
            16'd2: rdata = -32'sd1;
            16'd3: rdata = -32'sd2;
            16'd4: rdata = 32'sd1;
            16'd5: rdata = 32'sd1;
            16'd6: rdata = 32'sd2;
            16'd7: rdata = 32'sd2;
            16'd8: rdata = -32'sd3;
            16'd9: rdata = 32'sd2;
            16'd10: rdata = 32'sd0;
            16'd11: rdata = -32'sd1;
            16'd12: rdata = 32'sd2;
            16'd13: rdata = 32'sd2;
            16'd14: rdata = -32'sd2;
            16'd15: rdata = -32'sd1;
            16'd16: rdata = 32'sd3;
            16'd17: rdata = 32'sd1;
            16'd18: rdata = 32'sd2;
            16'd19: rdata = -32'sd2;
            16'd20: rdata = -32'sd1;
            16'd21: rdata = 32'sd3;
            16'd22: rdata = 32'sd2;
            16'd23: rdata = 32'sd3;
            16'd24: rdata = -32'sd2;
            16'd25: rdata = -32'sd2;
            16'd26: rdata = 32'sd0;
            16'd27: rdata = -32'sd2;
            16'd28: rdata = 32'sd2;
            16'd29: rdata = 32'sd2;
            16'd30: rdata = 32'sd1;
            16'd31: rdata = -32'sd1;
            16'd32: rdata = 32'sd2;
            16'd33: rdata = -32'sd1;
            16'd34: rdata = 32'sd4;
            16'd35: rdata = -32'sd4;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_ATT_VALUE_W) begin : gen_blocks_0_att_value_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_ATT_VALUE_W_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd110;
            16'd1: rdata = -32'sd44;
            16'd2: rdata = 32'sd106;
            16'd3: rdata = 32'sd35;
            16'd4: rdata = 32'sd64;
            16'd5: rdata = -32'sd90;
            16'd6: rdata = 32'sd14;
            16'd7: rdata = -32'sd14;
            16'd8: rdata = 32'sd34;
            16'd9: rdata = 32'sd71;
            16'd10: rdata = 32'sd40;
            16'd11: rdata = 32'sd0;
            16'd12: rdata = 32'sd0;
            16'd13: rdata = -32'sd68;
            16'd14: rdata = -32'sd49;
            16'd15: rdata = 32'sd59;
            16'd16: rdata = -32'sd52;
            16'd17: rdata = 32'sd81;
            16'd18: rdata = -32'sd79;
            16'd19: rdata = -32'sd43;
            16'd20: rdata = 32'sd25;
            16'd21: rdata = -32'sd89;
            16'd22: rdata = 32'sd31;
            16'd23: rdata = -32'sd38;
            16'd24: rdata = -32'sd41;
            16'd25: rdata = -32'sd9;
            16'd26: rdata = 32'sd108;
            16'd27: rdata = 32'sd83;
            16'd28: rdata = -32'sd45;
            16'd29: rdata = 32'sd13;
            16'd30: rdata = -32'sd57;
            16'd31: rdata = -32'sd85;
            16'd32: rdata = 32'sd18;
            16'd33: rdata = -32'sd25;
            16'd34: rdata = -32'sd65;
            16'd35: rdata = -32'sd85;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_ATT_RECEPTANCE_W) begin : gen_blocks_0_att_receptance_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_ATT_RECEPTANCE_W_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = 32'sd2;
            16'd2: rdata = -32'sd4;
            16'd3: rdata = -32'sd4;
            16'd4: rdata = 32'sd0;
            16'd5: rdata = -32'sd2;
            16'd6: rdata = -32'sd3;
            16'd7: rdata = -32'sd2;
            16'd8: rdata = 32'sd0;
            16'd9: rdata = -32'sd2;
            16'd10: rdata = -32'sd2;
            16'd11: rdata = 32'sd0;
            16'd12: rdata = -32'sd3;
            16'd13: rdata = 32'sd1;
            16'd14: rdata = -32'sd4;
            16'd15: rdata = -32'sd3;
            16'd16: rdata = 32'sd0;
            16'd17: rdata = -32'sd1;
            16'd18: rdata = -32'sd3;
            16'd19: rdata = 32'sd1;
            16'd20: rdata = 32'sd1;
            16'd21: rdata = 32'sd3;
            16'd22: rdata = -32'sd1;
            16'd23: rdata = -32'sd2;
            16'd24: rdata = -32'sd1;
            16'd25: rdata = 32'sd0;
            16'd26: rdata = 32'sd2;
            16'd27: rdata = -32'sd3;
            16'd28: rdata = 32'sd0;
            16'd29: rdata = 32'sd2;
            16'd30: rdata = -32'sd2;
            16'd31: rdata = -32'sd2;
            16'd32: rdata = 32'sd2;
            16'd33: rdata = -32'sd4;
            16'd34: rdata = 32'sd1;
            16'd35: rdata = -32'sd3;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_ATT_OUTPUT_W) begin : gen_blocks_0_att_output_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_ATT_OUTPUT_W_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd53;
            16'd1: rdata = -32'sd88;
            16'd2: rdata = 32'sd89;
            16'd3: rdata = -32'sd115;
            16'd4: rdata = -32'sd86;
            16'd5: rdata = -32'sd18;
            16'd6: rdata = 32'sd110;
            16'd7: rdata = -32'sd74;
            16'd8: rdata = -32'sd58;
            16'd9: rdata = 32'sd79;
            16'd10: rdata = 32'sd4;
            16'd11: rdata = 32'sd36;
            16'd12: rdata = -32'sd94;
            16'd13: rdata = -32'sd36;
            16'd14: rdata = -32'sd72;
            16'd15: rdata = 32'sd74;
            16'd16: rdata = 32'sd64;
            16'd17: rdata = -32'sd63;
            16'd18: rdata = 32'sd21;
            16'd19: rdata = -32'sd6;
            16'd20: rdata = -32'sd58;
            16'd21: rdata = -32'sd75;
            16'd22: rdata = -32'sd17;
            16'd23: rdata = 32'sd93;
            16'd24: rdata = -32'sd89;
            16'd25: rdata = -32'sd79;
            16'd26: rdata = -32'sd14;
            16'd27: rdata = 32'sd19;
            16'd28: rdata = 32'sd7;
            16'd29: rdata = -32'sd5;
            16'd30: rdata = -32'sd16;
            16'd31: rdata = -32'sd61;
            16'd32: rdata = -32'sd33;
            16'd33: rdata = -32'sd63;
            16'd34: rdata = 32'sd103;
            16'd35: rdata = -32'sd93;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_W) begin : gen_blocks_0_ffn_time_shift_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_FFN_TIME_SHIFT_W_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd3;
            16'd1: rdata = -32'sd3;
            16'd2: rdata = -32'sd1;
            16'd3: rdata = 32'sd4;
            16'd4: rdata = 32'sd4;
            16'd5: rdata = -32'sd2;
            16'd6: rdata = 32'sd0;
            16'd7: rdata = 32'sd2;
            16'd8: rdata = 32'sd0;
            16'd9: rdata = 32'sd2;
            16'd10: rdata = -32'sd1;
            16'd11: rdata = -32'sd3;
            16'd12: rdata = 32'sd1;
            16'd13: rdata = -32'sd2;
            16'd14: rdata = 32'sd1;
            16'd15: rdata = -32'sd1;
            16'd16: rdata = 32'sd3;
            16'd17: rdata = 32'sd5;
            16'd18: rdata = 32'sd4;
            16'd19: rdata = -32'sd4;
            16'd20: rdata = -32'sd1;
            16'd21: rdata = -32'sd1;
            16'd22: rdata = -32'sd1;
            16'd23: rdata = 32'sd4;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_B) begin : gen_blocks_0_ffn_time_shift_b
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_FFN_TIME_SHIFT_B_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = -32'sd4;
            16'd2: rdata = -32'sd3;
            16'd3: rdata = -32'sd2;
            16'd4: rdata = 32'sd3;
            16'd5: rdata = -32'sd4;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_FFN_KEY_W) begin : gen_blocks_0_ffn_key_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_FFN_KEY_W_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd42;
            16'd1: rdata = -32'sd69;
            16'd2: rdata = 32'sd40;
            16'd3: rdata = 32'sd27;
            16'd4: rdata = -32'sd16;
            16'd5: rdata = -32'sd3;
            16'd6: rdata = 32'sd22;
            16'd7: rdata = -32'sd16;
            16'd8: rdata = -32'sd33;
            16'd9: rdata = -32'sd18;
            16'd10: rdata = 32'sd13;
            16'd11: rdata = 32'sd51;
            16'd12: rdata = -32'sd32;
            16'd13: rdata = 32'sd31;
            16'd14: rdata = 32'sd38;
            16'd15: rdata = -32'sd27;
            16'd16: rdata = 32'sd47;
            16'd17: rdata = 32'sd42;
            16'd18: rdata = -32'sd14;
            16'd19: rdata = -32'sd35;
            16'd20: rdata = 32'sd41;
            16'd21: rdata = -32'sd41;
            16'd22: rdata = 32'sd37;
            16'd23: rdata = -32'sd3;
            16'd24: rdata = 32'sd37;
            16'd25: rdata = -32'sd58;
            16'd26: rdata = -32'sd26;
            16'd27: rdata = 32'sd28;
            16'd28: rdata = 32'sd33;
            16'd29: rdata = -32'sd63;
            16'd30: rdata = -32'sd44;
            16'd31: rdata = -32'sd55;
            16'd32: rdata = -32'sd56;
            16'd33: rdata = -32'sd36;
            16'd34: rdata = 32'sd30;
            16'd35: rdata = 32'sd8;
            16'd36: rdata = 32'sd30;
            16'd37: rdata = 32'sd53;
            16'd38: rdata = 32'sd25;
            16'd39: rdata = -32'sd44;
            16'd40: rdata = 32'sd28;
            16'd41: rdata = 32'sd18;
            16'd42: rdata = 32'sd59;
            16'd43: rdata = -32'sd71;
            16'd44: rdata = 32'sd57;
            16'd45: rdata = 32'sd47;
            16'd46: rdata = -32'sd28;
            16'd47: rdata = -32'sd15;
            16'd48: rdata = 32'sd55;
            16'd49: rdata = -32'sd50;
            16'd50: rdata = 32'sd33;
            16'd51: rdata = 32'sd30;
            16'd52: rdata = 32'sd30;
            16'd53: rdata = 32'sd36;
            16'd54: rdata = 32'sd42;
            16'd55: rdata = 32'sd46;
            16'd56: rdata = -32'sd6;
            16'd57: rdata = 32'sd42;
            16'd58: rdata = -32'sd50;
            16'd59: rdata = -32'sd27;
            16'd60: rdata = 32'sd5;
            16'd61: rdata = -32'sd19;
            16'd62: rdata = 32'sd66;
            16'd63: rdata = 32'sd6;
            16'd64: rdata = 32'sd35;
            16'd65: rdata = 32'sd35;
            16'd66: rdata = -32'sd44;
            16'd67: rdata = -32'sd24;
            16'd68: rdata = 32'sd13;
            16'd69: rdata = 32'sd7;
            16'd70: rdata = 32'sd44;
            16'd71: rdata = -32'sd36;
            16'd72: rdata = -32'sd26;
            16'd73: rdata = 32'sd25;
            16'd74: rdata = -32'sd31;
            16'd75: rdata = -32'sd53;
            16'd76: rdata = 32'sd40;
            16'd77: rdata = 32'sd55;
            16'd78: rdata = -32'sd13;
            16'd79: rdata = -32'sd8;
            16'd80: rdata = -32'sd33;
            16'd81: rdata = -32'sd36;
            16'd82: rdata = 32'sd30;
            16'd83: rdata = -32'sd30;
            16'd84: rdata = 32'sd25;
            16'd85: rdata = -32'sd60;
            16'd86: rdata = -32'sd26;
            16'd87: rdata = -32'sd14;
            16'd88: rdata = 32'sd12;
            16'd89: rdata = 32'sd62;
            16'd90: rdata = 32'sd28;
            16'd91: rdata = 32'sd5;
            16'd92: rdata = -32'sd41;
            16'd93: rdata = -32'sd51;
            16'd94: rdata = -32'sd33;
            16'd95: rdata = 32'sd22;
            16'd96: rdata = 32'sd45;
            16'd97: rdata = -32'sd15;
            16'd98: rdata = -32'sd10;
            16'd99: rdata = -32'sd40;
            16'd100: rdata = 32'sd16;
            16'd101: rdata = 32'sd43;
            16'd102: rdata = -32'sd41;
            16'd103: rdata = -32'sd51;
            16'd104: rdata = 32'sd62;
            16'd105: rdata = -32'sd1;
            16'd106: rdata = 32'sd14;
            16'd107: rdata = -32'sd7;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_FFN_RECEPTANCE_W) begin : gen_blocks_0_ffn_receptance_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_FFN_RECEPTANCE_W_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = -32'sd3;
            16'd2: rdata = -32'sd4;
            16'd3: rdata = 32'sd1;
            16'd4: rdata = 32'sd1;
            16'd5: rdata = -32'sd1;
            16'd6: rdata = -32'sd2;
            16'd7: rdata = -32'sd3;
            16'd8: rdata = -32'sd2;
            16'd9: rdata = -32'sd4;
            16'd10: rdata = 32'sd3;
            16'd11: rdata = 32'sd1;
            16'd12: rdata = -32'sd3;
            16'd13: rdata = -32'sd2;
            16'd14: rdata = 32'sd1;
            16'd15: rdata = -32'sd3;
            16'd16: rdata = 32'sd2;
            16'd17: rdata = 32'sd0;
            16'd18: rdata = -32'sd2;
            16'd19: rdata = 32'sd0;
            16'd20: rdata = -32'sd1;
            16'd21: rdata = 32'sd1;
            16'd22: rdata = -32'sd1;
            16'd23: rdata = 32'sd0;
            16'd24: rdata = 32'sd3;
            16'd25: rdata = -32'sd4;
            16'd26: rdata = 32'sd1;
            16'd27: rdata = 32'sd3;
            16'd28: rdata = 32'sd0;
            16'd29: rdata = 32'sd2;
            16'd30: rdata = 32'sd1;
            16'd31: rdata = 32'sd2;
            16'd32: rdata = -32'sd1;
            16'd33: rdata = 32'sd2;
            16'd34: rdata = 32'sd0;
            16'd35: rdata = 32'sd0;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_FFN_VALUE_W) begin : gen_blocks_0_ffn_value_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_FFN_VALUE_W_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd50;
            16'd1: rdata = -32'sd28;
            16'd2: rdata = 32'sd22;
            16'd3: rdata = 32'sd96;
            16'd4: rdata = -32'sd15;
            16'd5: rdata = 32'sd6;
            16'd6: rdata = 32'sd15;
            16'd7: rdata = 32'sd61;
            16'd8: rdata = 32'sd45;
            16'd9: rdata = -32'sd20;
            16'd10: rdata = -32'sd22;
            16'd11: rdata = 32'sd76;
            16'd12: rdata = -32'sd70;
            16'd13: rdata = 32'sd31;
            16'd14: rdata = -32'sd90;
            16'd15: rdata = -32'sd45;
            16'd16: rdata = -32'sd23;
            16'd17: rdata = 32'sd41;
            16'd18: rdata = 32'sd37;
            16'd19: rdata = -32'sd25;
            16'd20: rdata = -32'sd17;
            16'd21: rdata = 32'sd54;
            16'd22: rdata = 32'sd85;
            16'd23: rdata = -32'sd70;
            16'd24: rdata = -32'sd7;
            16'd25: rdata = 32'sd11;
            16'd26: rdata = 32'sd69;
            16'd27: rdata = 32'sd54;
            16'd28: rdata = 32'sd27;
            16'd29: rdata = 32'sd8;
            16'd30: rdata = -32'sd74;
            16'd31: rdata = 32'sd35;
            16'd32: rdata = -32'sd39;
            16'd33: rdata = 32'sd24;
            16'd34: rdata = 32'sd7;
            16'd35: rdata = 32'sd84;
            16'd36: rdata = 32'sd74;
            16'd37: rdata = -32'sd85;
            16'd38: rdata = 32'sd10;
            16'd39: rdata = 32'sd19;
            16'd40: rdata = 32'sd57;
            16'd41: rdata = -32'sd30;
            16'd42: rdata = 32'sd4;
            16'd43: rdata = -32'sd2;
            16'd44: rdata = -32'sd38;
            16'd45: rdata = 32'sd22;
            16'd46: rdata = 32'sd48;
            16'd47: rdata = 32'sd31;
            16'd48: rdata = 32'sd0;
            16'd49: rdata = -32'sd18;
            16'd50: rdata = -32'sd18;
            16'd51: rdata = -32'sd59;
            16'd52: rdata = -32'sd14;
            16'd53: rdata = 32'sd23;
            16'd54: rdata = 32'sd75;
            16'd55: rdata = 32'sd8;
            16'd56: rdata = 32'sd43;
            16'd57: rdata = 32'sd45;
            16'd58: rdata = 32'sd60;
            16'd59: rdata = -32'sd86;
            16'd60: rdata = -32'sd39;
            16'd61: rdata = 32'sd46;
            16'd62: rdata = 32'sd16;
            16'd63: rdata = -32'sd46;
            16'd64: rdata = 32'sd6;
            16'd65: rdata = 32'sd2;
            16'd66: rdata = -32'sd98;
            16'd67: rdata = 32'sd0;
            16'd68: rdata = 32'sd4;
            16'd69: rdata = -32'sd7;
            16'd70: rdata = -32'sd58;
            16'd71: rdata = -32'sd20;
            16'd72: rdata = -32'sd80;
            16'd73: rdata = 32'sd46;
            16'd74: rdata = 32'sd48;
            16'd75: rdata = -32'sd63;
            16'd76: rdata = -32'sd56;
            16'd77: rdata = -32'sd2;
            16'd78: rdata = -32'sd1;
            16'd79: rdata = -32'sd100;
            16'd80: rdata = -32'sd79;
            16'd81: rdata = 32'sd59;
            16'd82: rdata = -32'sd59;
            16'd83: rdata = -32'sd39;
            16'd84: rdata = 32'sd17;
            16'd85: rdata = -32'sd44;
            16'd86: rdata = 32'sd25;
            16'd87: rdata = 32'sd41;
            16'd88: rdata = -32'sd5;
            16'd89: rdata = -32'sd36;
            16'd90: rdata = 32'sd28;
            16'd91: rdata = -32'sd105;
            16'd92: rdata = 32'sd36;
            16'd93: rdata = 32'sd84;
            16'd94: rdata = 32'sd64;
            16'd95: rdata = -32'sd52;
            16'd96: rdata = 32'sd28;
            16'd97: rdata = -32'sd16;
            16'd98: rdata = 32'sd7;
            16'd99: rdata = -32'sd12;
            16'd100: rdata = 32'sd8;
            16'd101: rdata = 32'sd52;
            16'd102: rdata = -32'sd61;
            16'd103: rdata = -32'sd17;
            16'd104: rdata = -32'sd55;
            16'd105: rdata = -32'sd79;
            16'd106: rdata = -32'sd32;
            16'd107: rdata = -32'sd19;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_W) begin : gen_blocks_1_att_time_shift_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_ATT_TIME_SHIFT_W_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd2;
            16'd1: rdata = 32'sd1;
            16'd2: rdata = 32'sd3;
            16'd3: rdata = -32'sd3;
            16'd4: rdata = 32'sd0;
            16'd5: rdata = 32'sd1;
            16'd6: rdata = 32'sd3;
            16'd7: rdata = 32'sd4;
            16'd8: rdata = -32'sd3;
            16'd9: rdata = -32'sd4;
            16'd10: rdata = -32'sd4;
            16'd11: rdata = -32'sd3;
            16'd12: rdata = 32'sd3;
            16'd13: rdata = 32'sd2;
            16'd14: rdata = 32'sd5;
            16'd15: rdata = 32'sd5;
            16'd16: rdata = 32'sd0;
            16'd17: rdata = -32'sd3;
            16'd18: rdata = 32'sd4;
            16'd19: rdata = 32'sd3;
            16'd20: rdata = 32'sd2;
            16'd21: rdata = -32'sd2;
            16'd22: rdata = 32'sd3;
            16'd23: rdata = 32'sd1;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_B) begin : gen_blocks_1_att_time_shift_b
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_ATT_TIME_SHIFT_B_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd3;
            16'd1: rdata = 32'sd3;
            16'd2: rdata = 32'sd3;
            16'd3: rdata = -32'sd4;
            16'd4: rdata = -32'sd2;
            16'd5: rdata = 32'sd3;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_ATT_KEY_W) begin : gen_blocks_1_att_key_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_ATT_KEY_W_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = -32'sd2;
            16'd2: rdata = 32'sd3;
            16'd3: rdata = 32'sd0;
            16'd4: rdata = 32'sd2;
            16'd5: rdata = -32'sd2;
            16'd6: rdata = 32'sd1;
            16'd7: rdata = -32'sd1;
            16'd8: rdata = -32'sd1;
            16'd9: rdata = -32'sd1;
            16'd10: rdata = -32'sd1;
            16'd11: rdata = 32'sd2;
            16'd12: rdata = -32'sd1;
            16'd13: rdata = 32'sd2;
            16'd14: rdata = 32'sd1;
            16'd15: rdata = 32'sd0;
            16'd16: rdata = -32'sd2;
            16'd17: rdata = -32'sd3;
            16'd18: rdata = -32'sd1;
            16'd19: rdata = -32'sd4;
            16'd20: rdata = 32'sd0;
            16'd21: rdata = 32'sd0;
            16'd22: rdata = 32'sd0;
            16'd23: rdata = -32'sd2;
            16'd24: rdata = 32'sd2;
            16'd25: rdata = 32'sd1;
            16'd26: rdata = 32'sd1;
            16'd27: rdata = -32'sd1;
            16'd28: rdata = 32'sd3;
            16'd29: rdata = 32'sd2;
            16'd30: rdata = -32'sd3;
            16'd31: rdata = -32'sd1;
            16'd32: rdata = 32'sd0;
            16'd33: rdata = -32'sd1;
            16'd34: rdata = 32'sd3;
            16'd35: rdata = -32'sd1;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_ATT_VALUE_W) begin : gen_blocks_1_att_value_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_ATT_VALUE_W_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd102;
            16'd1: rdata = 32'sd12;
            16'd2: rdata = 32'sd11;
            16'd3: rdata = -32'sd42;
            16'd4: rdata = -32'sd22;
            16'd5: rdata = 32'sd17;
            16'd6: rdata = 32'sd45;
            16'd7: rdata = -32'sd3;
            16'd8: rdata = 32'sd82;
            16'd9: rdata = -32'sd75;
            16'd10: rdata = 32'sd35;
            16'd11: rdata = 32'sd100;
            16'd12: rdata = -32'sd28;
            16'd13: rdata = 32'sd93;
            16'd14: rdata = -32'sd34;
            16'd15: rdata = -32'sd93;
            16'd16: rdata = -32'sd77;
            16'd17: rdata = 32'sd63;
            16'd18: rdata = -32'sd26;
            16'd19: rdata = 32'sd34;
            16'd20: rdata = 32'sd119;
            16'd21: rdata = 32'sd39;
            16'd22: rdata = -32'sd1;
            16'd23: rdata = 32'sd9;
            16'd24: rdata = -32'sd88;
            16'd25: rdata = -32'sd65;
            16'd26: rdata = -32'sd107;
            16'd27: rdata = -32'sd91;
            16'd28: rdata = 32'sd3;
            16'd29: rdata = 32'sd48;
            16'd30: rdata = -32'sd33;
            16'd31: rdata = -32'sd90;
            16'd32: rdata = 32'sd40;
            16'd33: rdata = -32'sd61;
            16'd34: rdata = -32'sd36;
            16'd35: rdata = -32'sd74;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_ATT_RECEPTANCE_W) begin : gen_blocks_1_att_receptance_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_ATT_RECEPTANCE_W_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd2;
            16'd1: rdata = 32'sd2;
            16'd2: rdata = -32'sd4;
            16'd3: rdata = -32'sd3;
            16'd4: rdata = 32'sd2;
            16'd5: rdata = -32'sd1;
            16'd6: rdata = -32'sd1;
            16'd7: rdata = -32'sd1;
            16'd8: rdata = 32'sd1;
            16'd9: rdata = -32'sd2;
            16'd10: rdata = 32'sd0;
            16'd11: rdata = 32'sd2;
            16'd12: rdata = 32'sd1;
            16'd13: rdata = 32'sd2;
            16'd14: rdata = -32'sd4;
            16'd15: rdata = 32'sd1;
            16'd16: rdata = 32'sd0;
            16'd17: rdata = 32'sd1;
            16'd18: rdata = -32'sd3;
            16'd19: rdata = 32'sd2;
            16'd20: rdata = 32'sd2;
            16'd21: rdata = -32'sd1;
            16'd22: rdata = 32'sd1;
            16'd23: rdata = 32'sd2;
            16'd24: rdata = -32'sd1;
            16'd25: rdata = -32'sd1;
            16'd26: rdata = 32'sd4;
            16'd27: rdata = 32'sd0;
            16'd28: rdata = -32'sd2;
            16'd29: rdata = -32'sd1;
            16'd30: rdata = 32'sd1;
            16'd31: rdata = -32'sd1;
            16'd32: rdata = -32'sd2;
            16'd33: rdata = 32'sd2;
            16'd34: rdata = 32'sd1;
            16'd35: rdata = 32'sd0;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_ATT_OUTPUT_W) begin : gen_blocks_1_att_output_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_ATT_OUTPUT_W_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd1;
            16'd1: rdata = -32'sd18;
            16'd2: rdata = 32'sd34;
            16'd3: rdata = -32'sd16;
            16'd4: rdata = -32'sd77;
            16'd5: rdata = 32'sd4;
            16'd6: rdata = -32'sd21;
            16'd7: rdata = 32'sd10;
            16'd8: rdata = -32'sd9;
            16'd9: rdata = 32'sd25;
            16'd10: rdata = -32'sd102;
            16'd11: rdata = 32'sd24;
            16'd12: rdata = 32'sd46;
            16'd13: rdata = -32'sd2;
            16'd14: rdata = -32'sd59;
            16'd15: rdata = 32'sd5;
            16'd16: rdata = -32'sd25;
            16'd17: rdata = -32'sd74;
            16'd18: rdata = -32'sd86;
            16'd19: rdata = 32'sd107;
            16'd20: rdata = 32'sd102;
            16'd21: rdata = 32'sd59;
            16'd22: rdata = 32'sd52;
            16'd23: rdata = 32'sd59;
            16'd24: rdata = 32'sd67;
            16'd25: rdata = 32'sd58;
            16'd26: rdata = -32'sd38;
            16'd27: rdata = -32'sd20;
            16'd28: rdata = 32'sd95;
            16'd29: rdata = -32'sd11;
            16'd30: rdata = -32'sd82;
            16'd31: rdata = -32'sd73;
            16'd32: rdata = 32'sd82;
            16'd33: rdata = 32'sd92;
            16'd34: rdata = 32'sd60;
            16'd35: rdata = 32'sd32;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_W) begin : gen_blocks_1_ffn_time_shift_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_FFN_TIME_SHIFT_W_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd18;
            16'd1: rdata = -32'sd62;
            16'd2: rdata = -32'sd43;
            16'd3: rdata = -32'sd64;
            16'd4: rdata = 32'sd38;
            16'd5: rdata = -32'sd10;
            16'd6: rdata = -32'sd32;
            16'd7: rdata = 32'sd6;
            16'd8: rdata = -32'sd54;
            16'd9: rdata = -32'sd57;
            16'd10: rdata = 32'sd0;
            16'd11: rdata = 32'sd0;
            16'd12: rdata = -32'sd21;
            16'd13: rdata = -32'sd57;
            16'd14: rdata = 32'sd46;
            16'd15: rdata = 32'sd18;
            16'd16: rdata = 32'sd29;
            16'd17: rdata = -32'sd36;
            16'd18: rdata = 32'sd41;
            16'd19: rdata = -32'sd6;
            16'd20: rdata = -32'sd41;
            16'd21: rdata = -32'sd49;
            16'd22: rdata = 32'sd29;
            16'd23: rdata = 32'sd44;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_B) begin : gen_blocks_1_ffn_time_shift_b
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_FFN_TIME_SHIFT_B_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd38;
            16'd1: rdata = 32'sd52;
            16'd2: rdata = -32'sd55;
            16'd3: rdata = 32'sd84;
            16'd4: rdata = 32'sd44;
            16'd5: rdata = 32'sd30;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_FFN_KEY_W) begin : gen_blocks_1_ffn_key_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_FFN_KEY_W_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = 32'sd41;
            16'd2: rdata = -32'sd53;
            16'd3: rdata = 32'sd15;
            16'd4: rdata = -32'sd10;
            16'd5: rdata = 32'sd6;
            16'd6: rdata = 32'sd44;
            16'd7: rdata = -32'sd16;
            16'd8: rdata = -32'sd51;
            16'd9: rdata = -32'sd23;
            16'd10: rdata = -32'sd52;
            16'd11: rdata = 32'sd44;
            16'd12: rdata = -32'sd19;
            16'd13: rdata = -32'sd41;
            16'd14: rdata = 32'sd0;
            16'd15: rdata = -32'sd30;
            16'd16: rdata = -32'sd22;
            16'd17: rdata = 32'sd21;
            16'd18: rdata = -32'sd45;
            16'd19: rdata = 32'sd38;
            16'd20: rdata = 32'sd50;
            16'd21: rdata = 32'sd5;
            16'd22: rdata = 32'sd35;
            16'd23: rdata = -32'sd40;
            16'd24: rdata = 32'sd15;
            16'd25: rdata = 32'sd72;
            16'd26: rdata = -32'sd9;
            16'd27: rdata = 32'sd58;
            16'd28: rdata = -32'sd74;
            16'd29: rdata = 32'sd13;
            16'd30: rdata = -32'sd10;
            16'd31: rdata = -32'sd19;
            16'd32: rdata = 32'sd46;
            16'd33: rdata = -32'sd12;
            16'd34: rdata = -32'sd3;
            16'd35: rdata = -32'sd62;
            16'd36: rdata = 32'sd23;
            16'd37: rdata = -32'sd40;
            16'd38: rdata = -32'sd11;
            16'd39: rdata = 32'sd22;
            16'd40: rdata = 32'sd38;
            16'd41: rdata = 32'sd13;
            16'd42: rdata = -32'sd36;
            16'd43: rdata = -32'sd1;
            16'd44: rdata = 32'sd48;
            16'd45: rdata = 32'sd24;
            16'd46: rdata = 32'sd64;
            16'd47: rdata = 32'sd1;
            16'd48: rdata = 32'sd31;
            16'd49: rdata = -32'sd31;
            16'd50: rdata = 32'sd50;
            16'd51: rdata = -32'sd28;
            16'd52: rdata = -32'sd8;
            16'd53: rdata = -32'sd7;
            16'd54: rdata = -32'sd11;
            16'd55: rdata = 32'sd14;
            16'd56: rdata = 32'sd43;
            16'd57: rdata = -32'sd38;
            16'd58: rdata = 32'sd10;
            16'd59: rdata = -32'sd40;
            16'd60: rdata = 32'sd7;
            16'd61: rdata = 32'sd48;
            16'd62: rdata = 32'sd32;
            16'd63: rdata = 32'sd42;
            16'd64: rdata = 32'sd28;
            16'd65: rdata = -32'sd3;
            16'd66: rdata = 32'sd8;
            16'd67: rdata = -32'sd9;
            16'd68: rdata = 32'sd54;
            16'd69: rdata = 32'sd29;
            16'd70: rdata = -32'sd22;
            16'd71: rdata = 32'sd35;
            16'd72: rdata = -32'sd17;
            16'd73: rdata = 32'sd21;
            16'd74: rdata = 32'sd9;
            16'd75: rdata = 32'sd2;
            16'd76: rdata = 32'sd26;
            16'd77: rdata = -32'sd47;
            16'd78: rdata = -32'sd51;
            16'd79: rdata = -32'sd22;
            16'd80: rdata = -32'sd1;
            16'd81: rdata = 32'sd44;
            16'd82: rdata = 32'sd48;
            16'd83: rdata = -32'sd39;
            16'd84: rdata = -32'sd23;
            16'd85: rdata = 32'sd5;
            16'd86: rdata = -32'sd47;
            16'd87: rdata = 32'sd1;
            16'd88: rdata = -32'sd38;
            16'd89: rdata = 32'sd41;
            16'd90: rdata = -32'sd32;
            16'd91: rdata = -32'sd6;
            16'd92: rdata = -32'sd11;
            16'd93: rdata = -32'sd2;
            16'd94: rdata = 32'sd59;
            16'd95: rdata = -32'sd43;
            16'd96: rdata = -32'sd5;
            16'd97: rdata = 32'sd51;
            16'd98: rdata = 32'sd34;
            16'd99: rdata = -32'sd27;
            16'd100: rdata = -32'sd23;
            16'd101: rdata = -32'sd32;
            16'd102: rdata = -32'sd40;
            16'd103: rdata = 32'sd42;
            16'd104: rdata = -32'sd29;
            16'd105: rdata = 32'sd39;
            16'd106: rdata = -32'sd45;
            16'd107: rdata = -32'sd3;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_FFN_RECEPTANCE_W) begin : gen_blocks_1_ffn_receptance_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_FFN_RECEPTANCE_W_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd7;
            16'd1: rdata = 32'sd121;
            16'd2: rdata = 32'sd80;
            16'd3: rdata = 32'sd48;
            16'd4: rdata = 32'sd41;
            16'd5: rdata = -32'sd85;
            16'd6: rdata = 32'sd55;
            16'd7: rdata = -32'sd43;
            16'd8: rdata = -32'sd56;
            16'd9: rdata = -32'sd99;
            16'd10: rdata = -32'sd115;
            16'd11: rdata = 32'sd73;
            16'd12: rdata = -32'sd14;
            16'd13: rdata = 32'sd120;
            16'd14: rdata = 32'sd103;
            16'd15: rdata = 32'sd63;
            16'd16: rdata = 32'sd69;
            16'd17: rdata = -32'sd49;
            16'd18: rdata = 32'sd44;
            16'd19: rdata = 32'sd81;
            16'd20: rdata = 32'sd4;
            16'd21: rdata = -32'sd16;
            16'd22: rdata = -32'sd3;
            16'd23: rdata = 32'sd16;
            16'd24: rdata = -32'sd114;
            16'd25: rdata = 32'sd70;
            16'd26: rdata = -32'sd110;
            16'd27: rdata = 32'sd72;
            16'd28: rdata = -32'sd30;
            16'd29: rdata = -32'sd54;
            16'd30: rdata = -32'sd85;
            16'd31: rdata = 32'sd122;
            16'd32: rdata = -32'sd113;
            16'd33: rdata = 32'sd74;
            16'd34: rdata = 32'sd86;
            16'd35: rdata = 32'sd50;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_FFN_VALUE_W) begin : gen_blocks_1_ffn_value_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_FFN_VALUE_W_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd19;
            16'd1: rdata = 32'sd14;
            16'd2: rdata = 32'sd35;
            16'd3: rdata = 32'sd35;
            16'd4: rdata = -32'sd17;
            16'd5: rdata = 32'sd1;
            16'd6: rdata = -32'sd6;
            16'd7: rdata = 32'sd39;
            16'd8: rdata = 32'sd21;
            16'd9: rdata = -32'sd3;
            16'd10: rdata = -32'sd39;
            16'd11: rdata = 32'sd35;
            16'd12: rdata = 32'sd66;
            16'd13: rdata = 32'sd72;
            16'd14: rdata = -32'sd84;
            16'd15: rdata = 32'sd58;
            16'd16: rdata = -32'sd52;
            16'd17: rdata = -32'sd92;
            16'd18: rdata = -32'sd75;
            16'd19: rdata = -32'sd25;
            16'd20: rdata = 32'sd7;
            16'd21: rdata = -32'sd22;
            16'd22: rdata = 32'sd10;
            16'd23: rdata = 32'sd95;
            16'd24: rdata = 32'sd14;
            16'd25: rdata = 32'sd80;
            16'd26: rdata = -32'sd14;
            16'd27: rdata = -32'sd5;
            16'd28: rdata = 32'sd14;
            16'd29: rdata = 32'sd34;
            16'd30: rdata = 32'sd1;
            16'd31: rdata = -32'sd27;
            16'd32: rdata = -32'sd9;
            16'd33: rdata = 32'sd46;
            16'd34: rdata = 32'sd67;
            16'd35: rdata = -32'sd64;
            16'd36: rdata = -32'sd22;
            16'd37: rdata = -32'sd42;
            16'd38: rdata = 32'sd21;
            16'd39: rdata = 32'sd23;
            16'd40: rdata = 32'sd9;
            16'd41: rdata = 32'sd66;
            16'd42: rdata = 32'sd62;
            16'd43: rdata = 32'sd58;
            16'd44: rdata = 32'sd18;
            16'd45: rdata = 32'sd78;
            16'd46: rdata = -32'sd14;
            16'd47: rdata = 32'sd52;
            16'd48: rdata = 32'sd98;
            16'd49: rdata = 32'sd78;
            16'd50: rdata = -32'sd68;
            16'd51: rdata = -32'sd7;
            16'd52: rdata = 32'sd43;
            16'd53: rdata = -32'sd24;
            16'd54: rdata = -32'sd11;
            16'd55: rdata = 32'sd6;
            16'd56: rdata = 32'sd43;
            16'd57: rdata = 32'sd12;
            16'd58: rdata = -32'sd57;
            16'd59: rdata = 32'sd60;
            16'd60: rdata = 32'sd28;
            16'd61: rdata = -32'sd4;
            16'd62: rdata = 32'sd20;
            16'd63: rdata = -32'sd23;
            16'd64: rdata = 32'sd7;
            16'd65: rdata = -32'sd12;
            16'd66: rdata = 32'sd96;
            16'd67: rdata = -32'sd34;
            16'd68: rdata = -32'sd73;
            16'd69: rdata = -32'sd32;
            16'd70: rdata = 32'sd38;
            16'd71: rdata = -32'sd89;
            16'd72: rdata = 32'sd59;
            16'd73: rdata = -32'sd26;
            16'd74: rdata = -32'sd31;
            16'd75: rdata = -32'sd53;
            16'd76: rdata = 32'sd45;
            16'd77: rdata = 32'sd21;
            16'd78: rdata = 32'sd46;
            16'd79: rdata = -32'sd30;
            16'd80: rdata = -32'sd72;
            16'd81: rdata = -32'sd40;
            16'd82: rdata = -32'sd42;
            16'd83: rdata = -32'sd15;
            16'd84: rdata = -32'sd16;
            16'd85: rdata = 32'sd14;
            16'd86: rdata = 32'sd62;
            16'd87: rdata = -32'sd6;
            16'd88: rdata = -32'sd42;
            16'd89: rdata = 32'sd40;
            16'd90: rdata = -32'sd32;
            16'd91: rdata = -32'sd46;
            16'd92: rdata = -32'sd13;
            16'd93: rdata = 32'sd14;
            16'd94: rdata = -32'sd92;
            16'd95: rdata = 32'sd74;
            16'd96: rdata = 32'sd5;
            16'd97: rdata = -32'sd27;
            16'd98: rdata = 32'sd61;
            16'd99: rdata = -32'sd12;
            16'd100: rdata = 32'sd40;
            16'd101: rdata = 32'sd60;
            16'd102: rdata = 32'sd41;
            16'd103: rdata = 32'sd34;
            16'd104: rdata = -32'sd11;
            16'd105: rdata = 32'sd68;
            16'd106: rdata = 32'sd0;
            16'd107: rdata = -32'sd75;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_OUTPUT_PROJ_W) begin : gen_output_proj_w
      always_comb begin
        rdata = 32'sd0;
        if (addr < OUTPUT_PROJ_W_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd15;
            16'd1: rdata = -32'sd44;
            16'd2: rdata = -32'sd55;
            16'd3: rdata = -32'sd56;
            16'd4: rdata = 32'sd48;
            16'd5: rdata = -32'sd56;
            16'd6: rdata = -32'sd92;
            16'd7: rdata = -32'sd46;
            16'd8: rdata = 32'sd56;
            16'd9: rdata = -32'sd4;
            16'd10: rdata = -32'sd21;
            16'd11: rdata = 32'sd34;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_OUTPUT_PROJ_B) begin : gen_output_proj_b
      always_comb begin
        rdata = 32'sd0;
        if (addr < OUTPUT_PROJ_B_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd3;
            16'd1: rdata = 32'sd4;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_ATT_TIME_MIX_K) begin : gen_blocks_0_att_time_mix_k
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_ATT_TIME_MIX_K_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = 32'sd73;
            16'd2: rdata = 32'sd97;
            16'd3: rdata = 32'sd152;
            16'd4: rdata = 32'sd217;
            16'd5: rdata = 32'sd255;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_ATT_TIME_MIX_V) begin : gen_blocks_0_att_time_mix_v
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_ATT_TIME_MIX_V_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = 32'sd40;
            16'd2: rdata = 32'sd133;
            16'd3: rdata = 32'sd159;
            16'd4: rdata = 32'sd182;
            16'd5: rdata = 32'sd227;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_ATT_TIME_MIX_R) begin : gen_blocks_0_att_time_mix_r
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_ATT_TIME_MIX_R_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = 32'sd141;
            16'd2: rdata = 32'sd194;
            16'd3: rdata = 32'sd216;
            16'd4: rdata = 32'sd218;
            16'd5: rdata = 32'sd228;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_ATT_ONE_TM) begin : gen_blocks_0_att_one_tm
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_ATT_ONE_TM_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd255;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_FFN_TIME_MIX_K) begin : gen_blocks_0_ffn_time_mix_k
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_FFN_TIME_MIX_K_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = 32'sd26;
            16'd2: rdata = 32'sd129;
            16'd3: rdata = 32'sd183;
            16'd4: rdata = 32'sd158;
            16'd5: rdata = 32'sd255;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_FFN_TIME_MIX_R) begin : gen_blocks_0_ffn_time_mix_r
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_FFN_TIME_MIX_R_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = 32'sd42;
            16'd2: rdata = 32'sd77;
            16'd3: rdata = 32'sd186;
            16'd4: rdata = 32'sd160;
            16'd5: rdata = 32'sd246;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_FFN_ONE_TM) begin : gen_blocks_0_ffn_one_tm
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_FFN_ONE_TM_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd255;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_ATT_TIME_MIX_K) begin : gen_blocks_1_att_time_mix_k
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_ATT_TIME_MIX_K_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd8;
            16'd1: rdata = 32'sd104;
            16'd2: rdata = 32'sd154;
            16'd3: rdata = 32'sd173;
            16'd4: rdata = 32'sd254;
            16'd5: rdata = 32'sd226;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_ATT_TIME_MIX_V) begin : gen_blocks_1_att_time_mix_v
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_ATT_TIME_MIX_V_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd55;
            16'd1: rdata = 32'sd163;
            16'd2: rdata = 32'sd212;
            16'd3: rdata = 32'sd255;
            16'd4: rdata = 32'sd255;
            16'd5: rdata = 32'sd255;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_ATT_TIME_MIX_R) begin : gen_blocks_1_att_time_mix_r
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_ATT_TIME_MIX_R_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd12;
            16'd1: rdata = 32'sd205;
            16'd2: rdata = 32'sd236;
            16'd3: rdata = 32'sd250;
            16'd4: rdata = 32'sd220;
            16'd5: rdata = 32'sd247;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_ATT_ONE_TM) begin : gen_blocks_1_att_one_tm
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_ATT_ONE_TM_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd255;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_FFN_TIME_MIX_K) begin : gen_blocks_1_ffn_time_mix_k
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_FFN_TIME_MIX_K_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = 32'sd103;
            16'd2: rdata = 32'sd179;
            16'd3: rdata = 32'sd153;
            16'd4: rdata = 32'sd255;
            16'd5: rdata = 32'sd255;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_FFN_TIME_MIX_R) begin : gen_blocks_1_ffn_time_mix_r
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_FFN_TIME_MIX_R_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = 32'sd71;
            16'd2: rdata = 32'sd173;
            16'd3: rdata = 32'sd158;
            16'd4: rdata = 32'sd217;
            16'd5: rdata = 32'sd255;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_FFN_ONE_TM) begin : gen_blocks_1_ffn_one_tm
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_FFN_ONE_TM_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd255;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_WKV_LUT) begin : gen_wkv_lut
      always_comb begin
        rdata = 32'sd0;
        if (addr < WKV_LUT_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = 32'sd0;
            16'd2: rdata = 32'sd0;
            16'd3: rdata = 32'sd0;
            16'd4: rdata = 32'sd0;
            16'd5: rdata = 32'sd1;
            16'd6: rdata = 32'sd1;
            16'd7: rdata = 32'sd1;
            16'd8: rdata = 32'sd1;
            16'd9: rdata = 32'sd1;
            16'd10: rdata = 32'sd1;
            16'd11: rdata = 32'sd1;
            16'd12: rdata = 32'sd1;
            16'd13: rdata = 32'sd1;
            16'd14: rdata = 32'sd1;
            16'd15: rdata = 32'sd1;
            16'd16: rdata = 32'sd1;
            16'd17: rdata = 32'sd1;
            16'd18: rdata = 32'sd1;
            16'd19: rdata = 32'sd1;
            16'd20: rdata = 32'sd1;
            16'd21: rdata = 32'sd1;
            16'd22: rdata = 32'sd1;
            16'd23: rdata = 32'sd1;
            16'd24: rdata = 32'sd1;
            16'd25: rdata = 32'sd1;
            16'd26: rdata = 32'sd1;
            16'd27: rdata = 32'sd1;
            16'd28: rdata = 32'sd2;
            16'd29: rdata = 32'sd2;
            16'd30: rdata = 32'sd2;
            16'd31: rdata = 32'sd2;
            16'd32: rdata = 32'sd2;
            16'd33: rdata = 32'sd2;
            16'd34: rdata = 32'sd2;
            16'd35: rdata = 32'sd2;
            16'd36: rdata = 32'sd2;
            16'd37: rdata = 32'sd2;
            16'd38: rdata = 32'sd2;
            16'd39: rdata = 32'sd3;
            16'd40: rdata = 32'sd3;
            16'd41: rdata = 32'sd3;
            16'd42: rdata = 32'sd3;
            16'd43: rdata = 32'sd3;
            16'd44: rdata = 32'sd3;
            16'd45: rdata = 32'sd3;
            16'd46: rdata = 32'sd4;
            16'd47: rdata = 32'sd4;
            16'd48: rdata = 32'sd4;
            16'd49: rdata = 32'sd4;
            16'd50: rdata = 32'sd4;
            16'd51: rdata = 32'sd4;
            16'd52: rdata = 32'sd5;
            16'd53: rdata = 32'sd5;
            16'd54: rdata = 32'sd5;
            16'd55: rdata = 32'sd5;
            16'd56: rdata = 32'sd6;
            16'd57: rdata = 32'sd6;
            16'd58: rdata = 32'sd6;
            16'd59: rdata = 32'sd6;
            16'd60: rdata = 32'sd7;
            16'd61: rdata = 32'sd7;
            16'd62: rdata = 32'sd7;
            16'd63: rdata = 32'sd8;
            16'd64: rdata = 32'sd8;
            16'd65: rdata = 32'sd9;
            16'd66: rdata = 32'sd9;
            16'd67: rdata = 32'sd9;
            16'd68: rdata = 32'sd10;
            16'd69: rdata = 32'sd10;
            16'd70: rdata = 32'sd11;
            16'd71: rdata = 32'sd11;
            16'd72: rdata = 32'sd12;
            16'd73: rdata = 32'sd12;
            16'd74: rdata = 32'sd13;
            16'd75: rdata = 32'sd14;
            16'd76: rdata = 32'sd14;
            16'd77: rdata = 32'sd15;
            16'd78: rdata = 32'sd16;
            16'd79: rdata = 32'sd17;
            16'd80: rdata = 32'sd17;
            16'd81: rdata = 32'sd18;
            16'd82: rdata = 32'sd19;
            16'd83: rdata = 32'sd20;
            16'd84: rdata = 32'sd21;
            16'd85: rdata = 32'sd22;
            16'd86: rdata = 32'sd23;
            16'd87: rdata = 32'sd24;
            16'd88: rdata = 32'sd25;
            16'd89: rdata = 32'sd27;
            16'd90: rdata = 32'sd28;
            16'd91: rdata = 32'sd29;
            16'd92: rdata = 32'sd31;
            16'd93: rdata = 32'sd32;
            16'd94: rdata = 32'sd34;
            16'd95: rdata = 32'sd35;
            16'd96: rdata = 32'sd37;
            16'd97: rdata = 32'sd39;
            16'd98: rdata = 32'sd41;
            16'd99: rdata = 32'sd42;
            16'd100: rdata = 32'sd45;
            16'd101: rdata = 32'sd47;
            16'd102: rdata = 32'sd49;
            16'd103: rdata = 32'sd51;
            16'd104: rdata = 32'sd54;
            16'd105: rdata = 32'sd56;
            16'd106: rdata = 32'sd59;
            16'd107: rdata = 32'sd62;
            16'd108: rdata = 32'sd65;
            16'd109: rdata = 32'sd68;
            16'd110: rdata = 32'sd71;
            16'd111: rdata = 32'sd75;
            16'd112: rdata = 32'sd78;
            16'd113: rdata = 32'sd82;
            16'd114: rdata = 32'sd86;
            16'd115: rdata = 32'sd90;
            16'd116: rdata = 32'sd95;
            16'd117: rdata = 32'sd99;
            16'd118: rdata = 32'sd104;
            16'd119: rdata = 32'sd109;
            16'd120: rdata = 32'sd114;
            16'd121: rdata = 32'sd120;
            16'd122: rdata = 32'sd125;
            16'd123: rdata = 32'sd131;
            16'd124: rdata = 32'sd138;
            16'd125: rdata = 32'sd144;
            16'd126: rdata = 32'sd151;
            16'd127: rdata = 32'sd159;
            16'd128: rdata = 32'sd166;
            16'd129: rdata = 32'sd174;
            16'd130: rdata = 32'sd183;
            16'd131: rdata = 32'sd192;
            16'd132: rdata = 32'sd201;
            16'd133: rdata = 32'sd210;
            16'd134: rdata = 32'sd221;
            16'd135: rdata = 32'sd231;
            16'd136: rdata = 32'sd242;
            16'd137: rdata = 32'sd254;
            16'd138: rdata = 32'sd266;
            16'd139: rdata = 32'sd279;
            16'd140: rdata = 32'sd293;
            16'd141: rdata = 32'sd307;
            16'd142: rdata = 32'sd321;
            16'd143: rdata = 32'sd337;
            16'd144: rdata = 32'sd353;
            16'd145: rdata = 32'sd370;
            16'd146: rdata = 32'sd388;
            16'd147: rdata = 32'sd407;
            16'd148: rdata = 32'sd426;
            16'd149: rdata = 32'sd447;
            16'd150: rdata = 32'sd468;
            16'd151: rdata = 32'sd491;
            16'd152: rdata = 32'sd515;
            16'd153: rdata = 32'sd539;
            16'd154: rdata = 32'sd565;
            16'd155: rdata = 32'sd593;
            16'd156: rdata = 32'sd621;
            16'd157: rdata = 32'sd651;
            16'd158: rdata = 32'sd682;
            16'd159: rdata = 32'sd715;
            16'd160: rdata = 32'sd750;
            16'd161: rdata = 32'sd786;
            16'd162: rdata = 32'sd824;
            16'd163: rdata = 32'sd863;
            16'd164: rdata = 32'sd905;
            16'd165: rdata = 32'sd949;
            16'd166: rdata = 32'sd994;
            16'd167: rdata = 32'sd1042;
            16'd168: rdata = 32'sd1092;
            16'd169: rdata = 32'sd1145;
            16'd170: rdata = 32'sd1200;
            16'd171: rdata = 32'sd1258;
            16'd172: rdata = 32'sd1319;
            16'd173: rdata = 32'sd1382;
            16'd174: rdata = 32'sd1449;
            16'd175: rdata = 32'sd1519;
            16'd176: rdata = 32'sd1592;
            16'd177: rdata = 32'sd1669;
            16'd178: rdata = 32'sd1749;
            16'd179: rdata = 32'sd1833;
            16'd180: rdata = 32'sd1922;
            16'd181: rdata = 32'sd2014;
            16'd182: rdata = 32'sd2111;
            16'd183: rdata = 32'sd2213;
            16'd184: rdata = 32'sd2320;
            16'd185: rdata = 32'sd2431;
            16'd186: rdata = 32'sd2549;
            16'd187: rdata = 32'sd2671;
            16'd188: rdata = 32'sd2800;
            16'd189: rdata = 32'sd2935;
            16'd190: rdata = 32'sd3076;
            16'd191: rdata = 32'sd3225;
            16'd192: rdata = 32'sd3380;
            16'd193: rdata = 32'sd3543;
            16'd194: rdata = 32'sd3714;
            16'd195: rdata = 32'sd3893;
            16'd196: rdata = 32'sd4080;
            16'd197: rdata = 32'sd4277;
            16'd198: rdata = 32'sd4483;
            16'd199: rdata = 32'sd4699;
            16'd200: rdata = 32'sd4925;
            16'd201: rdata = 32'sd5162;
            16'd202: rdata = 32'sd5411;
            16'd203: rdata = 32'sd5672;
            16'd204: rdata = 32'sd5945;
            16'd205: rdata = 32'sd6232;
            16'd206: rdata = 32'sd6532;
            16'd207: rdata = 32'sd6847;
            16'd208: rdata = 32'sd7177;
            16'd209: rdata = 32'sd7522;
            16'd210: rdata = 32'sd7885;
            16'd211: rdata = 32'sd8265;
            16'd212: rdata = 32'sd8663;
            16'd213: rdata = 32'sd9080;
            16'd214: rdata = 32'sd9518;
            16'd215: rdata = 32'sd9976;
            16'd216: rdata = 32'sd10457;
            16'd217: rdata = 32'sd10961;
            16'd218: rdata = 32'sd11489;
            16'd219: rdata = 32'sd12043;
            16'd220: rdata = 32'sd12623;
            16'd221: rdata = 32'sd13231;
            16'd222: rdata = 32'sd13869;
            16'd223: rdata = 32'sd14537;
            16'd224: rdata = 32'sd15238;
            16'd225: rdata = 32'sd15972;
            16'd226: rdata = 32'sd16741;
            16'd227: rdata = 32'sd17548;
            16'd228: rdata = 32'sd18393;
            16'd229: rdata = 32'sd19280;
            16'd230: rdata = 32'sd20209;
            16'd231: rdata = 32'sd21182;
            16'd232: rdata = 32'sd22203;
            16'd233: rdata = 32'sd23273;
            16'd234: rdata = 32'sd24394;
            16'd235: rdata = 32'sd25570;
            16'd236: rdata = 32'sd26802;
            16'd237: rdata = 32'sd28093;
            16'd238: rdata = 32'sd29447;
            16'd239: rdata = 32'sd30866;
            16'd240: rdata = 32'sd32353;
            16'd241: rdata = 32'sd33912;
            16'd242: rdata = 32'sd35546;
            16'd243: rdata = 32'sd37258;
            16'd244: rdata = 32'sd39054;
            16'd245: rdata = 32'sd40935;
            16'd246: rdata = 32'sd42908;
            16'd247: rdata = 32'sd44975;
            16'd248: rdata = 32'sd47142;
            16'd249: rdata = 32'sd49414;
            16'd250: rdata = 32'sd51795;
            16'd251: rdata = 32'sd54290;
            16'd252: rdata = 32'sd56906;
            16'd253: rdata = 32'sd59648;
            16'd254: rdata = 32'sd62522;
            16'd255: rdata = 32'sd65535;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_WKV_MIN_DELTA_I) begin : gen_wkv_min_delta_i
      always_comb begin
        rdata = 32'sd0;
        if (addr < WKV_MIN_DELTA_I_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd48;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_WKV_STEP_I) begin : gen_wkv_step_i
      always_comb begin
        rdata = 32'sd0;
        if (addr < WKV_STEP_I_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd1;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_WKV_E_FRAC) begin : gen_wkv_e_frac
      always_comb begin
        rdata = 32'sd0;
        if (addr < WKV_E_FRAC_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd16;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_WKV_LOG_EXP) begin : gen_wkv_log_exp
      always_comb begin
        rdata = 32'sd0;
        if (addr < WKV_LOG_EXP_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd2;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_ATT_TIME_FIRST) begin : gen_blocks_0_att_time_first
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_ATT_TIME_FIRST_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd4;
            16'd1: rdata = -32'sd3;
            16'd2: rdata = -32'sd6;
            16'd3: rdata = -32'sd5;
            16'd4: rdata = -32'sd3;
            16'd5: rdata = -32'sd6;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_0_ATT_TIME_DECAY_WEXP) begin : gen_blocks_0_att_time_decay_wexp
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_0_ATT_TIME_DECAY_WEXP_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = 32'sd0;
            16'd2: rdata = -32'sd2;
            16'd3: rdata = -32'sd8;
            16'd4: rdata = -32'sd27;
            16'd5: rdata = -32'sd80;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_ATT_TIME_FIRST) begin : gen_blocks_1_att_time_first
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_ATT_TIME_FIRST_NUMEL) begin
          case (addr)
            16'd0: rdata = -32'sd5;
            16'd1: rdata = -32'sd3;
            16'd2: rdata = -32'sd7;
            16'd3: rdata = -32'sd4;
            16'd4: rdata = -32'sd2;
            16'd5: rdata = -32'sd7;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else if (ROM_ID == ROM_ID_BLOCKS_1_ATT_TIME_DECAY_WEXP) begin : gen_blocks_1_att_time_decay_wexp
      always_comb begin
        rdata = 32'sd0;
        if (addr < BLOCKS_1_ATT_TIME_DECAY_WEXP_NUMEL) begin
          case (addr)
            16'd0: rdata = 32'sd0;
            16'd1: rdata = 32'sd0;
            16'd2: rdata = 32'sd0;
            16'd3: rdata = -32'sd1;
            16'd4: rdata = -32'sd5;
            16'd5: rdata = -32'sd80;
            default: rdata = 32'sd0;
          endcase
        end
      end
    end
    else begin : gen_default
      always_comb begin
        rdata = 32'sd0;
      end
    end
  endgenerate

endmodule

module rwkv_rom_flat #(
  parameter int ROM_ID = 0,
  parameter int LEN = 1
)(
  output wire signed [LEN*32-1:0] data
);
  genvar idx;
  generate
    for (idx = 0; idx < LEN; idx++) begin : gen_words
      localparam logic [15:0] ADDR = idx;
      rwkv_rom #(.ROM_ID(ROM_ID)) u_rom (
        .addr(ADDR),
        .rdata(data[idx*32 +: 32])
      );
    end
  endgenerate

endmodule

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
