/**
 * VGA测试图案生成模块
 * 用于验证VGA显示功能
 * 
 * 包含多种测试图案:
 * - 彩色条纹
 * - 棋盘格
 * - 渐变色
 * - 边框
 */

module vga_test_pattern (
    input  wire        clk,            // 时钟信号
    input  wire        rst_n,          // 复位信号(低电平有效)
    input  wire [9:0]  pixel_x,        // 像素X坐标
    input  wire [9:0]  pixel_y,        // 像素Y坐标
    input  wire        video_on,       // 视频有效区域标志
    input  wire [2:0]  pattern_sel,    // 图案选择 (0-7)
    output reg  [11:0] pixel_data      // 像素数据输出 {R,G,B}
);

    //=========================================================================
    // 常用颜色定义 (12位: R[3:0], G[3:0], B[3:0])
    //=========================================================================
    localparam COLOR_BLACK   = 12'h000;  // 黑色
    localparam COLOR_WHITE   = 12'hFFF;  // 白色
    localparam COLOR_RED     = 12'hF00;  // 红色
    localparam COLOR_GREEN   = 12'h0F0;  // 绿色
    localparam COLOR_BLUE    = 12'h00F;  // 蓝色
    localparam COLOR_YELLOW  = 12'hFF0;  // 黄色
    localparam COLOR_CYAN    = 12'h0FF;  // 青色
    localparam COLOR_MAGENTA = 12'hF0F;  // 品红色
    
    //=========================================================================
    // 图案0: 彩色竖条纹 (8色)
    //=========================================================================
    reg [11:0] color_bars;
    
    always @(*) begin
        case (pixel_x[9:7])  // 将屏幕分成8个竖条
            3'd0: color_bars = COLOR_WHITE;
            3'd1: color_bars = COLOR_YELLOW;
            3'd2: color_bars = COLOR_CYAN;
            3'd3: color_bars = COLOR_GREEN;
            3'd4: color_bars = COLOR_MAGENTA;
            3'd5: color_bars = COLOR_RED;
            3'd6: color_bars = COLOR_BLUE;
            3'd7: color_bars = COLOR_BLACK;
            default: color_bars = COLOR_BLACK;
        endcase
    end
    
    //=========================================================================
    // 图案1: 棋盘格
    //=========================================================================
    wire [11:0] checkerboard;
    wire check_pattern;
    
    // 32x32像素的棋盘格
    assign check_pattern = pixel_x[5] ^ pixel_y[5];
    assign checkerboard = check_pattern ? COLOR_WHITE : COLOR_BLACK;
    
    //=========================================================================
    // 图案2: 水平渐变色 (红色)
    //=========================================================================
    wire [11:0] gradient_h;
    wire [3:0] grad_h_val;
    
    // 将640像素映射到16级灰度
    assign grad_h_val = pixel_x[9:6];
    assign gradient_h = {grad_h_val, 4'h0, 4'h0};  // 红色渐变
    
    //=========================================================================
    // 图案3: 垂直渐变色 (绿色)
    //=========================================================================
    wire [11:0] gradient_v;
    wire [3:0] grad_v_val;
    
    // 将480像素映射到16级灰度
    assign grad_v_val = pixel_y[8:5];
    assign gradient_v = {4'h0, grad_v_val, 4'h0};  // 绿色渐变
    
    //=========================================================================
    // 图案4: 边框测试
    //=========================================================================
    wire [11:0] border_pattern;
    wire is_border;
    
    // 1像素边框
    assign is_border = (pixel_x == 0) || (pixel_x == 639) || 
                       (pixel_y == 0) || (pixel_y == 479);
    assign border_pattern = is_border ? COLOR_WHITE : COLOR_BLUE;
    
    //=========================================================================
    // 图案5: RGB色块
    //=========================================================================
    reg [11:0] rgb_blocks;
    
    always @(*) begin
        if (pixel_y < 160)
            rgb_blocks = COLOR_RED;      // 上部红色
        else if (pixel_y < 320)
            rgb_blocks = COLOR_GREEN;    // 中部绿色
        else
            rgb_blocks = COLOR_BLUE;     // 下部蓝色
    end
    
    //=========================================================================
    // 图案6: 交叉线
    //=========================================================================
    wire [11:0] crosshair;
    wire is_crosshair;
    
    // 中心十字线
    assign is_crosshair = (pixel_x == 320) || (pixel_y == 240) ||
                          // 对角线
                          (pixel_x == pixel_y) || 
                          (pixel_x == (639 - pixel_y));
    assign crosshair = is_crosshair ? COLOR_WHITE : COLOR_BLACK;
    
    //=========================================================================
    // 图案7: 彩虹渐变
    //=========================================================================
    wire [11:0] rainbow;
    wire [3:0] rainbow_r, rainbow_g, rainbow_b;
    
    // 基于X坐标的彩虹渐变
    assign rainbow_r = (pixel_x < 213) ? 4'hF : 
                       (pixel_x < 426) ? 4'hF - pixel_x[7:4] : 4'h0;
    assign rainbow_g = (pixel_x < 213) ? pixel_x[7:4] : 
                       (pixel_x < 426) ? 4'hF : 4'hF - pixel_x[7:4];
    assign rainbow_b = (pixel_x < 213) ? 4'h0 : 
                       (pixel_x < 426) ? pixel_x[7:4] : 4'hF;
    assign rainbow = {rainbow_r, rainbow_g, rainbow_b};
    
    //=========================================================================
    // 图案选择输出
    //=========================================================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_data <= COLOR_BLACK;
        end
        else if (!video_on) begin
            pixel_data <= COLOR_BLACK;
        end
        else begin
            case (pattern_sel)
                3'd1: pixel_data <= color_bars;      // 彩色条纹
                3'd0: pixel_data <= checkerboard;    // 棋盘格
                3'd2: pixel_data <= gradient_h;      // 水平渐变
                3'd3: pixel_data <= gradient_v;      // 垂直渐变
                3'd4: pixel_data <= border_pattern;  // 边框测试
                3'd5: pixel_data <= rgb_blocks;      // RGB色块
                3'd6: pixel_data <= crosshair;       // 交叉线
                3'd7: pixel_data <= rainbow;         // 彩虹渐变
                default: pixel_data <= COLOR_BLACK;
            endcase
        end
    end

endmodule
