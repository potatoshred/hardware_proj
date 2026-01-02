/******************************************************************************
** USB键盘模块 - 支持PS/2键盘和串口双向通信
**
** 功能说明:
**   1. PS/2键盘输入 -> 扫描码转ASCII -> 串口发送
**   2. 串口接收 -> ASCII字符 -> 串口回显 (可选)
**   3. 串口接收 -> 特殊命令 -> PS/2键盘控制 (可选)
**
** 串口参数:
**   - 波特率: 115200 bps
**   - 数据位: 8
**   - 停止位: 1
**   - 无奇偶校验
**
** 数据流向:
**   [物理键盘] -> PS/2接口 -> 扫描码解析 -> ASCII -> UART TXD
**   UART RXD -> ASCII -> UART TXD (回显) 或 -> PS/2命令
**
** 版本: 2.1
** 修改: 修复多驱动源问题，统一UART发送逻辑
******************************************************************************/

module usb_keyboard(
    input             clk,              // 系统时钟 100MHz
    input             rst,              // 系统复位

    // PS/2键盘接口 (双向)
    inout             USB_CLOCK,
    inout             USB_DATA,

    // UART串口接口
    input             RXD,              // UART接收引脚
    output reg        TXD,              // UART发送引脚
    output reg        CTS,              // Clear To Send (低电平=允许发送)
    input             RTS,              // Request To Send (低电平=请求发送)

    // ASCII输出到数码管显示
    output reg [7:0]  ascii_out,        // 接收到的ASCII码
    output reg        ascii_valid       // ASCII数据有效标志（单周期脉冲）
);

//==============================================================================
// 参数定义
//==============================================================================
parameter CLK_FREQ = 100_000_000;       // 系统时钟频率 100MHz
parameter BAUD_RATE = 115200;            // 波特率 115200
localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;  // 波特率分频: 868

//==============================================================================
// PS/2接口信号
//==============================================================================
wire   USB_CLOCK_OE;                    // PS/2时钟输出使能
wire   USB_DATA_OE;                     // PS/2数据输出使能
wire   USB_CLOCK_out;                   // PS/2时钟输出
wire   USB_CLOCK_in;                    // PS/2时钟输入
wire   USB_DATA_out;                    // PS/2数据输出
wire   USB_DATA_in;                     // PS/2数据输入

// 三态总线控制
assign USB_CLOCK = (USB_CLOCK_OE) ? USB_CLOCK_out : 1'bz;
assign USB_DATA = (USB_DATA_OE) ? USB_DATA_out : 1'bz;
assign USB_CLOCK_in = USB_CLOCK;
assign USB_DATA_in = USB_DATA;

//==============================================================================
// PS/2收发器信号
//==============================================================================
wire       PS2_valid;                   // PS/2数据有效
wire [7:0] PS2_data_in;                 // PS/2接收数据(扫描码)
wire       PS2_busy;                    // PS/2忙碌标志
wire       PS2_error;                   // PS/2错误标志
wire       PS2_complete;                // PS/2发送完成
reg        PS2_enable;                  // PS/2发送使能
(* dont_touch = "true" *) reg [7:0] PS2_data_out;  // PS/2发送数据

// 用于ChipScope调试
(* dont_touch = "true" *) reg  USB_CLOCK_d;
(* dont_touch = "true" *) reg  USB_DATA_d;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        USB_CLOCK_d <= 1'b0;
        USB_DATA_d  <= 1'b0;
    end
    else begin
        USB_CLOCK_d <= USB_CLOCK_in;
        USB_DATA_d <= USB_DATA_in;
    end
end

//==============================================================================
// PS/2收发器实例化
//==============================================================================
ps2_transmitter ps2_transmitter(
    .clk(clk),
    .rst(rst),

    // PS/2接收
    .clock_in(USB_CLOCK_in),
    .serial_data_in(USB_DATA_in),
    .parallel_data_in(PS2_data_in),
    .parallel_data_valid(PS2_valid),
    .busy(PS2_busy),
    .data_in_error(PS2_error),

    // PS/2发送
    .clock_out(USB_CLOCK_out),
    .serial_data_out(USB_DATA_out),
    .parallel_data_out(PS2_data_out),
    .parallel_data_enable(PS2_enable),
    .data_out_complete(PS2_complete),

    .clock_output_oe(USB_CLOCK_OE),
    .data_output_oe(USB_DATA_OE)
);

