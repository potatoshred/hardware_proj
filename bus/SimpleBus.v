`timescale 1ns / 1ps

module SimpleBus(
    input [31:0] addr,
    input [31:0] write_data,
    input        mem_write,
    input        mem_read,
    
    // 连接到 Data RAM
    input  [31:0] ram_rdata,
    output [31:0] ram_addr,
    output [31:0] ram_wdata,
    output        ram_we,
    
    // 连接到外设 (例如 seg)
    output [31:0] peripheral_wdata,
    output        peripheral_we,

    // 连接到LED
    output        led_we,
    output [7:0] led_wdata,

    // VGA pattern
    output        vga_sel_we,
    output [2:0] vga_sel_wdata,
    
    // 总线返回给 CPU 的数据
    output reg [31:0] read_data
);

    // 1. 地址译码逻辑
    wire is_ram = (addr >= 32'h0000 && addr <= 32'h0FFF); // 假设 RAM 空间
    wire is_seg = (addr == 32'h1000);                     // 假设 seg 映射在 0x1000
    wire is_led = (addr == 32'h1004);                     // 假设 LED 映射在 0x1004
    wire is_vga = (addr == 32'h1008);                     // 假设 VGA 映射在 0x1008

    // 2. 分发写信号
    assign ram_addr  = addr;
    assign ram_wdata = write_data;
    assign ram_we    = is_ram && mem_write;
    // seg
    assign peripheral_wdata = write_data;
    assign peripheral_we    = is_seg && mem_write;
    // LED
    assign led_wdata = write_data[7:0];
    assign led_we    = is_led && mem_write;
    // VGA
    assign vga_sel_we = is_vga && mem_write;
    assign vga_sel_wdata = write_data[2:0];

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
        else
            read_data = 32'h0;
    end

endmodule