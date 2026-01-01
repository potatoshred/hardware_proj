`timescale 1ns/1ps
module Bit_Extender #(parameter INPUT_WIDTH = 8, OUTPUT_WIDTH = 32, SIGN_EXTEND = 0)(
    input [INPUT_WIDTH-1:0] imm_in,
    output reg [OUTPUT_WIDTH-1:0] imm_out
);

    always @(*) begin
        if (SIGN_EXTEND) begin
            imm_out = {{(OUTPUT_WIDTH-INPUT_WIDTH){imm_in[INPUT_WIDTH-1]}}, imm_in};
        end else begin
            imm_out = {{(OUTPUT_WIDTH-INPUT_WIDTH){1'b0}}, imm_in};
        end
    end

endmodule