//==============================================================================
// PS/2扫描码到ASCII转换查找表
//==============================================================================
function [7:0] scancode_to_ascii;
    input [7:0] scancode;
    begin
        case(scancode)
            // 数字键 (主键盘区)
            8'h45: scancode_to_ascii = 8'h30;  // 0
            8'h16: scancode_to_ascii = 8'h31;  // 1
            8'h1E: scancode_to_ascii = 8'h32;  // 2
            8'h26: scancode_to_ascii = 8'h33;  // 3
            8'h25: scancode_to_ascii = 8'h34;  // 4
            8'h2E: scancode_to_ascii = 8'h35;  // 5
            8'h36: scancode_to_ascii = 8'h36;  // 6
            8'h3D: scancode_to_ascii = 8'h37;  // 7
            8'h3E: scancode_to_ascii = 8'h38;  // 8
            8'h46: scancode_to_ascii = 8'h39;  // 9

            // 字母键 (小写)
            8'h1C: scancode_to_ascii = 8'h61;  // a
            8'h32: scancode_to_ascii = 8'h62;  // b
            8'h21: scancode_to_ascii = 8'h63;  // c
            8'h23: scancode_to_ascii = 8'h64;  // d
            8'h24: scancode_to_ascii = 8'h65;  // e
            8'h2B: scancode_to_ascii = 8'h66;  // f
            8'h34: scancode_to_ascii = 8'h67;  // g
            8'h33: scancode_to_ascii = 8'h68;  // h
            8'h43: scancode_to_ascii = 8'h69;  // i
            8'h3B: scancode_to_ascii = 8'h6A;  // j
            8'h42: scancode_to_ascii = 8'h6B;  // k
            8'h4B: scancode_to_ascii = 8'h6C;  // l
            8'h3A: scancode_to_ascii = 8'h6D;  // m
            8'h31: scancode_to_ascii = 8'h6E;  // n
            8'h44: scancode_to_ascii = 8'h6F;  // o
            8'h4D: scancode_to_ascii = 8'h70;  // p
            8'h15: scancode_to_ascii = 8'h71;  // q
            8'h2D: scancode_to_ascii = 8'h72;  // r
            8'h1B: scancode_to_ascii = 8'h73;  // s
            8'h2C: scancode_to_ascii = 8'h74;  // t
            8'h3C: scancode_to_ascii = 8'h75;  // u
            8'h2A: scancode_to_ascii = 8'h76;  // v
            8'h1D: scancode_to_ascii = 8'h77;  // w
            8'h22: scancode_to_ascii = 8'h78;  // x
            8'h35: scancode_to_ascii = 8'h79;  // y
            8'h1A: scancode_to_ascii = 8'h7A;  // z

            // 特殊键
            8'h29: scancode_to_ascii = 8'h20;  // Space 空格
            8'h5A: scancode_to_ascii = 8'h0D;  // Enter 回车
            8'h66: scancode_to_ascii = 8'h08;  // Backspace 退格
            8'h0D: scancode_to_ascii = 8'h09;  // Tab 制表符
            8'h76: scancode_to_ascii = 8'h1B;  // Esc 退出键

            // 符号键
            8'h0E: scancode_to_ascii = 8'h60;  // ` 反引号
            8'h4E: scancode_to_ascii = 8'h2D;  // - 减号
            8'h55: scancode_to_ascii = 8'h3D;  // = 等号
            8'h54: scancode_to_ascii = 8'h5B;  // [ 左方括号
            8'h5B: scancode_to_ascii = 8'h5D;  // ] 右方括号
            8'h5D: scancode_to_ascii = 8'h5C;  // \ 反斜杠
            8'h4C: scancode_to_ascii = 8'h3B;  // ; 分号
            8'h52: scancode_to_ascii = 8'h27;  // ' 单引号
            8'h41: scancode_to_ascii = 8'h2C;  // , 逗号
            8'h49: scancode_to_ascii = 8'h2E;  // . 句号
            8'h4A: scancode_to_ascii = 8'h2F;  // / 斜杠

            // 默认: 不可打印字符返回0
            default: scancode_to_ascii = 8'h00;
        endcase
    end
endfunction

//==============================================================================
// UART接收模块
//==============================================================================
(* dont_touch = "true" *) reg [7:0] RXD_delay;
reg [15:0] uart_rx_count;               // UART接收波特率计数器
(* dont_touch = "true" *) reg [3:0] rx_bit_count;
reg        rx_start;                    // 接收开始标志
reg [7:0]  rx_data_reg;                 // 接收数据寄存器
reg        rx_data_ready;               // 接收数据就绪标志
reg [2:0]  RXD_sync;                    // RXD同步寄存器（防止亚稳态）

// 同步RXD信号到clk时钟域
always @(posedge clk or posedge rst) begin
    if(rst)
        RXD_sync <= 3'b111;
    else
        RXD_sync <= {RXD_sync[1:0], RXD};
end

wire RXD_stable = RXD_sync[2];  // 使用3级同步后的稳定信号

