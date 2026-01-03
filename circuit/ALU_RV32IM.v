/******************************************************************************
 ** RV32IM ALU - Simplified Version
 **
 ** This ALU uses direct Verilog operations instead of sub-modules
 ******************************************************************************/

`timescale 1ns/1ps

// Include shared definitions
`include "RV32IM_Defines.vh"

module ALU_RV32IM(
    input  wire [4:0]  AluOP,
    input  wire [31:0] X,
    input  wire [31:0] Y,

    output wire        Less,       // For SLT result
    output wire        Equal,      // For BEQ
    output wire        GE,         // For BGE
    output wire [31:0] Result,     // Primary result
    output wire [31:0] Result_2    // Secondary result (for MULH/REM)
);

    // 直接使用 Verilog 操作
    wire [31:0] add_result  = X + Y;
    wire [31:0] sub_result  = X - Y;
    wire [31:0] and_result  = X & Y;
    wire [31:0] or_result   = X | Y;
    wire [31:0] xor_result  = X ^ Y;
    wire [31:0] nor_result  = ~(X | Y);
    wire [31:0] sll_result  = X << Y[4:0];
    wire [31:0] srl_result  = X >> Y[4:0];
    wire [31:0] sra_result  = $signed(X) >>> Y[4:0];

    // 比较操作
    wire less_signed   = $signed(X) < $signed(Y);
    wire less_unsigned = X < Y;
    wire equal_flag    = (X == Y);

    // 乘除法 (简化版)
    wire [63:0] mul_result_u_u = X * Y;
    wire [63:0] mul_result_s_s = $signed(X) * $signed(Y);
    wire [63:0] mul_result_s_u = $signed(X) * $signed({1'b0, Y});

    wire [31:0] mul_low    = mul_result_u_u[31:0];
    
    wire [31:0] div_quot   = (Y != 0) ? $signed($signed(X) / $signed(Y)) : 32'hFFFFFFFF;
    wire [31:0] div_rem    = (Y != 0) ? $signed($signed(X) % $signed(Y)) : X;
    wire [31:0] divu_quot  = (Y != 0) ? (X / Y) : 32'hFFFFFFFF;
    wire [31:0] divu_rem   = (Y != 0) ? (X % Y) : X;

    // 结果选择
    reg [31:0] result_mux;
    reg [31:0] result_2_mux;

    always @(*) begin
        case (AluOP)
            `ALU_SLL:    result_mux = sll_result;
            `ALU_SRA:    result_mux = sra_result;
            `ALU_SRL:    result_mux = srl_result;
            `ALU_MUL:    result_mux = mul_low;
            `ALU_DIV:    result_mux = div_quot;
            `ALU_DIVU:   result_mux = divu_quot;
            `ALU_REM:    result_mux = div_rem;
            `ALU_REMU:   result_mux = divu_rem;
            `ALU_ADD:    result_mux = add_result;
            `ALU_SUB:    result_mux = sub_result;
            `ALU_AND:    result_mux = and_result;
            `ALU_OR:     result_mux = or_result;
            `ALU_XOR:    result_mux = xor_result;
            `ALU_SLT:    result_mux = {31'b0, less_signed};
            `ALU_SLTU:   result_mux = {31'b0, less_unsigned};
            `ALU_MULH:   result_mux = mul_result_s_s[63:32];
            `ALU_MULHU:  result_mux = mul_result_u_u[63:32];
            `ALU_MULHSU: result_mux = mul_result_s_u[63:32];
            default:     result_mux = add_result;
        endcase
    end

    always @(*) begin
        case (AluOP)
            `ALU_MUL:    result_2_mux = mul_result_u_u[63:32];
            default:     result_2_mux = 32'b0;
        endcase
    end

    assign Result   = result_mux;
    assign Result_2 = result_2_mux;
    assign Less     = less_signed;
    assign Equal    = equal_flag;
    assign GE       = ~less_signed;

endmodule
