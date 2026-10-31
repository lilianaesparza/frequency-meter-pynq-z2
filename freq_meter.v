module freq_meter(
    input wire sys_clk,
    input wire sys_rst_n
);

    // Clocking Wizard signals
    wire clk_stand;
    wire clk_test;
    wire locked;

    // Frequency-measurement signals
    wire [33:0] freq;
    wire        gate_s;
    wire        gate_a;
    wire [33:0] cnt_clk_stand;
    wire [33:0] cnt_clk_test;

    // Clocking Wizard
    clk_test_gen clk_test_gen_inst (
        .clk_in1  (sys_clk),
        .reset    (~sys_rst_n),
        .clk_stand(clk_stand),
        .clk_test (clk_test),
        .locked   (locked)
    );

    // Frequency-measurement calculation module
    freq_meter_calc freq_meter_calc_inst (
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

    // ILA with five probes
        ila_frequency ila_frequency_inst (
        .clk    (clk_stand),
        .probe0 (freq)
    );

endmodule
