module Top (
	input i_rst_n,		// i_key_3
	input i_clk,
	input i_key_0,		// Record/Pause
	input i_key_1,		// Play/Pause
	input i_key_2,		// Stop
	input [3:0] i_speed, // design how user can decide mode on your own
	input i_fast,
	input i_slow_0, 
	input i_slow_1, 
	

	// AudDSP and SRAM
	output [19:0] o_SRAM_ADDR,
	inout  [15:0] io_SRAM_DQ,
	output        o_SRAM_WE_N,
	output        o_SRAM_CE_N,
	output        o_SRAM_OE_N,
	output        o_SRAM_LB_N,
	output        o_SRAM_UB_N,

	// I2C
	input  i_clk_100k,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,

	// AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT,

	// SEVENDECODER (optional display)
	output [5:0] o_record_time,
	output [5:0] o_play_time

	// LCD (optional display)
	// input        i_clk_800k,
	// inout  [7:0] o_LCD_DATA,
	// output       o_LCD_EN,
	// output       o_LCD_RS,
	// output       o_LCD_RW,
	// output       o_LCD_ON,
	// output       o_LCD_BLON,

	// LED
	// output  [8:0] o_ledg,
	// output [17:0] o_ledr
);

// design the FSM and states as you like
parameter S_IDLE       = 0;
parameter S_I2C        = 1;
parameter S_RECD       = 2;
parameter S_RECD_PAUSE = 3;
parameter S_PLAY       = 4;
parameter S_PLAY_PAUSE = 5;

parameter MAX 		   = 15'd32767;
parameter timemax      = 6'd32;

logic i2c_oen, i2c_sdat;
logic [19:0] addr_record, addr_play;
logic [15:0] data_record, data_play, dac_data;
logic [2:0] state_r, state_w;

logic [5:0] record_time_r,o_record_time_w;
logic [5:0] play_time_r,play_time_w;
logic [15:0] ctr_r,ctr_w;

logic i2c_start, i2c_finished;
logic Aud_Recorder_start, Aud_Recorder_pause;
logic Aud_Player_start, Aud_Player_pause;
logic Aud_all_stop;
logic Aud_fast,Aud_slow_0,Aud_slow_1;

assign i2c_start = (state_r == S_I2C)? 1'b1 : 1'b0;
assign Aud_Recorder_start = (state_r == S_RECD)? 1'b1 : 1'b0;
assign Aud_Recorder_pause = (state_r == S_RECD_PAUSE)? 1'b1 : 1'b0;
assign Aud_Player_start = (state_r == S_PLAY)? 1'b1 : 1'b0;
assign Aud_Player_pause = (state_r == S_PLAY_PAUSE)? 1'b1 : 1'b0;
assign Aud_fast = (i_fast&(~i_slow_0)&(~i_slow_1));
assign Aud_slow_0 = (~i_fast&(i_slow_0)&(~i_slow_1));
assign Aud_slow_1 = (~i_fast&(~i_slow_0)&(i_slow_1));

assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SRAM_ADDR = (state_r == S_RECD) ? addr_record : addr_play[19:0];
assign io_SRAM_DQ  = (state_r == S_RECD) ? data_record : 16'dz; // sram_dq as output
assign data_play   = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input
assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

assign o_record_time = record_time_r;
assign o_play_time   = play_time_r;

// below is a simple example for module division
// you can design these as you like

// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100k),
	.i_start(i2c_start),
	.o_finished(i2c_finished),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player
AudDSP dsp0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk),
	.i_start(Aud_Player_start),
	.i_pause(Aud_Player_pause),
	.i_stop(Aud_all_stop),
	.i_speed(i_speed),
	.i_fast(Aud_fast),
	.i_slow_0(Aud_slow_0), // constant interpolation
	.i_slow_1(Aud_slow_1), // linear interpolation
	.i_daclrck(i_AUD_DACLRCK),
	.i_sram_data(data_play),
	.o_dac_data(dac_data),
	.o_sram_addr(addr_play)
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(Aud_Player_start), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
AudRecorder recorder0(
	.i_rst_n(i_rst_n),
	.i_clk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(Aud_Recorder_start),
	.i_pause(Aud_Recorder_pause),
	.i_stop(Aud_all_stop),
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record),
	.o_data(data_record)
);

always_comb begin
	// design your control here
	state_w       = state_r;
	record_time_w = record_time_r;
	play_time_w   = play_time_r;
	ctr_w         = ctr_r;
	Aud_all_stop  = 0;
	
	case(state_r)

		S_I2C:  begin
			if(i2c_finished) begin
				state_w = S_IDLE;
				Aud_all_stop = 1;
			end
		end        

		S_IDLE: begin
			if(i_key_0) begin
				state_w = S_RECD;
				record_time_w = 0;
				ctr_w   = 0;
			end

			else if(i_key_1) begin
				state_w = S_PLAY;
				play_time_w = 0;
				ctr_w   = 0;
			end
		end

		S_RECD: begin
			if(i_key_0) begin
				state_w = S_RECD_PAUSE;
			end

			else if (i_key_1) begin
				state_w = S_PLAY;
			end

			else if (i_key_2) begin
				state_w = S_IDLE;
				Aud_all_stop = 1;
			end

			else begin
				if(ctr_r != MAX) begin
					ctr_w = ctr_r + 1;
				end

				else begin
					ctr_w = 0;
					record_time_w = record_time_r + 1;
						if(record_time_r == timemax) begin
							state_w = S_IDLE;
						end
				end
			end
		end       

		S_RECD_PAUSE: begin
			if(i_key_0) begin
				state_w = S_RECD;
			end

			else if (i_key_1) begin
				state_w = S_PLAY;
			end

			else if (i_key_2) begin
				state_w = S_IDLE;
			end
			
		end 

		S_PLAY: begin
			if(i_key_1) begin
				state_w = S_PLAY_PAUSE;
			end

			else if (i_key_2) begin
				state_w = S_IDLE;
				Aud_all_stop = 1;
			end

			else begin
				if(ctr_r != MAX) begin
					ctr_w = ctr_r + 1;
				end

				else begin
					ctr_w = 0;
					play_time_w = play_time_r + 1;
						if(play_time_r == timemax) begin
							state_w = S_IDLE;
						end
				end
			end

		end      

		S_PLAY_PAUSE: begin
			if(i_key_1) begin
				state_w = S_PLAY;
			end

			else if (i_key_2) begin
				state_w = S_RECD_PAUSE;
				Aud_all_stop = 1;
			end
		end 

	endcase
end

always_ff @(posedge i_AUD_BCLK or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r   <= S_I2C;
		ctr_r <= 0;
		record_time_r <= 6'd0;
		play_time_r <= 6'd0;
	end
	else begin
		state_r       <= state_w;
		ctr_r		  <= ctr_w;
		record_time_r <= record_time_w;
		play_time_r   <= play_time_w;
	end
end

endmodule
