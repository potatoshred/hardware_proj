/******************************************************************************
 ** Logisim goes FPGA automatic generated Verilog code                       **
 **                                                                          **
 ** Component : Regifile                                                     **
 **                                                                          **
 ******************************************************************************/

`timescale 1ns/1ps
module Regifile( Clk,
                 Din,
                 R1N,
                 R2N,
                 RdN,
                 WE,
                 R1,
                 R2);

   /***************************************************************************
    ** Here the inputs are defined                                           **
    ***************************************************************************/
   input  Clk;
   input[31:0]  Din;
   input[4:0]  R1N;
   input[4:0]  R2N;
   input[4:0]  RdN;
   input  WE;

   /***************************************************************************
    ** Here the outputs are defined                                          **
    ***************************************************************************/
   output [31:0] R1;
   output [31:0] R2;


   /***************************************************************************
    ** Here all output connections are defined                               **
    ***************************************************************************/
    reg [31:0] mem[31:0];
    integer i;
    initial begin
        for (i = 0; i<32; i=i+1) begin
            mem[i]=32'd0;
        end
    end
    // RISC-V x0 register is always 0
    assign R1 = (R1N == 5'd0) ? 32'd0 : mem[R1N];
    assign R2 = (R2N == 5'd0) ? 32'd0 : mem[R2N];

    // 使用上升沿写入寄存器
    always @ (posedge Clk) begin
        if (WE && (RdN != 5'd0))
            mem[RdN] <= Din;
    end



endmodule
