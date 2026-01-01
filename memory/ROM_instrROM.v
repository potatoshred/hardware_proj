/******************************************************************************
 ** Logisim goes FPGA automatic generated Verilog code                       **
 **                                                                          **
 ** Component : ROM_instrROM                                                 **
 **                                                                          **
 ******************************************************************************/

`timescale 1ns/1ps
module ROM_instrROM( Address,
                     Data);

   /***************************************************************************
    ** Here the inputs are defined                                           **
    ***************************************************************************/
   input[9:0]  Address;

   /***************************************************************************
    ** Here the outputs are defined                                          **
    ***************************************************************************/
   output [31:0] Data;

   // 定义一个深度为1024、宽度为8位的存储器
   reg [31:0] memory_array [1023:0];
   initial begin
      $readmemh("D:/D3A/RISCV_CPU/fpga/my/rv32im/rv32im.srcs/sources_1/imports/src/asm/tst.hex", memory_array); // 使用十六进制文件初始化Data
   end

    assign Data = memory_array[Address];

endmodule
