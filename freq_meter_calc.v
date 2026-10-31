module freq_meter_calc #(
    parameter integer CNT_GATE_S_MAX = 187_499_999,
    parameter integer CNT_RISE_MAX   = 31_249_999
)(
    input  wire        clk_stand,
    input  wire        clk_test,
    input  wire        sys_clk,
    input  wire        sys_rst_n,

    output reg [33:0]  freq,
    output reg         gate_s,
    output reg         gate_a,
    output reg [33:0]  cnt_clk_stand,
    output reg [33:0]  cnt_clk_test
);

    // Software-gate counter
    reg [27:0] cnt_gate_s;

    // Gate synchronization registers
    reg gate_stand_meta;
    reg gate_stand_sync;
    reg gate_stand_previous;

    reg gate_test_meta;
    reg gate_test_sync;
    reg gate_test_previous;

    // Latched counter values
    reg [33:0] stand_latched;
    reg [33:0] test_latched;

    // Synchronize the test counter result into the reference-clock domain
    reg [33:0] test_latched_meta;
    reg [33:0] test_latched_sync;

    // Calculation registers
    reg [2:0] calculate_delay;
    reg [67:0] multiplication_result;

    // Internal synchronized gates
    wire gate_stand_active = gate_stand_sync;
    wire gate_test_active  = gate_test_sync;

    // ---------------------------------------------------------
    // Generate a 1-second measurement gate using the 125 MHz
    // system clock.
    //
    // 0.25 seconds = 31,250,000 clock cycles
    // 1.50 seconds = 187,500,000 clock cycles
    // ---------------------------------------------------------
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_gate_s <= 28'd0;
            gate_s     <= 1'b0;
        end
        else if (cnt_gate_s == CNT_GATE_S_MAX) begin
            cnt_gate_s <= 28'd0;
            gate_s     <= 1'b0;
        end
        else begin
            cnt_gate_s <= cnt_gate_s + 1'b1;

            if ((cnt_gate_s > CNT_RISE_MAX) &&
                (cnt_gate_s < (CNT_GATE_S_MAX - CNT_RISE_MAX)))
                gate_s <= 1'b1;
            else
                gate_s <= 1'b0;
        end
    end

    // ---------------------------------------------------------
    // Synchronize the measurement gate into the reference-clock
    // domain.
    // ---------------------------------------------------------
    always @(posedge clk_stand or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            gate_stand_meta     <= 1'b0;
            gate_stand_sync     <= 1'b0;
            gate_stand_previous <= 1'b0;
        end
        else begin
            gate_stand_meta     <= gate_s;
            gate_stand_sync     <= gate_stand_meta;
            gate_stand_previous <= gate_stand_sync;
        end
    end

    // ---------------------------------------------------------
    // Synchronize the measurement gate into the test-clock
    // domain.
    // ---------------------------------------------------------
    always @(posedge clk_test or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            gate_test_meta     <= 1'b0;
            gate_test_sync     <= 1'b0;
            gate_test_previous <= 1'b0;
            gate_a             <= 1'b0;
        end
        else begin
            gate_test_meta     <= gate_s;
            gate_test_sync     <= gate_test_meta;
            gate_test_previous <= gate_test_sync;
            gate_a             <= gate_test_sync;
        end
    end

    // ---------------------------------------------------------
    // Count reference-clock cycles.
    // ---------------------------------------------------------
    always @(posedge clk_stand or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_clk_stand <= 34'd0;
            stand_latched <= 34'd0;
        end
        else if (!gate_stand_active &&
                 gate_stand_previous) begin
            stand_latched <= cnt_clk_stand;
            cnt_clk_stand <= 34'd0;
        end
        else if (gate_stand_active) begin
            cnt_clk_stand <= cnt_clk_stand + 1'b1;
        end
    end

    // ---------------------------------------------------------
    // Count test-clock cycles.
    // ---------------------------------------------------------
    always @(posedge clk_test or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_clk_test <= 34'd0;
            test_latched <= 34'd0;
        end
        else if (!gate_test_active &&
                 gate_test_previous) begin
            test_latched <= cnt_clk_test;
            cnt_clk_test <= 34'd0;
        end
        else if (gate_test_active) begin
            cnt_clk_test <= cnt_clk_test + 1'b1;
        end
    end

    // ---------------------------------------------------------
    // Transfer the completed test-clock count into the
    // reference-clock domain.
    // ---------------------------------------------------------
    always @(posedge clk_stand or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            test_latched_meta <= 34'd0;
            test_latched_sync <= 34'd0;
        end
        else begin
            test_latched_meta <= test_latched;
            test_latched_sync <= test_latched_meta;
        end
    end

    // ---------------------------------------------------------
    // Calculate:
    //
    // frequency = test-clock count x reference frequency
    //             --------------------------------------
    //             reference-clock count
    //
    // The reference frequency is 100 MHz.
    // ---------------------------------------------------------
    always @(posedge clk_stand or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            freq                 <= 34'd0;
            multiplication_result <= 68'd0;
            calculate_delay      <= 3'd0;
        end
        else if (!gate_stand_active &&
                 gate_stand_previous) begin
            calculate_delay <= 3'd4;
        end
        else if (calculate_delay != 3'd0) begin
            calculate_delay <= calculate_delay - 1'b1;

            if (calculate_delay == 3'd1) begin
                if (stand_latched != 34'd0) begin
                    multiplication_result =
                        test_latched_sync * 34'd100_000_000;

                    freq <= multiplication_result / stand_latched;
                end
                else begin
                    freq <= 34'd0;
                end
            end
        end
    end

endmodule
