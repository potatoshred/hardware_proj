`timescale 1ns / 1ps
/******************************************************************************
** PS/2 键盘接收模块 (精简版)
**
** 功能说明:
**   1. 接收 PS/2 物理信号
**   2. 解析扫描码 (Scancode)
**   3. 转换为 ASCII 码输出
**
** 依赖:
**   - ps2_transmitter.v (底层物理驱动)
******************************************************************************/

module ps2_keyboard(
    input             clk,              // 系统时钟 100MHz
    input             rst,              // 系统复位

    // PS/2 物理接口
    inout             ps2_clk,
    inout             ps2_data,

    // ASCII 输出接口
    output reg [7:0]  ascii_out,        // 转换后的 ASCII 码
    output reg        ascii_valid       // 有效标志 (单周期脉冲)
);

    //==========================================================================
    // PS/2 接口信号处理
    //==========================================================================
    wire   ps2_clk_out;
    wire   ps2_clk_in;
    wire   ps2_data_out;
    wire   ps2_data_in;
    wire   ps2_clk_oe;
    wire   ps2_data_oe;

    // 三态门控制
    assign ps2_clk  = (ps2_clk_oe)  ? ps2_clk_out  : 1'bz;
    assign ps2_data = (ps2_data_oe) ? ps2_data_out : 1'bz;
    assign ps2_clk_in  = ps2_clk;
    assign ps2_data_in = ps2_data;

    //==========================================================================
    // PS/2 收发器实例化
    //==========================================================================
    wire [7:0] rx_data;         // 接收到的原始扫描码
    wire       rx_valid;        // 接收完成标志
    wire       rx_error;        // 接收错误标志
    wire       tx_busy;         // 发送忙标志

    ps2_transmitter u_ps2_phy(
        .clk(clk),
        .rst(rst),

        // 物理接口连接
        .clock_in(ps2_clk_in),
        .serial_data_in(ps2_data_in),
        .clock_out(ps2_clk_out),
        .serial_data_out(ps2_data_out),
        .clock_output_oe(ps2_clk_oe),
        .data_output_oe(ps2_data_oe),

        // 数据接口
        .parallel_data_in(rx_data),
        .parallel_data_valid(rx_valid),
        .data_in_error(rx_error),

        // 发送接口 (本模块只读，发送端口接0)
        .parallel_data_out(8'h00),
        .parallel_data_enable(1'b0),
        .data_out_complete(),
        .busy(tx_busy)
    );

    //==========================================================================
    // 扫描码处理逻辑
    //==========================================================================
    // 简单的断码处理状态机
    // 键盘按下会发送通码 (Make Code)，释放会发送断码 (Break Code, F0 + Key)
    // 我们只在接收到通码时输出字符，忽略断码序列
    
    reg       prev_is_f0; // 上一个字节是否是 F0 (断码标志)
    reg [7:0] ascii_val;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ascii_out   <= 8'h00;
            ascii_valid <= 1'b0;
            prev_is_f0  <= 1'b0;
        end
        else begin
            // 默认拉低有效标志
            ascii_valid <= 1'b0;

            if (rx_valid && !rx_error) begin
                if (rx_data == 8'hF0) begin
                    // 收到断码标志，标记下一个字节需要忽略
                    prev_is_f0 <= 1'b1;
                end
                else begin
                    if (!prev_is_f0) begin
                        // 是通码 (按键按下)
                        ascii_val = scancode_to_ascii(rx_data);
                        if (ascii_val != 8'h00) begin
                            ascii_out   <= ascii_val;
                            ascii_valid <= 1'b1;
                        end
                    end
                    // 重置断码标志 (无论是通码还是断码后的那个字节，处理完都重置)
                    prev_is_f0 <= 1'b0;
                end
            end
        end
    end

    //==========================================================================
    // 扫描码转 ASCII 查找表
    //==========================================================================
    function [7:0] scancode_to_ascii;
        input [7:0] code;
        begin
            case(code)
                // 数字键
                8'h45: scancode_to_ascii = 8'h30; // 0
                8'h16: scancode_to_ascii = 8'h31; // 1
                8'h1E: scancode_to_ascii = 8'h32; // 2
                8'h26: scancode_to_ascii = 8'h33; // 3
                8'h25: scancode_to_ascii = 8'h34; // 4
                8'h2E: scancode_to_ascii = 8'h35; // 5
                8'h36: scancode_to_ascii = 8'h36; // 6
                8'h3D: scancode_to_ascii = 8'h37; // 7
                8'h3E: scancode_to_ascii = 8'h38; // 8
                8'h46: scancode_to_ascii = 8'h39; // 9

                // 字母键 (小写)
                8'h1C: scancode_to_ascii = 8'h61; // a
                8'h32: scancode_to_ascii = 8'h62; // b
                8'h21: scancode_to_ascii = 8'h63; // c
                8'h23: scancode_to_ascii = 8'h64; // d
                8'h24: scancode_to_ascii = 8'h65; // e
                8'h2B: scancode_to_ascii = 8'h66; // f
                8'h34: scancode_to_ascii = 8'h67; // g
                8'h33: scancode_to_ascii = 8'h68; // h
                8'h43: scancode_to_ascii = 8'h69; // i
                8'h3B: scancode_to_ascii = 8'h6A; // j
                8'h42: scancode_to_ascii = 8'h6B; // k
                8'h4B: scancode_to_ascii = 8'h6C; // l
                8'h3A: scancode_to_ascii = 8'h6D; // m
                8'h31: scancode_to_ascii = 8'h6E; // n
                8'h44: scancode_to_ascii = 8'h6F; // o
                8'h4D: scancode_to_ascii = 8'h70; // p
                8'h15: scancode_to_ascii = 8'h71; // q
                8'h2D: scancode_to_ascii = 8'h72; // r
                8'h1B: scancode_to_ascii = 8'h73; // s
                8'h2C: scancode_to_ascii = 8'h74; // t
                8'h3C: scancode_to_ascii = 8'h75; // u
                8'h2A: scancode_to_ascii = 8'h76; // v
                8'h1D: scancode_to_ascii = 8'h77; // w
                8'h22: scancode_to_ascii = 8'h78; // x
                8'h35: scancode_to_ascii = 8'h79; // y
                8'h1A: scancode_to_ascii = 8'h7A; // z

                // 功能键
                8'h29: scancode_to_ascii = 8'h20; // Space
                8'h5A: scancode_to_ascii = 8'h0D; // Enter
                8'h66: scancode_to_ascii = 8'h08; // Backspace
                8'h0D: scancode_to_ascii = 8'h09; // Tab
                8'h76: scancode_to_ascii = 8'h1B; // Esc

                // 符号
                8'h0E: scancode_to_ascii = 8'h60; // `
                8'h4E: scancode_to_ascii = 8'h2D; // -
                8'h55: scancode_to_ascii = 8'h3D; // =
                8'h54: scancode_to_ascii = 8'h5B; // [
                8'h5B: scancode_to_ascii = 8'h5D; // ]
                8'h5D: scancode_to_ascii = 8'h5C; // \
                8'h4C: scancode_to_ascii = 8'h3B; // ;
                8'h52: scancode_to_ascii = 8'h27; // '
                8'h41: scancode_to_ascii = 8'h2C; // ,
                8'h49: scancode_to_ascii = 8'h2E; // .
                8'h4A: scancode_to_ascii = 8'h2F; // /

                default: scancode_to_ascii = 8'h00;
            endcase
        end
    endfunction

endmodule
