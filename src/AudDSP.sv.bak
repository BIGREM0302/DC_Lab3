module AudDSP (
    input  logic               i_rst_n,
    input  logic               i_clk,
    input  logic               i_start,
    input  logic               i_pause,
    input  logic               i_stop,
    input  logic        [3:0]  i_speed,
    input  logic               i_fast,
    input  logic               i_slow_0,
    input  logic               i_slow_1,
    input  logic               i_daclrck,
    input  logic signed [15:0] i_sram_data,
    output logic signed [15:0] o_dac_data,
    output logic        [19:0] o_sram_addr
);

parameter S_IDLE  = 0;
parameter S_PLAY  = 1;
parameter S_PAUSE = 2;
parameter S_STOP  = 3;

logic        [ 1:0] state_r, state_w;
logic        [19:0] play_addr_r, play_addr_w;
logic signed [15:0] prev_sample_r, prev_sample_w;
logic signed [15:0] dac_data_r, dac_data_w;
logic        [ 3:0] repeat_cnt_r, repeat_cnt_w;
logic signed [15:0] step_val;
logic         [3:0] i_speed_brainrot;

assign o_sram_addr = play_addr_r;
assign o_dac_data  = dac_data_r;
assign i_speed_brainrot = (i_speed != 4'd0)? i_speed:4'd1;

always_comb begin
    play_addr_w   = play_addr_r;
    prev_sample_w = prev_sample_r;
    dac_data_w    = dac_data_r;
    repeat_cnt_w  = repeat_cnt_r;

    case (state_r)
        S_IDLE: begin
            if (i_start) begin
                play_addr_w   = 0;
                prev_sample_w = i_sram_data;
                dac_data_w    = i_sram_data;
                repeat_cnt_w  = 0;
            end
        end

        S_PLAY: begin
            if (!i_pause && !i_stop) begin
                if (i_fast) begin
                        play_addr_w   = play_addr_r + i_speed_brainrot;
                        dac_data_w    = i_sram_data;
                        prev_sample_w = i_sram_data;
                        repeat_cnt_w  = 0;
                end

                else if (i_slow_0) begin
                    if (repeat_cnt_r == 0) begin
                        prev_sample_w = i_sram_data;
                        dac_data_w    = i_sram_data;
                        repeat_cnt_w  = repeat_cnt_r + 1;
                    end
                    else if (repeat_cnt_r < i_speed_brainrot) begin
                        dac_data_w   = prev_sample_r;
                        repeat_cnt_w = repeat_cnt_r + 1;
                    end
                    if (repeat_cnt_r == (i_speed_brainrot - 1)) begin
                        play_addr_w  = play_addr_r + 1;
                        repeat_cnt_w = 0;
                    end
                end

                else if (i_slow_1) begin
                    if (repeat_cnt_r == 0) begin
                        play_addr_w   = play_addr_r + 1;
                        dac_data_w    = i_sram_data;
                        prev_sample_w = i_sram_data;
                        repeat_cnt_w  = repeat_cnt_r + 1;
                    end
                    else if (repeat_cnt_r < i_speed_brainrot) begin
                        $signed(step_val)     = $signed(($signed(i_sram_data) - $signed(prev_sample_r))/ $signed(i_speed_brainrot));
                        $signed(dac_data_w)  = $signed(prev_sample_r) + $signed(($signed(step_val) * $signed(repeat_cnt_r)));
                        repeat_cnt_w = repeat_cnt_r + 1;
                    end
                    if (repeat_cnt_r == (i_speed_brainrot - 1)) begin
                        repeat_cnt_w = 0;
                    end
                end

                else begin
                    play_addr_w   = play_addr_r + 1;
                    dac_data_w    = i_sram_data;
                    prev_sample_w = i_sram_data;
                    repeat_cnt_w  = 0;
                end
            end
        end

        S_PAUSE: begin
            dac_data_w = dac_data_r;
        end

        S_STOP: begin
            play_addr_w  = 0;
            dac_data_w   = 0;
            repeat_cnt_w = 0;
        end
    endcase
end

always_ff @(posedge i_daclrck or negedge i_rst_n) begin
    if (!i_rst_n) begin
        play_addr_r   <= 0;
        prev_sample_r <= 0;
        dac_data_r    <= 0;
        repeat_cnt_r  <= 0;
    end
    else begin
        play_addr_r   <= play_addr_w;
        prev_sample_r <= prev_sample_w;
        dac_data_r    <= dac_data_w;
        repeat_cnt_r  <= repeat_cnt_w;
    end
end

always_comb begin
    state_w = state_r;

    case (state_r)
        S_IDLE: begin
            if (i_start)
                state_w = S_PLAY;
        end

        S_PLAY: begin
            if (i_pause)
                state_w = S_PAUSE;
            else if (i_stop)
                state_w = S_STOP;
        end

        S_PAUSE: begin
            if (i_stop)
                state_w = S_STOP;
            else if (!i_pause)
                state_w = S_PLAY;
        end

        S_STOP: begin
            if (i_start)
                state_w = S_PLAY;
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_IDLE;
    end
    else begin
        state_r <= state_w;
    end
end

endmodule
