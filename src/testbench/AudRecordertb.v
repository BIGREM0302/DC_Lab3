`timescale 1ns / 1ps

module AudRecorder_tb;

// === Clock / Timing Parameters ===
reg clk = 0;                 // BCLK (bit clock)
reg rst_n = 0;
reg lrc = 0;                 // Left/Right clock
reg i_start = 0;
reg i_pause = 0;
reg i_stop = 0;
reg i_data = 0;

wire [19:0] o_address;
wire [15:0] o_data;

// === Instantiate your module ===
AudRecorder uut (
    .i_rst_n(rst_n),
    .i_clk(clk),
    .i_lrc(lrc),
    .i_start(i_start),
    .i_pause(i_pause),
    .i_stop(i_stop),
    .i_data(i_data),
    .o_address(o_address),
    .o_data(o_data)
);

// === Clock generation: BCLK 5ns period (100MHz) ===
always #2.5 clk = ~clk;

// === Generate LRC and ADCDAT ===
reg [15:0] l_data = 16'h5555;  // 模擬左聲道資料（前 16bit）
reg [15:0] r_data = 16'hFEDC;  // 模擬右聲道資料（後 16bit）
integer bit_index = 0;

always @(negedge clk) begin
    // 模擬 I2S LRC 變化，每 32 位元切一次
    if (bit_index == 0)
        lrc <= 0;  // Left channel
    else if (bit_index == 32)
        lrc <= 1;  // Right channel

    // 模擬 I2S 資料
    if (bit_index <= 16 && bit_index >= 1)
        i_data <= l_data[16-bit_index];
    else if (bit_index <= 48 && bit_index >= 33)
        i_data <= r_data[48-bit_index];
    else
        i_data <= 0;

    bit_index <= (bit_index + 1) % 64; // 每 64 個 BCLK 重複
end

// === Test sequence ===
initial begin
    $display("Start simulation");
    rst_n = 0;
    #20;
    rst_n = 1;

    // 啟動錄音
    #30;
    i_start = 1;
    #10;
    i_start = 0;

    // 播放一段資料（模擬幾個 frame）
    #1000;

    // Pause
    i_pause = 1;
    #200;
    i_pause = 0;

    // 播放再一段資料
    #1000;

    // Stop
    i_stop = 1;
    #20;
    i_stop = 0;

    // 再次 start
    #100;
    i_start = 1;
    #10;
    i_start = 0;

    #1000;

    $display("End simulation");
    $finish;
end

// generate waveform file
initial begin
    $dumpfile("audRecorder.fsdb");
    $dumpvars(0, AudRecorder_tb);
end

endmodule
