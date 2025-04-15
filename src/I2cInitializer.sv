`timescale 1ns / 1ps //for testbench

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
parameter IDLE = 4'd0;
parameter START = 4'd1;
parameter SENDBUF = 4'd2;
parameter SEND = 4'd3;
parameter ACKBUF = 4'd4;
parameter ACK = 4'd5;
parameter CEND = 4'd6;
parameter STOPBUF = 4'd7;
parameter STOP = 4'd8;

logic dat, oen, sclk, finished;
logic [23:0] command_r, command_w;
logic [3:0] state_r, state_w;
//counters bit 0~7, byte 0~2, command 0~9
logic [2:0] bit_counter_r, bit_counter_w; 
logic [1:0] byte_counter_r, byte_counter_w;
logic [3:0] c_counter_r, c_counter_w;

//inout_port
assign o_oen = oen;
assign o_sclk = sclk;
assign o_finished = finished;
assign o_sdat = oen? dat:1'bz;

//FSM
always_comb begin
    //default value
    state_w = state_r;
    finished = 1'b0;
    oen = 1'b1;
    dat = 1'b1;
    sclk = 1'b1;
    case(state_r) 
        IDLE:begin
            if(i_start) state_w = START;
        end
        START:begin
            state_w = SENDBUF;
            dat = 1'b0; //1->0
        end
        SENDBUF:begin
            state_w = SEND;
            sclk = 1'b0;
            dat = command_r[23]; //send the MSB
        end
        SEND:begin
            if(bit_counter_r == 3'd7) state_w = ACKBUF;
            else state_w = SENDBUF;
            sclk = 1'b1;
            dat = command_r[23];
        end
        ACKBUF:begin
            state_w = ACK;
            oen = 1'b0;
            sclk = 1'b0;
        end
        ACK:begin
            if(byte_counter_r == 2'd2) state_w = CEND;
            else state_w = SENDBUF;
            oen = 1'b0;
            sclk = 1'b1;
        end
        CEND:begin
            if(c_counter_r == 4'd9) state_w = STOPBUF;//finish all commands
            else state_w = SENDBUF;
            sclk = 1'b0;
            dat = 1'b0;
        end
        STOPBUF:begin
            state_w = STOP;
            sclk = 1'b1;
            dat = 1'b0;
            finished = 1'b1;
        end
        STOP:begin
            state_w = IDLE;
            dat = 1'b1; //0->1
            finished = 1'b1;
        end
    endcase    
end

//command updaate
always_comb begin
    //default value
    command_w = command_r;
    if(state_r == START) command_w = LLI;
    else if(state_r == CEND) begin
        case(c_counter_r)
            4'd0: command_w = RLI;
            4'd1: command_w = LHO;
            4'd2: command_w = RHO;
            4'd3: command_w = AAPC;
            4'd4: command_w = DAPC;
            4'd5: command_w = PDC;
            4'd6: command_w = DAIF;
            4'd7: command_w = SC;
            4'd8: command_w = AC;
        endcase
    end
    else if(state_r == SEND) begin
        command_w = command_r << 1;
    end
end

//couners
always_comb begin
    //default values
    c_counter_w = c_counter_r;
    bit_counter_w = bit_counter_r;
    byte_counter_w = byte_counter_r;
    if(state_r == SEND)begin
        if(bit_counter_r == 3'd7) bit_counter_w = 3'd0;
        else bit_counter_w = bit_counter_r + 3'd1;
    end
    if(state_r == ACK)begin
        if(byte_counter_r == 2'd2) byte_counter_w = 2'd0;
        else byte_counter_w = byte_counter_r + 2'd1;
    end
    if(state_r == CEND)begin
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
        command_r <= 24'd0;
    end
    else begin
        state_r <= state_w;
        c_counter_r <= c_counter_w;
        bit_counter_r <= bit_counter_w;
        byte_counter_r <= byte_counter_w;
        command_r <= command_w;
    end
end

endmodule