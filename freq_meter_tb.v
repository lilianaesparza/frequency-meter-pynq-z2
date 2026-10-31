`timescale 1ns/1ps

module freq_meter_tb;

    reg clk_stand;
    reg clk_test;
    reg sys_clk;
    reg sys_rst_n;

    wire [33:0] freq;
    wire        gate_s;
    wire        gate_a;
    wire [33:0] cnt_clk_stand;
    wire [33:0] cnt_clk_test;

    // Use small values so simulation finishes quickly
    freq_meter_calc #(
        .CNT_GATE_S_MAX(99),
        .CNT_RISE_MAX(4)
    ) dut (
        .clk_stand     (clk_stand),
        .clk_test      (clk_test),
        .sys_clk       (sys_clk),
        .sys_rst_n     (sys_rst_n),
        .freq          (freq),
        .gate_s        (gate_s),
        .gate_a        (gate_a),
        .cnt_clk_stand (cnt_clk_stand),
        .cnt_clk_test  (cnt_clk_test)
    );

    // 125 MHz system clock: 8 ns period
    initial begin
        sys_clk = 1'b0;
        forever #4 sys_clk = ~sys_clk;
    end

    // 100 MHz reference clock: 10 ns period
    initial begin
        clk_stand = 1'b0;
        forever #5 clk_stand = ~clk_stand;
    end

    // 50 MHz test clock: 20 ns period
    initial begin
        clk_test = 1'b0;
        forever #10 clk_test = ~clk_test;
    end

    // Reset and simulation control
    initial begin
        sys_rst_n = 1'b0;
        #100;

        sys_rst_n = 1'b1;

        // Allow the measurement to complete
        #3000;

        $finish;
    end

endmodule
