/******************************************************************************
 ** Logisim goes FPGA automatic generated Verilog code                       **
 **                                                                          **
 ** Component : FPGADigit                                                    **
 **                                                                          **
 ******************************************************************************/

`timescale 1ns/1ps
module FPGADigit( clkx,
                  GO,
                  RST,
                  EPC,
                  Ld, 
                  Done,
                  LED,
                  AN,
                  SEG,
                 CPU_RESETN,
                 SW,
                 VGA_R, 
                 VGA_G,
                 VGA_B,
                 VGA_HS,
                 VGA_VS
                  );

   /***************************************************************************
    ** Here the inputs are defined                                           **
    ***************************************************************************/
   input clkx, GO, RST, EPC, Ld;
                input  wire        CPU_RESETN;     // CPU复位按钮 (低电平有效)
                // 开关输入
                input  wire [2:0]  SW;             // 开关 (用于选择测试图案)
                // VGA输出
                output wire [3:0]  VGA_R;          // VGA红色信号
                output wire [3:0]  VGA_G;          // VGA绿色信号
                output wire [3:0]  VGA_B;          // VGA蓝色信号
                output wire        VGA_HS;         // VGA水平同步
                output wire        VGA_VS;         // VGA垂直同步
   /***************************************************************************
    ** Here the outputs are defined                                          **
    ***************************************************************************/
   output Done;
   output[7:0] AN;
   output[7:0] SEG;
   output[7:0] LED;


   /***************************************************************************
    ** Here the internal wires are defined                                   **
    ***************************************************************************/
   wire clkCPU, clkSEG;
   wire[3:0] data;
   wire[2:0] num;
   wire[31:0] dig;

//    initial begin
//        GO<=1;
//        RST<=0;
//    end


    clkDivider #(20000000) DividerCPU(.clk(clkx), .clk_N(clkCPU));
    clkDivider #(250000) DividerDisplay(.clk(clkx), .clk_N(clkSEG));

    wire [2:0] vga_sel;
    wire [7:0] cpu_led;

    MonoCycleCPU monoCycle(
        .Clk(clkCPU),
        .GO(GO),
        .RST(RST),
        .Done(Done),
        .DisplayDigit(dig),
        .LEDdata(cpu_led),
        .vga_sel(vga_sel)
    );


    // 连接CPU LED输出到物理LED
    assign LED[2:0] = cpu_led[2:0];

    sevenseg_display_top u_sevenseg_display_top(
        .clk(clkSEG),
        .rst(RST),
        .data_in(dig),
        .seg_patt(SEG),
        .seg_sel(AN)
    );
    vga_top u_vga_top (
        .CLK        (clkx),
        .CPU_RESETN (CPU_RESETN),
        .SW         (vga_sel),
        .VGA_R      (VGA_R),
        .VGA_G      (VGA_G),
        .VGA_B      (VGA_B),
        .VGA_HS     (VGA_HS),
        .VGA_VS     (VGA_VS),
        .LED        (LED[5:3])
    );

endmodule
