`timescale 1ns / 1ps

module SimpleBus(
    input [31:0] addr,
    input [31:0] write_data,
    input [3:0]  mem_write_mask, // Changed from mem_write (1 bit)
    input        mem_read,
    
    // 连接到 Data RAM
    input  [31:0] ram_rdata,
    output [31:0] ram_addr,
    output [31:0] ram_wdata,
    output [3:0]  ram_we, // Changed from ram_we (1 bit)
    
    // 连接到外设 (例如 seg)
    output [31:0] peripheral_wdata,
    output        peripheral_we,

    // 连接到LED
    output        led_we,
    output [7:0] led_wdata,

    // VGA pattern
    output        vga_sel_we,
    output [2:0] vga_sel_wdata,

    // Frame Buffer
    output        fb_we,
    output [31:0] fb_addr,
    output [31:0] fb_wdata,

    // UART
    output        uart_we,
    output        uart_re,
    output [31:0] uart_addr,
    output [31:0] uart_wdata,
    input  [31:0] uart_rdata,

    // 总线返回给 CPU 的数据
    output reg [31:0] read_data
);

    // 1. 地址译码逻辑
    wire is_ram = (addr >= 32'h0000 && addr <= 32'hFFFF); // RAM 空间 (64KB)
    wire is_seg = (addr == 32'h10000);                    // seg 映射在 0x10000
    wire is_led = (addr == 32'h10004);                    // LED 映射在 0x10004
    wire is_vga = (addr == 32'h10008);                    // VGA 映射在 0x10008
    wire is_uart = (addr >= 32'h10010 && addr <= 32'h1001F); // UART 映射在 0x10010
    // Frame Buffer: 0x8000_0000 - 0x8012_BFFF (1.2MB, 640*480*4 bytes)
    // 640 * 480 * 4 = 1,228,800 = 0x12C000 bytes
    wire is_fb  = (addr >= 32'h80000000 && addr < 32'h8012C000);

    // 2. 分发写信号
    assign ram_addr  = addr;
    assign ram_wdata = write_data;
    assign ram_we    = is_ram ? mem_write_mask : 4'b0000;
    
    // Generate single bit write enable for peripherals
    wire write_enable = |mem_write_mask;

    // seg
    assign peripheral_wdata = write_data;
    assign peripheral_we    = is_seg && write_enable;
    // LED
    assign led_wdata = write_data[7:0];
    assign led_we    = is_led && write_enable;
    // VGA
    assign vga_sel_we = is_vga && write_enable;
    assign vga_sel_wdata = write_data[2:0];
    // UART
    assign uart_we    = is_uart && write_enable;
    assign uart_re    = is_uart && mem_read;
    assign uart_addr  = addr; // Pass full address, UART_IO will decode offset
    assign uart_wdata = write_data;

    // Frame Buffer
    assign fb_we    = is_fb && write_enable;
    assign fb_addr  = addr;
    assign fb_wdata = write_data;

    // 3. 收集读信号 (通过多路复用器)
    always @(*) begin
        if (is_ram)
            read_data = ram_rdata;
        else if (is_seg)
            read_data = 32'h0; // seg 只写不读
        else if (is_led)
            read_data = 32'h0; // LED 只写不读
        else if (is_vga)
            read_data = 32'h0; // VGA 选择寄存器只写不读
        else if (is_uart)
            read_data = uart_rdata;
        else if (is_fb)
            read_data = 32'h0; // Frame Buffer 只写不读 (可扩展支持读)
        else
            read_data = 32'h0;
    end

endmodule