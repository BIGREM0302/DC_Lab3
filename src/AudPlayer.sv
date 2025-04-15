`timescale 1ns / 1ps //for testbench

module AudPlayer(
	input i_rst_n,
	input i_bclk,
	input i_daclrck,
	input i_en, // enable AudPlayer only when playing audio, work with AudDSP
	input [15:0] i_dac_data, //dac_data
	output o_aud_dacdat
);

//let's play on left track
parameter IDLE = 1'b0;
parameter PLAY = 1'b1;

logic state_r, state_w;
logic [15:0] aud_dacdat_r, aud_dacdat_w;
logic [5:0] counter_r, counter_w;

assign o_aud_dacdat = aud_dacdat_r[15];
//FSM
always_comb begin
    state_w = state_r;
    case(state_r)
    IDLE: if(i_en && ~i_daclrck) state_w = PLAY;
    PLAY: if(i_daclrck && counter_r == 5'd16) state_w = IDLE;
    endcase
end

//counter
always_comb begin
    counter_w = counter_r;
    case(state_r)
    PLAY: begin
        if(state_w == IDLE) counter_w = 5'd0;
        else if(counter_r < 5'd16) counter_w = counter_r + 5'd1;
    end
    endcase
end

//data
always_comb begin
    aud_dacdat_w = aud_dacdat_r;
    if(state_r == IDLE && state_w == PLAY)begin //need to advance 1 cycle
        aud_dacdat_w = i_dac_data;
    end
    else if (state_r == PLAY)begin
        if(counter_r >= 5'd15) aud_dacdat_w = 16'd0;
        else aud_dacdat_w = aud_dacdat_r << 1;
    end
end

always_ff@(posedge i_bclk or negedge i_rst_n) begin

if(!i_rst_n)begin
    state_r <= IDLE;
    counter_r <= 5'd0;
    aud_dacdat_r <= 16'd0;
end
else begin
    state_r <= state_w;
    counter_r <= counter_w;
    aud_dacdat_r <= aud_dacdat_w;
end

end

endmodule