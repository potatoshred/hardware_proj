`timescale 1ns / 1ps

module clock_generator(
    input  wire clk_in1,   // 100 MHz
    output wire clk_out1,  // 25.175 MHz
    output wire clk_out2,  // 10 MHz (CPU)
    input  wire reset,
    output wire locked
);

    wire clkfbout, clkfbout_buf;
    wire clkout0, clkout1;
    
    // MMCME2_BASE: Base Mixed Mode Clock Manager
    //              Artix-7
    // Xilinx HDL Language Template, version 2019.1

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),         // Jitter programming (OPTIMIZED, HIGH, LOW)
        .CLKFBOUT_MULT_F(9.0),     // Multiply value for all CLKOUT (2.000-64.000). VCO = 100 * 9 = 900 MHz
        .CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (-360.000-360.000).
        .CLKIN1_PERIOD(10.0),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
        // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
        .CLKOUT0_DIVIDE_F(35.75),  // Divide amount for CLKOUT0 (1.000-128.000). 900 / 35.75 = 25.1748 MHz
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0.0),
        .CLKOUT1_DIVIDE(36),       // 900 / 36 = 25 MHz
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT1_PHASE(0.0),
        .DIVCLK_DIVIDE(1),         // Master division value (1-106)
        .REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999).
        .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
    )
    MMCME2_BASE_inst (
        // Clock Outputs: 1-bit (each) output: User configurable clock outputs
        .CLKOUT0(clkout0),     // 1-bit output: CLKOUT0
        .CLKOUT0B(),   // 1-bit output: Inverted CLKOUT0
        .CLKOUT1(clkout1),     // 1-bit output: CLKOUT1
        .CLKOUT1B(),   // 1-bit output: Inverted CLKOUT1
        .CLKOUT2(),     // 1-bit output: CLKOUT2
        .CLKOUT2B(),   // 1-bit output: Inverted CLKOUT2
        .CLKOUT3(),     // 1-bit output: CLKOUT3
        .CLKOUT3B(),   // 1-bit output: Inverted CLKOUT3
        .CLKOUT4(),     // 1-bit output: CLKOUT4
        .CLKOUT5(),     // 1-bit output: CLKOUT5
        .CLKOUT6(),     // 1-bit output: CLKOUT6
        // Feedback Clocks: 1-bit (each) output: Clock feedback ports
        .CLKFBOUT(clkfbout),   // 1-bit output: Feedback clock
        .CLKFBOUTB(), // 1-bit output: Inverted CLKFBOUT
        // Status Ports: 1-bit (each) output: MMCM status ports
        .LOCKED(locked),       // 1-bit output: LOCK
        // Clock Inputs: 1-bit (each) input: Clock input
        .CLKIN1(clk_in1),       // 1-bit input: Clock
        // Control Ports: 1-bit (each) input: MMCM control ports
        .PWRDWN(1'b0),       // 1-bit input: Power-down
        .RST(1'b0),             // 1-bit input: Reset (Disabled to prevent noise)
        // Feedback Clocks: 1-bit (each) input: Clock feedback ports
        .CLKFBIN(clkfbout_buf)      // 1-bit input: Feedback clock
    );

    // Output buffering
    // BUFG is needed for clock distribution network
    BUFG clkout1_buf (.I(clkout0), .O(clk_out1));
    BUFG clkout2_buf (.I(clkout1), .O(clk_out2));
    BUFG clkf_buf (.I(clkfbout), .O(clkfbout_buf));

endmodule
