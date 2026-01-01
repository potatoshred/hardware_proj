/******************************************************************************
 ** Logisim goes FPGA automatic generated Verilog code                       **
 **                                                                          **
 ** Component : REGISTER_FLIP_FLOP                                           **
 **                                                                          **
 ******************************************************************************/

`timescale 1ns/1ps
module REGISTER_FLIP_FLOP #(
    parameter WIDTH = 32
)(
    input wire clk,      // 时钟信号
    input wire rst,     // 异步复位信号，高电平有效 (Active-High)
    input wire e,        // 同步使能信号，高电平有效
    input wire [WIDTH-1:0] d, // 可变宽度数据输入
    output reg [WIDTH-1:0] q  // 可变宽度数据输出
);
    initial begin 
        q = {WIDTH{1'b0}};
    end 
    // 主要行为逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin     // 异步复位：优先级最高
            q <= {WIDTH{1'b0}};      // 复位时输出清零
        end else if (e) begin // 同步使能：在时钟上升沿判断
            q <= d;          // 使能有效时，锁存输入数据
        end
        // 如果使能无效，q 保持原值不变
    end

endmodule
