/**
 * VGA顶层模块 - Nexys4 DDR (Artix-7) 开发板
 * 
 * 功能描述:
 * - 集成VGA控制器和测试图案生成器
 * - 使用3个开关选择测试图案
 * - 使用按钮进行复位
 * 
 * 端口连接:
 * - 100MHz系统时钟
 * - SW[2:0]: 选择测试图案 (0-7)
 * - CPU_RESETN: 复位按钮 (低电平有效)
 * - VGA接口: R[3:0], G[3:0], B[3:0], HS, VS
 */

module vga_top (
    // 系统时钟和复位
    input  wire        CLK,      // 100MHz系统时钟
    input  wire        CPU_RESETN,     // CPU复位按钮 (低电平有效)
    
    // 开关输入
    input  wire [2:0]  SW,             // 开关 (用于选择测试图案)
    
    // VGA输出
    output wire [3:0]  VGA_R,          // VGA红色信号
    output wire [3:0]  VGA_G,          // VGA绿色信号
    output wire [3:0]  VGA_B,          // VGA蓝色信号
    output wire        VGA_HS,         // VGA水平同步
    output wire        VGA_VS,         // VGA垂直同步
    
    // LED输出 (用于状态指示)
    output wire [2:0]  LED             // 显示当前选择的图案
);

    //=========================================================================
    // 内部信号定义
    //=========================================================================
    wire [9:0]  pixel_x;               // 当前像素X坐标
    wire [9:0]  pixel_y;               // 当前像素Y坐标
    wire        video_on;              // 视频有效区域标志
    wire [11:0] pixel_data;            // 像素数据
    
    // 开关同步 (防止亚稳态) - 3级同步确保时钟域跨越稳定
    reg [2:0] sw_sync1, sw_sync2, sw_sync3;

    always @(posedge CLK) begin
        sw_sync1 <= SW;
        sw_sync2 <= sw_sync1;
        sw_sync3 <= sw_sync2;
    end
    
    //=========================================================================
    // VGA控制器实例化
    //=========================================================================
    vga_controller u_vga_controller (
        .clk_100mhz   (CLK),
        .rst_n        (CPU_RESETN),
        .vga_r        (VGA_R),
        .vga_g        (VGA_G),
        .vga_b        (VGA_B),
        .vga_hs       (VGA_HS),
        .vga_vs       (VGA_VS),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .video_on     (video_on),
        .pixel_data   (pixel_data)
    );
    
    //=========================================================================
    // 测试图案生成器实例化
    //=========================================================================
    vga_test_pattern u_test_pattern (
        .clk          (CLK),
        .rst_n        (CPU_RESETN),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .video_on     (video_on),
        .pattern_sel  (sw_sync3),
        .pixel_data   (pixel_data)
    );
    
    //=========================================================================
    // LED状态显示
    //=========================================================================
    assign LED = sw_sync3;             // 显示当前选择的图案编号

endmodule
