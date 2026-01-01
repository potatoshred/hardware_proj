/******************************************************************************
 ** Logisim goes FPGA automatic generated Verilog code                       **
 **                                                                          **
 ** Component : RAM_dataRAM                                                  **
 **                                                                          **
 ******************************************************************************/

`timescale 1ns/1ps
module RAM_dataRAM( addr,
                    clk,
                    d,
                    str,
                    ld,
                    clr,
                    q);

   /***************************************************************************
    ** Here the inputs are defined                                           **
    ***************************************************************************/
   input[9:0]  addr;
   input  clk;
   input[31:0]  d;
   input  str, ld, clr;

   /***************************************************************************
    ** Here the outputs are defined                                          **
    ***************************************************************************/
   output reg[31:0] q;

	reg [31:0] mem[1023:0];
	always @ (negedge clk) begin
		if (str)
			mem[addr] <= d;
      else
         q <= mem[addr];
	end

endmodule
