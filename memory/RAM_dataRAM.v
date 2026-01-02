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
                    q,
                    prog_clk,
                    prog_we,
                    prog_addr,
                    prog_data);

   /***************************************************************************
    ** Here the inputs are defined                                           **
    ***************************************************************************/
   input[11:0]  addr;
   input  clk;
   input[31:0]  d;
   input  str, ld, clr;
   
   // Programming Port
   input prog_clk;
   input prog_we;
   input [11:0] prog_addr;
   input [31:0] prog_data;

   /***************************************************************************
    ** Here the outputs are defined                                          **
    ***************************************************************************/
   output reg[31:0] q;

	reg [31:0] mem[4095:0];
	
	// Port A: CPU Read/Write (Negedge triggered as per original design)
	always @ (negedge clk) begin
		if (str)
			mem[addr] <= d;
      else
         q <= mem[addr];
	end
	
	// Port B: Programmer Write (Posedge triggered)
	always @ (posedge prog_clk) begin
	   if (prog_we)
	       mem[prog_addr] <= prog_data;
	end

endmodule
