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
                    we,
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
   input[15:0]  addr;
   input  clk;
   input[31:0]  d;
   input[3:0]   we; // Changed from str (1 bit) to we (4 bits)
   input  ld, clr;

   // Programming Port
   input prog_clk;
   input prog_we;
   input [15:0] prog_addr;
   input [31:0] prog_data;

   /***************************************************************************
    ** Here the outputs are defined                                          **
    ***************************************************************************/
   output reg[31:0] q;

	reg [31:0] mem[16383:0];
	
	// Port A: CPU Read/Write (Negedge triggered as per original design)
	always @ (negedge clk) begin
		if (we[0]) mem[addr][7:0]   <= d[7:0];
		if (we[1]) mem[addr][15:8]  <= d[15:8];
		if (we[2]) mem[addr][23:16] <= d[23:16];
		if (we[3]) mem[addr][31:24] <= d[31:24];
		
		if (we == 4'b0000)
         q <= mem[addr];
	end
	
	// Port B: Programmer Write (Posedge triggered)
	always @ (posedge prog_clk) begin
	   if (prog_we)
	       mem[prog_addr] <= prog_data;
	end

endmodule
