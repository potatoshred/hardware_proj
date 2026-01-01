/**
 * VGA Frame Buffer 模块
 * 分辨率: 640x480
 * 色深: 12位 (R4G4B4)
 * 总存储: 307,200 像素 × 12bit = 3,686,400 bits ≈ 450KB
 *
 * 使用双端口BRAM实现:
 * - Port A: CPU写入端口 (32位宽，按字访问)
 * - Port B: VGA读取端口 (12位宽，按像素访问)
 */

`timescale 1ns / 1ps

module vga_framebuffer #(
    parameter H_DISPLAY = 640,
    parameter V_DISPLAY = 480,
    parameter COLOR_BITS = 12
)(
    // Port A: CPU写端口 (32位宽)
    input  wire         clk_cpu,        // CPU时钟
    input  wire         we_cpu,         // 写使能
    input  wire [31:0]  addr_cpu,       // CPU地址 (字节地址)
    input  wire [31:0]  wdata_cpu,      // 写数据 (32位)

    // Port B: VGA读端口 (12位宽)
    input  wire         clk_vga,        // VGA像素时钟 (25MHz)
    input  wire [9:0]   pixel_x,        // 像素X坐标 (0-639)
    input  wire [9:0]   pixel_y,        // 像素Y坐标 (0-479)
    output wire [11:0]  pixel_data      // 像素数据输出
);

    //=========================================================================
    // 地址计算
    //=========================================================================

    // VGA端地址: pixel_addr = y * 640 + x
    // 使用移位优化: y * 640 = (y << 9) + (y << 7) = y * 512 + y * 128
    wire [18:0] pixel_addr;
    wire [18:0] y_512 = {pixel_y, 9'b0};      // y * 512
    wire [18:0] y_128 = {pixel_y, 7'b0};      // y * 128
    assign pixel_addr = y_512 + y_128 + pixel_x;

    // CPU端地址转换 (字节地址 -> 像素地址)
    // CPU地址范围: 0x80000000 - 0x8012BFFF
    // 步骤1: 减去基地址 0x80000000，得到偏移量
    // 步骤2: 除以4 (右移2位)，得到像素索引
    wire [31:0] cpu_offset = addr_cpu - 32'h80000000;  // 计算偏移量
    wire [18:0] cpu_pixel_addr = cpu_offset[20:2];     // 转换为像素地址

    //=====================================================================
    // 使用 Vivado BRAM IP 核
    //=====================================================================

    blk_mem_gen_framebuffer bram_inst (
        // Port A: CPU写端口
        .clka   (clk_cpu),
        .wea    (we_cpu),
        .addra  (cpu_pixel_addr),
        .dina   (wdata_cpu[11:0]),
        .douta  (),  // 不使用读端口

        // Port B: VGA读端口
        .clkb   (clk_vga),
        .web    (1'b0),  // 只读
        .addrb  (pixel_addr),
        .dinb   (12'b0),
        .doutb  (pixel_data)
    );


endmodule


//=============================================================================
//
// 如果 BRAM 资源不足
//
// 方案 A: 降低分辨率到 320x240
//    - 修改参数: H_DISPLAY=320, V_DISPLAY=240
//    - 存储需求: 76,800 像素 × 12bit = 112.5KB
//    - BRAM使用: 约26个blocks (19%)
//    - 显示时使用像素复制放大到640x480
//
// 方案 B: 降低色深到 8位 (R3G3B2)
//    - 修改 COLOR_BITS = 8
//    - 存储需求: 307,200 × 8bit = 300KB
//    - BRAM使用: 约68个blocks (50%)
//
// 方案 C: 结合降低分辨率和色深 (320x240 @ 8bit)
//    - 存储需求: 76,800 × 8bit = 75KB
//    - BRAM使用: 约17个blocks (12.6%)
//
//=============================================================================
