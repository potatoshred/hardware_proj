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
    input  wire        CLK100MHZ,      // 100MHz系统时钟
    input  wire        CLKCPU,   // CPU时钟
    input  wire        CLKVGA,   // 25MHz像素时钟
    input  wire        CPU_RESETN,     // CPU复位按钮 (低电平有效)
    
    // 开关输入
    input  wire [2:0]  SW,             // 开关 (用于选择测试图案)

    // Frame Buffer接口 (来自CPU)
    input  wire        fb_we,          // Frame Buffer写使能
    input  wire [31:0] fb_addr,        // Frame Buffer地址
    input  wire [31:0] fb_wdata,       // Frame Buffer写数据

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
    wire [11:0] pixel_data;            // 测试图案像素数据
    wire [11:0] fb_pixel_data;         // Frame Buffer像素数据

    
    //=========================================================================
    // 模式选择逻辑
    //=========================================================================
    // SW[2:0] == 3'b111 (7): 使用Frame Buffer
    // SW[2:0] == 其他值: 使用测试图案
    wire use_framebuffer;
    assign use_framebuffer = (SW == 3'b111);

    //=========================================================================
    // VGA控制器实例化
    //=========================================================================
    vga_controller u_vga_controller (
        .clk_100mhz      (CLK100MHZ),
        .rst_n           (CPU_RESETN),
        .vga_r           (VGA_R),
        .vga_g           (VGA_G),
        .vga_b           (VGA_B),
        .vga_hs          (VGA_HS),
        .vga_vs          (VGA_VS),
        .pixel_x         (pixel_x),
        .pixel_y         (pixel_y),
        .video_on        (video_on),
        .pixel_data      (pixel_data),
        .use_framebuffer (use_framebuffer),
        .fb_pixel_data   (fb_pixel_data)
    );
    
    //=========================================================================
    // 测试图案生成器实例化
    //=========================================================================
    vga_test_pattern u_test_pattern (
        .clk          (CLKVGA),
        .rst_n        (CPU_RESETN),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .video_on     (video_on),
        .pattern_sel  (SW),
        .pixel_data   (pixel_data)
    );

    //=========================================================================
    // Frame Buffer 实例化
    //=========================================================================
    // 使用vga_controller导出的25MHz像素时钟，确保时钟域同步
    vga_framebuffer u_framebuffer (
        // CPU写端口
        .clk_cpu     (CLKCPU),
        .we_cpu      (fb_we),
        .addr_cpu    (fb_addr),
        .wdata_cpu   (fb_wdata),

        // VGA读端口 (使用vga_controller的25MHz像素时钟)
        .clk_vga     (CLKVGA),
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .pixel_data  (fb_pixel_data)
    );
    
    //=========================================================================
    // LED状态显示
    //=========================================================================
    assign LED = SW;             // 显示当前选择的图案编号

endmodule
