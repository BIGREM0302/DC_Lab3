`timescale 1ns / 1ps

module AudPlayer_tb();

    // Inputs
    reg i_rst_n;
    reg i_bclk;
    reg i_daclrck;
    reg i_en;
    reg [15:0] i_dac_data;

    // Output
    wire o_aud_dacdat;

    // Instantiate the DUT
    AudPlayer uut (
        .i_rst_n(i_rst_n),
        .i_bclk(i_bclk),
        .i_daclrck(i_daclrck),
        .i_en(i_en),
        .i_dac_data(i_dac_data),
        .o_aud_dacdat(o_aud_dacdat)
    );

    // Clock generation (10ns period, 100MHz)
    initial begin
        i_bclk = 0;
        forever #5 i_bclk = ~i_bclk;  // BCLK toggles every 5ns
    end

    // DACLRCK simulation: simple toggle every 320ns (simulate stereo frame)
    initial begin
        i_daclrck = 0;
        forever #160 i_daclrck = ~i_daclrck;
    end

    // Stimulus
    initial begin
        $display("Starting AudPlayer Testbench");
        i_rst_n = 0;
        i_en = 0;
        i_dac_data = 16'b0;

        // Reset pulse
        #20;
        i_rst_n = 1;

        // Wait a bit
        #20;

        // Play a sample
        i_dac_data = 16'b1010101010101010;  // example pattern
        i_en = 1;
        #10; // one BCLK low cycle
        i_en = 0;

        // Wait for playback to finish
        #500;

        // Try another sample
        i_dac_data = 16'b1111000011110000;
        i_en = 1;

        #500;

        $display("Finish simulation");
        $finish;
    end

    // generate waveform file
    initial begin
        $dumpfile("audPlayer.fsdb");
        $dumpvars(0, AudPlayer_tb);
    end

endmodule
