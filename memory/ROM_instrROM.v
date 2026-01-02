/******************************************************************************
 ** Logisim goes FPGA automatic generated Verilog code                       **
 **                                                                          **
 ** Component : ROM_instrROM                                                 **
 **                                                                          **
 ******************************************************************************/

`timescale 1ns/1ps
module ROM_instrROM( Address,
                     Data,
                     clk,
                     we,
                     waddr,
                     wdata);

   /***************************************************************************
    ** Here the inputs are defined                                           **
    ***************************************************************************/
   input[11:0]  Address;
   
   // Programming Interface
   input clk;
   input we;
   input [11:0] waddr;
   input [31:0] wdata;

   /***************************************************************************
    ** Here the outputs are defined                                          **
    ***************************************************************************/
   output [31:0] Data;

   // 定义一个深度为4096、宽度为32位的存储器
   reg [31:0] memory_array [4095:0];
   initial begin
      $readmemh("D:/D3A/RISCV_CPU/fpga/my/rv32im/rv32im.srcs/sources_1/imports/src/asm/tst.hex", memory_array); // 使用十六进制文件初始化Data
   end

    // Port A: Read Only (CPU)
    assign Data = memory_array[Address];
    
    // Port B: Write Only (Programmer)
    always @(posedge clk) begin
        if (we) begin
            memory_array[waddr] <= wdata;
        end
    end

endmodule
