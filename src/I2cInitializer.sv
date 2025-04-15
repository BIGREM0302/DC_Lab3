module I2cInitializer(
    input i_rst_n,
    input i_clk,
    input i_start,
    output o_finished,
    output o_sclk,
    inout o_sdat,
    output o_oen
);
//commands for initialization
parameter LLI = 24'b0011_0100_000_0000_0_1001_0111;
parameter RLI = 24'b0011_0100_000_0001_0_1001_0111;
parameter LHO = 24'b0011_0100_000_0010_0_0111_1001;
parameter RHO = 24'b0011_0100_000_0011_0_0111_1001;
parameter AAPC = 24'b0011_0100_000_0100_0_0001_0101;
parameter DAPC = 24'b0011_0100_000_0101_0_0000_0000;
parameter PDC = 24'b0011_0100_000_0110_0_0000_0000;
parameter DAIF = 24'b0011_0100_000_0111_0_0100_0010;
parameter SC = 24'b0011_0100_000_1000_0_0001_1001;
parameter AC = 24'b0011_0100_000_1001_0_0000_0001;
//state parameter
parameter IDLE = 3'd0;
parameter START = 3'd1;
parameter SENDBUF = 3'd2;
parameter SEND = 3'd3;
parameter ACKBUF = 3'd4;
parameter ACK = 3'd5;
parameter CEND = 3'd6;
parameter STOP = 3'd7;

logic o_dat;
logic [2:0] state_r, state_w;
//counters bit 0~7, byte 0~2, command 0~9
logic [2:0] bit_counter_r, bit_counter_w; 
logic [1:0] byte_counter_r, byte_counter_w;
logic [3:0] c_counter_r, c_counter_w;

//inout_port
assign o_sdat = oen? o_dat:1'bz;

//FSM
always_comb begin
    //default value
    state_w = state_r;
    case(state_r) 
        IDLE:begin
            if(i_start) state_w = START;
        end
        START:begin
            
        end
        SENDBUF:begin
            state_w = SEND;
        end
        SEND:begin
            if(bit_counter_r == 3'd7) state_w = ACKBUF;
            else state_w = SENDBUF;
        end
        ACKBUF:begin
            state_w = ACK;
        end
        ACK:begin
            
        end
        CEND:begin

        end
        STOP:begin

        end
    endcase    
end

//couners
always_comb begin
    //default values
    c_counter_w = c_counter_r;
    bit_counter_w = bit_counter_r;
    byte_counter_w = byte_counter_r;
    if(state == SEND)begin
        if(bit_counter_r == 3'd7) bit_counter_w = 3'd0;
        else bit_counter_w = bit_counter_r + 3'd1;
    end
    if(state == ACK)begin
        if(byte_counter_r == 2'd3) byte_counter_r = 2'd0;
        else byte_counter_w = byte_counter_r + 2'd1;
    end
    if(state == CEND)begin
        if(c_counter_r == 4'd9) c_counter_w = 4'd0;
        else c_counter_w = c_counter_r + 4'd1;
    end
end

always_ff @(posedge i_clk  or negedge i_rst_n) begin
    if(!i_rst_n) begin
        state_r <= IDLE;
        c_counter_r <= 0;
        bit_counter_r <= 0;
        byte_counter_r <= 0;
    end
    else begin
        state_r <= state_w;
        c_counter_r <= c_counter_w;
        bit_counter_r <= bit_counter_w;
        byte_counter_r <= byte_counter_w;
    end
end

endmodule