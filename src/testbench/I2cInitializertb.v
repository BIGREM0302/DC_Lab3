`timescale 1ns / 1ps

module I2cInitializer_tb;

    // DUT 介面訊號宣告
    reg i_clk;
    reg i_rst_n;
    reg i_start;
    wire o_finished;
    wire o_sclk;
    wire o_oen;
    wire o_sdat;

    // inout pin 模擬 (實際上測試時用pullup模擬 open-drain)
    tri o_sdat_line;

    // assign 模擬 open-drain 行為
    assign o_sdat_line = o_oen ? o_sdat : 1'bz;

    // DUT 實例化
    I2cInitializer uut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(i_start),
        .o_finished(o_finished),
        .o_sclk(o_sclk),
        .o_sdat(o_sdat_line),
        .o_oen(o_oen)
    );

    // clock 產生器 (100MHz)
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    // 測試程序
    initial begin
        // 初始化
        i_rst_n = 0;
        i_start = 0;

        // Reset active
        #20;
        i_rst_n = 1;

        // 等待一點時間後觸發啟動
        #50;
        i_start = 1;

        // 只保留一個 cycle
        #10;
        i_start = 0;

        // 模擬結束時間
        #8000;

        i_start = 1;

        #10 i_start = 0;

        #2500;

        // 模擬結束
        $finish;
    end

    // Monitor
    initial begin
        $dumpfile("i2c_initializer.fsdb");
        $dumpvars(0, I2cInitializer_tb);
        $display("Time\tclk\trst\tstart\tfinish\tsclk\tsdat");
        $monitor("%0t\t%b\t%b\t%b\t%b\t%b\t%b",
                 $time, i_clk, i_rst_n, i_start, o_finished, o_sclk, o_sdat_line);
    end

endmodule
