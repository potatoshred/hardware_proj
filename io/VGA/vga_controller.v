/**
 * VGA控制器模块 - Nexys4 DDR (Artix-7) 开发板
 * 分辨率: 640x480 @ 60Hz
 * 像素时钟: 25.175MHz (使用25MHz近似)
 * 
 * VGA时序参数 (640x480 @ 60Hz):
 * 水平: 可见区域640, 前沿16, 同步脉冲96, 后沿48, 总计800
 * 垂直: 可见区域480, 前沿10, 同步脉冲2, 后沿33, 总计525
 */

module vga_controller (
    input  wire        pixel_clk,     // 25MHz像素时钟 (外部输入)
    input  wire        rst_n,          // 复位信号(低电平有效)
    
    // VGA输出信号
    output reg  [3:0]  vga_r,          // 红色信号 (4位)
    output reg  [3:0]  vga_g,          // 绿色信号 (4位)
    output reg  [3:0]  vga_b,          // 蓝色信号 (4位)
    output wire        vga_hs,         // 水平同步信号
    output wire        vga_vs,         // 垂直同步信号
    
    // 显示数据接口
    output wire [9:0]  pixel_x,        // 当前像素X坐标 (0-639)
    output wire [9:0]  pixel_y,        // 当前像素Y坐标 (0-479)
    output wire        video_on,       // 视频有效区域标志
    input  wire [11:0] pixel_data,     // 像素数据输入 {R[3:0], G[3:0], B[3:0]}

    // Frame Buffer模式选择
    input  wire        use_framebuffer, // 1=使用Frame Buffer, 0=使用测试图案
    input  wire [11:0] fb_pixel_data   // Frame Buffer像素数据
);

    //=========================================================================
    // VGA时序参数定义 (640x480 @ 60Hz)
    //=========================================================================
    
    // 水平时序参数
    localparam H_DISPLAY    = 640;     // 水平可见区域
    localparam H_FRONT      = 16;      // 水平前沿
    localparam H_SYNC       = 96;      // 水平同步脉冲宽度
    localparam H_BACK       = 48;      // 水平后沿
    localparam H_TOTAL      = 800;     // 水平总像素数
    
    // 垂直时序参数
    localparam V_DISPLAY    = 480;     // 垂直可见区域
    localparam V_FRONT      = 10;      // 垂直前沿
    localparam V_SYNC       = 2;       // 垂直同步脉冲宽度
    localparam V_BACK       = 33;      // 垂直后沿
    localparam V_TOTAL      = 525;     // 垂直总行数
    
    //=========================================================================
    // 时钟分频 - 已移除，直接使用外部输入的25MHz pixel_clk
    //=========================================================================
    /*
    reg [1:0] clk_div;                 // 时钟分频计数器
    wire      clk_25mhz;               // 25MHz像素时钟
    
    always @(posedge clk_100mhz or negedge rst_n) begin
        if (!rst_n)
            clk_div <= 2'b00;
        else
            clk_div <= clk_div + 1'b1;
    end
    
    assign clk_25mhz = clk_div[1];     // 100MHz / 4 = 25MHz
    */
    
    //=========================================================================
    // 水平和垂直计数器
    //=========================================================================
    reg [9:0] h_count;                 // 水平像素计数器 (0-799)
    reg [9:0] v_count;                 // 垂直行计数器 (0-524)
    
    // 水平计数器
    always @(posedge pixel_clk or negedge rst_n) begin
        if (!rst_n)
            h_count <= 10'd0;
        else if (h_count == H_TOTAL - 1)
            h_count <= 10'd0;
        else
            h_count <= h_count + 1'b1;
    end
    
    // 垂直计数器
    always @(posedge pixel_clk or negedge rst_n) begin
        if (!rst_n)
            v_count <= 10'd0;
        else if (h_count == H_TOTAL - 1) begin
            if (v_count == V_TOTAL - 1)
                v_count <= 10'd0;
            else
                v_count <= v_count + 1'b1;
        end
    end
    
    //=========================================================================
    //=========================================================================
    // 同步信号生成 (原始)
    //=========================================================================
    wire hs_raw, vs_raw, video_on_raw;
    assign hs_raw = ~((h_count >= H_DISPLAY + H_FRONT) && (h_count < H_DISPLAY + H_FRONT + H_SYNC));
    assign vs_raw = ~((v_count >= V_DISPLAY + V_FRONT) && (v_count < V_DISPLAY + V_FRONT + V_SYNC));
    assign video_on_raw = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

    //=========================================================================
    // 输出寄存器 (1周期延迟)
    //=========================================================================
    // 目的: 清除组合逻辑毛刺，并与BRAM数据对齐
    // BRAM读取延迟为1周期，所以数据在T+1时刻有效
    // 我们在这里将HS/VS也延迟1周期，使其与数据对齐
    
    reg hs_reg, vs_reg, video_on_reg;
    
    always @(posedge pixel_clk or negedge rst_n) begin
        if (!rst_n) begin
            hs_reg <= 1'b1;
            vs_reg <= 1'b1;
            video_on_reg <= 1'b0;
            vga_r <= 4'b0;
            vga_g <= 4'b0;
            vga_b <= 4'b0;
        end else begin
            hs_reg <= hs_raw;
            vs_reg <= vs_raw;
            video_on_reg <= video_on_raw;
            
            // 数据输出逻辑
            // 注意：selected_pixel_data 来自 BRAM (地址为 h_count)
            // 当我们在时钟上升沿采样 selected_pixel_data 时，实际上采样的是
            // 上一个周期地址对应的数据 (因为BRAM读延迟)
            // 这正好与我们延迟1周期的 HS/VS/VideoOn 对齐
            
            if (video_on_raw) begin
                vga_r <= selected_pixel_data[11:8];
                vga_g <= selected_pixel_data[7:4];
                vga_b <= selected_pixel_data[3:0];
            end else begin
                vga_r <= 4'b0;
                vga_g <= 4'b0;
                vga_b <= 4'b0;
            end
        end
    end
    
    assign vga_hs = hs_reg;
    assign vga_vs = vs_reg;
    
    // 输出给外部的 video_on 信号也需要延迟，以匹配 RGB 输出
    // 这样 vga_test_pattern 生成的图案才能与时序对齐
    assign video_on = video_on_reg; 

    // 输出当前像素坐标 (直接输出计数器，用于驱动BRAM地址)
    // BRAM地址不需要延迟，因为我们需要提前读取数据
    assign pixel_x = h_count;
    assign pixel_y = v_count;

    //=========================================================================
    // RGB输出寄存器 (已合并到上方 always 块)
    //=========================================================================

    // 根据模式选择像素数据源
    wire [11:0] selected_pixel_data;
    assign selected_pixel_data = use_framebuffer ? fb_pixel_data : pixel_data;

endmodule
