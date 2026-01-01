/******************************************************************************
 ** Logisim goes FPGA automatic generated Verilog code                       **
 **                                                                          **
 ** Component : Priority_Encoder                                             **
 **                                                                          **
 ******************************************************************************/

`timescale 1ns/1ps
module Priority_Encoder (
    input [3:0] in,      // 4位输入信号，in[3]优先级最高，in[0]优先级最低
    output reg [1:0] out, // 2位二进制编码输出
    output reg valid      // 有效标志位：1表示至少有一个输入为1，0表示所有输入均为0
);

// 组合逻辑，使用 always 块和 if-else 语句描述优先级
always @(*) begin
    if (in[3]) begin         // 最高优先级：in[3] 为 1
        out = 2'b11;
        valid = 1'b1;
    end
    else if (in[2]) begin    // 次高优先级：in[2] 为 1
        out = 2'b10;
        valid = 1'b1;
    end
    else if (in[1]) begin    // 第三优先级：in[1] 为 1
        out = 2'b01;
        valid = 1'b1;
    end
    else if (in[0]) begin    // 最低优先级：in[0] 为 1
        out = 2'b00;
        valid = 1'b1;
    end
    else begin               // 所有输入都为 0
        out = 2'b00;        // 此时输出可任意，但通常设为0或特定值
        valid = 1'b0;       // 有效标志位为0，表示无有效输入
    end
end

endmodule
