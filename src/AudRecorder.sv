module AudRecorder(
	input i_rst_n, // connect to the reset signal
	input i_clk, // connect to the AUD_BCLK, the bit clock
	input i_lrc, // the clock for left and right channels, 0 for left, 1 for right
	input i_start, // start to record
	input i_pause, // pause recording
	input i_stop, // stop recording
	input i_data, // connect to i_AUD_ADCDAT (analog to digital)
	output [19:0] o_address, //the address of SRAM : 20 bits address with each word size = 16bits
	output [15:0] o_data, //the data going to be stored (16 bit)
);

reg [1:0] state_r, state_w;
reg [15:0] data_r, data_w;
reg [19:0] address_r, address_w;
reg [4:0] counter_r, counter_w;

parameter IDLE = 2'd0;
parameter LEFT = 2'd1;
parameter RIGHT = 2'd2;
parameter STOP = 2'd3;

assign o_address = adress_r;
assign o_data = data_r;

//FSM
always_comb begin
    //default value
    state_w = state_r;
    case(state_r)
    IDLE:begin
        if(i_start) state_w = LEFT;    
    end
    LEFT:begin
        if(i_stop|i_pause) state_w = STOP;
        else if(i_lrc) state_w = RIGHT;
    end
    RIGHT:begin
        if(i_stop|i_pause) state_w = STOP;
        else if(~i_lrc) state_w = LEFT;
    end
    STOP:begin
        // To Do:
        if(i_start) state_w = LEFT;
        else state_w = IDLE;
    end
    endcase
end

//pause function
always_comb begin
    
end

//counter
always_comb begin
    //default value
    counter_w = counter_r;
    //count 0 -> 1 -> 2 ... -> 15 -> 16 -> 16 .... 16 -> 0...
    case(state_r)
    STOP: counter_w = 5'd0;
    LEFT:begin
        if(state_w == RIGHT) counter_w = 5'd0;
        else if(counter_r >= 5'd16) counter_w = counter_r;
        else counter_w = counter_r + 5'd1;
    end
    RIGHT:begin
        if(state_w == LEFT) counter_w = 5'd0;
        else if(counter_r >= 5'd16) counter_w = counter_r;
        else counter_w = counter_r + 5'd1;
    end
    endcase
end

//data
always_comb begin
    //default value
    data_w = data_r;
    case(state_r)
    LEFT: data_w = 16'd0; //nothing but also reset to zeros when it's left channel
    RIGHT:begin
        if(counter_r < 5'd16) data_w = {data_r[14:0], i_data}; //i_data will change at negative edge
        else data_w = data_r;
    end
    endcase
end

//address
always_comb begin
    //default value
    address_w = address_r;
    if(state_r == RIGHT && state_w == LEFT) address_w = address_r + 20'd1;
end

always_ff @(posedge i_clk or negedge i_rst_n)begin
    if(!i_rst_n) begin
        state_r <= IDLE;
        data_r <= 16'd0;
        address_r <= 20'd0;
        counter_r <= 5'd0;
    end
    else begin
        state_r <= state_w;
        data_r <= data_w;
        address_r <= address_w;
        counter_r <= counter_w;
    end
end

endmodule