always @(posedge clk or posedge rst) begin
    if(rst) begin
        RXD_delay <= 8'h00;
        uart_rx_count <= 16'd0;
        rx_bit_count <= 4'd0;
        rx_start <= 1'b0;
        rx_data_reg <= 8'h00;
        rx_data_ready <= 1'b0;
        PS2_enable <= 1'b0;
        PS2_data_out <= 8'h00;
        ascii_out <= 8'h00;
        ascii_valid <= 1'b0;
    end
    else if(~RTS) begin  // RTS低电平时允许接收
        // 默认：清除单周期脉冲标志
        ascii_valid <= 1'b0;
        rx_data_ready <= 1'b0;
        PS2_enable <= 1'b0;

        // PS/2 输入处理 (新增)
        if (PS2_valid) begin
             if(scancode_to_ascii(PS2_data_in) != 8'h00) begin
                 ascii_out <= scancode_to_ascii(PS2_data_in);
                 ascii_valid <= 1'b1;
             end
        end

        if(~rx_start) begin
            // 空闲状态：检测起始位（RXD下降沿）
            if(~RXD_stable) begin
                rx_start <= 1'b1;
                uart_rx_count <= 16'd0;
                rx_bit_count <= 4'd0;
                RXD_delay <= 8'h00;
            end
        end
        else begin
            // 接收状态：波特率计数
            if(uart_rx_count < BAUD_DIV - 1) begin
                uart_rx_count <= uart_rx_count + 16'd1;
            end
            else begin
                uart_rx_count <= 16'd0;

                // 在波特率周期中间采样
                if(rx_bit_count < 4'd8) begin
                    // 接收8位数据（LSB先）
                    RXD_delay <= {RXD_stable, RXD_delay[7:1]};
                    rx_bit_count <= rx_bit_count + 4'd1;
                end
                else begin
                    // 接收完成（忽略停止位）
                    rx_start <= 1'b0;
                    rx_bit_count <= 4'd0;
                    rx_data_reg <= RXD_delay;
                    rx_data_ready <= 1'b1;

                    // ★ 输出ASCII码到数码管（单周期脉冲）
                    ascii_out <= RXD_delay;
                    ascii_valid <= 1'b1;

                    // 特殊命令处理 (可选, 用于PS/2键盘控制)
                    case(RXD_delay)
                        8'h0C: begin  // Ctrl+L - 复位键盘
                            PS2_enable <= 1'b1;
                            PS2_data_out <= 8'hFF;
                        end
                        8'h03: begin  // Ctrl+C - 回显测试
                            PS2_enable <= 1'b1;
                            PS2_data_out <= 8'hEE;
                        end
                        default: begin
                            PS2_enable <= 1'b0;
                        end
                    endcase
                end
            end
        end
    end
    else begin
        // RTS高电平时停止接收
        uart_rx_count <= 16'd0;
        rx_start <= 1'b0;
        rx_bit_count <= 4'd0;
        PS2_enable <= 1'b0;
        ascii_valid <= 1'b0;
        rx_data_ready <= 1'b0;
    end
end

//==============================================================================
// 统一的UART发送模块 - 处理PS/2数据和串口回显
//==============================================================================
reg [15:0] uart_tx_count;               // UART发送波特率计数器
reg [9:0]  uart_tx_shift;               // UART发送移位寄存器 (1起始+8数据+1停止)
reg        uart_tx_busy;                // UART发送忙碌标志

always @(posedge clk or posedge rst) begin
    if(rst) begin
        uart_tx_count <= 16'd0;
        uart_tx_shift <= 10'h3FF;       // 空闲时全1
        uart_tx_busy <= 1'b0;
        TXD <= 1'b1;                    // 空闲时高电平
        CTS <= 1'b1;                    // 空闲
    end
    else begin
        // 波特率计数器
        if(uart_tx_count < BAUD_DIV - 1) begin
            uart_tx_count <= uart_tx_count + 16'd1;
        end
        else begin
            uart_tx_count <= 16'd0;
        end

        // 优先级1: 串口回显（接收到数据立即回显）
        if(rx_data_ready && !uart_tx_busy) begin
            uart_tx_shift <= {1'b1, rx_data_reg, 1'b0};  // 停止位+数据+起始位
            uart_tx_busy <= 1'b1;
            CTS <= 1'b0;                // 发送中
        end
        // 优先级2: PS/2键盘数据发送
        else if(PS2_valid && !uart_tx_busy) begin
            // 只发送可打印字符
            if(scancode_to_ascii(PS2_data_in) != 8'h00) begin
                uart_tx_shift <= {1'b1, scancode_to_ascii(PS2_data_in), 1'b0};
                uart_tx_busy <= 1'b1;
                CTS <= 1'b0;            // 发送中
            end
        end
        // UART发送移位
        else if(uart_tx_busy && (uart_tx_count == 16'd0)) begin
            TXD <= uart_tx_shift[0];
            uart_tx_shift <= {1'b1, uart_tx_shift[9:1]};

            // 发送完成检测
            if(uart_tx_shift == 10'h3FF) begin
                uart_tx_busy <= 1'b0;
                CTS <= 1'b1;            // 空闲
                TXD <= 1'b1;
            end
        end
    end
end

endmodule
