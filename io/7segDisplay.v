`timescale 1ns/1ps

`timescale 1ns/1ps

module sevenseg_display_top(
    input               clk,        // 系统时钟
    input               rst,        // 复位信号，高电平有效
    input   [31:0]      data_in,    // 32位输入数据，显示8位十六进制数
    output  [7:0]       seg_sel,    // 8位数码管位选信号（低电平有效）
    output  [7:0]       seg_patt    // 7段数码管段选信号（低电平有效）
);

    // 分频计数器参数
    // 假设输入时钟为100MHz，分频到约1kHz用于数码管扫描
    // 每个数码管显示约125Hz，人眼感觉不到闪烁
    parameter DIVIDER = 100000;  // 100MHz / 100000 = 1kHz

    // 扫描计数器（0-7循环）
    wire [2:0] scan_cnt;

    // 当前显示的4位数据
    wire [3:0] current_slice;

    // 段选信号
    wire [7:0] seg_pattern;


    //========================================
    // 实例化计数器：生成扫描索引
    //========================================
    counter u_counter(
        .clk(clk),
        .out(scan_cnt)
    );

    //========================================
    // 实例化显示选择模块：选择当前要显示的4位数据
    //========================================
    display_sel u_display_sel(
        .idx(scan_cnt),
        .dig(data_in),
        .slice(current_slice)
    );

    //========================================
    // 实例化3-8译码器：生成位选信号
    //========================================
    decoder3_8 u_decoder3_8(
        .num(scan_cnt),
        .sel(seg_sel)
    );

    //========================================
    // 实例化7段译码器：将4位十六进制转换为段选信号
    //========================================
    sevenseg_dec u_sevenseg_dec(
        .code(current_slice),
        .patt(seg_pattern)
    );

    //========================================
    // 输出段选信号
    //========================================
    assign seg_patt = seg_pattern;

endmodule


module decoder3_8(num, sel);
    input [2: 0] num;
    output [7:0] sel;

    reg [7:0] SEG_w;
    assign sel = SEG_w; 

    always @(num[2:0]) begin
        case(num[2:0])
            3'h0:SEG_w     = 8'b11111110;
            3'h1:SEG_w     = 8'b11111101;
            3'h2:SEG_w     = 8'b11111011;
            3'h3:SEG_w     = 8'b11110111;
            3'h4:SEG_w     = 8'b11101111;
            3'h5:SEG_w     = 8'b11011111;
            3'h6:SEG_w     = 8'b10111111;
            default :SEG_w = 8'b01111111;
        endcase
	end
endmodule

module display_sel(idx, dig, slice);
    input   [2: 0]    idx;
    input   [31:0]    dig;
    output reg [3:0]  slice;
    always @* begin
        case(idx)
            3'd0: slice = dig[3:0];
            3'd1: slice = dig[7:4];
            3'd2: slice = dig[11:8];
            3'd3: slice = dig[15:12];
            3'd4: slice = dig[19:16];
            3'd5: slice = dig[23:20];
            3'd6: slice = dig[27:24];
            3'd7: slice = dig[31:28];
            default: slice = 4'h0;
        endcase
    end
endmodule

`timescale 1ns/1ps
module sevenseg_dec(code, patt);
    input [3: 0] code;
    output [7:0] patt;

    reg [7:0] SEG_w;
    assign patt = SEG_w; 
	always @(code[3:0]) begin
        case(code[3:0])
            4'h0:SEG_w     = 8'b11000000;
            4'h1:SEG_w     = 8'b11111001;
            4'h2:SEG_w     = 8'b10100100;
            4'h3:SEG_w     = 8'b10110000;
            4'h4:SEG_w     = 8'b10011001;
            4'h5:SEG_w     = 8'b10010010;
            4'h6:SEG_w     = 8'b10000010;
            4'h7:SEG_w     = 8'b11111000;
            4'h8:SEG_w     = 8'b10000000;
            4'h9:SEG_w     = 8'b10011000;
            4'hA:SEG_w     = 8'b10001000;
            4'hB:SEG_w     = 8'b10000011;
            4'hC:SEG_w     = 8'b11000110;
            4'hD:SEG_w     = 8'b10100001;
            4'hE:SEG_w     = 8'b10000110;
            default :SEG_w = 8'b10001110;
        endcase
	end
    
endmodule

module counter(clk, out);
    input clk;                    // 计数时钟
    output reg [2:0] out;         // 计数值

    always @(posedge clk)  begin  // 在时钟上升沿计数器加1
        out <= out + 1;           // 在时钟上升沿计数器加1
    end                           
endmodule

