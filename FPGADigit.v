/******************************************************************************
 ** Logisim goes FPGA automatic generated Verilog code                       **
 **                                                                          **
 ** Component : FPGADigit                                                    **
 **                                                                          **
 ******************************************************************************/

`timescale 1ns/1ps
module FPGADigit( clkx,
                  GO,
                  RST,
                  EPC,
                  Ld, 
                  Done,
                  LED,
                  AN,
                  SEG,
                 CPU_RESETN,
                 SW,
                 VGA_R, 
                 VGA_G,
                 VGA_B,
                 VGA_HS,
                 VGA_VS,
                 UART_TXD_IN, // UART RX Pin
                 PS2_CLK,
                 PS2_DATA
                  );

   /***************************************************************************
    ** Here the inputs are defined                                           **
    ***************************************************************************/
   input clkx, GO, RST, EPC, Ld;
   input UART_TXD_IN;
   inout PS2_CLK;
   inout PS2_DATA;
                input  wire        CPU_RESETN;     // CPU复位按钮 (低电平有效)
                // 开关输入
                input  wire [2:0]  SW;             // 开关 (用于选择测试图案)
                // VGA输出
                output wire [3:0]  VGA_R;          // VGA红色信号
                output wire [3:0]  VGA_G;          // VGA绿色信号
                output wire [3:0]  VGA_B;          // VGA蓝色信号
                output wire        VGA_HS;         // VGA水平同步
                output wire        VGA_VS;         // VGA垂直同步
   /***************************************************************************
    ** Here the outputs are defined                                          **
    ***************************************************************************/
   output Done;
   output[7:0] AN;
   output[7:0] SEG;
   output[7:0] LED;


   /***************************************************************************
    ** Here the internal wires are defined                                   **
    ***************************************************************************/
   wire clkCPU, clkSEG;
   wire[3:0] data;
   wire[2:0] num;
   wire[31:0] dig;

//    initial begin
//        GO<=1;
//        RST<=0;
//    end


    // clkDivider #(10) DividerCPU(.clk(clkx), .clk_N(clkCPU));
    // clkDivider #(4) DividerSEG(.clk(clkx), .clk_N(clkVGA));
    
    wire mmcm_locked;
    clock_generator clk_gen_inst (
        .clk_in1(clkx),
        .clk_out1(clkVGA),
        .clk_out2(clkCPU),
        .reset(1'b0), // MMCM reset is active high
        .locked(mmcm_locked)
    );

    // 只有当 MMCM 锁定且 CPU_RESETN 未按下时，才释放 VGA 复位
    // 这样可以防止在时钟不稳定时 VGA 控制器输出异常信号
    wire vga_rst_n = CPU_RESETN & mmcm_locked;

    clkDivider #(250000) DividerDisplay(.clk(clkx), .clk_N(clkSEG));

    wire [2:0] vga_sel;
    wire [7:0] cpu_led;
    wire [31:0] pc_val;
    wire fb_we_cpu;
    wire [31:0] fb_addr_cpu;
    wire [31:0] fb_wdata_cpu;

    // UART Programmer Signals
    wire [31:0] prog_addr;
    wire [31:0] prog_data;
    wire prog_we;
    wire [7:0] prog_led;
    
    // Use Ld switch (SW[1]) as Program Mode Enable
    // When Ld is HIGH: CPU is Reset, Programmer is Active
    wire prog_mode = Ld;
    wire cpu_rst_combined = RST | prog_mode; // CPU held in reset during programming

    UART_Programmer programmer(
        .clk(clkx),
        .rst(~CPU_RESETN | ~prog_mode), // Reset programmer when button pressed OR NOT in program mode
        .uart_rx_pin(UART_TXD_IN),
        .ram_addr(prog_addr),
        .ram_wdata(prog_data),
        .ram_we(prog_we), // Only write if in program mode
        .debug_led(prog_led)
    );

    // Keyboard MMIO Register
    reg [31:0] kbd_reg;
    wire kbd_read_cpu;

    always @(posedge clkx) begin
        if (RST) begin
            kbd_reg <= 32'd0;
        end else begin
            if (uart_ascii_valid) begin
                kbd_reg <= {1'b1, 23'd0, uart_ascii_out}; // Set Valid bit (31) and Data
            end else if (kbd_read_cpu) begin
                kbd_reg[31] <= 1'b0; // Clear Valid bit on read
            end
        end
    end

    MonoCycleCPU monoCycle(
        .Clk(clkCPU),
        .GO(GO),
        .RST(cpu_rst_combined),
        .Done(Done),
        .DisplayDigit(dig),
        .LEDdata(cpu_led),
        .vga_sel(vga_sel),
        .fb_we(fb_we_cpu),
        .fb_addr(fb_addr_cpu),
        .fb_wdata(fb_wdata_cpu),
        .PC(pc_val),
        .kbd_data(kbd_reg),      // Connect Keyboard Register
        .kbd_read(kbd_read_cpu), // Connect Read Signal
        .prog_clk(clkx),
        .prog_we(prog_we & prog_mode),
        .prog_addr(prog_addr),
        .prog_data(prog_data)
    );


    // 连接CPU LED输出到物理LED
    // If in program mode, show debug LEDs (last received byte)
    assign LED[7:0] = prog_mode ? prog_led : cpu_led[7:0];

    // USB键盘模块实例化（用于串口输入显示ASCII码）
    wire [7:0] uart_ascii_out;
    wire       uart_ascii_valid;
    
    ps2_keyboard uart_kbd_inst(
        .clk(clkx),                    // 100MHz时钟
        .rst(RST),
        .ps2_clk(PS2_CLK),             // 连接到PS/2键盘时钟
        .ps2_data(PS2_DATA),           // 连接到PS/2键盘数据
        .ascii_out(uart_ascii_out),    // ASCII码输出到CPU
        .ascii_valid(uart_ascii_valid) // ASCII码有效标志
    );

    // Latch last ASCII code for display
    reg [7:0] last_ascii;
    always @(posedge clkx) begin
        if (RST) last_ascii <= 8'h00;
        else if (uart_ascii_valid) last_ascii <= uart_ascii_out;
    end

    sevenseg_display_top u_sevenseg_display_top(
        .clk(clkSEG),
        .rst(RST),
        .data_in(SW[0] ? {24'h0, last_ascii} : (EPC ? {2'b0, pc_val[31:2]} : dig)),
        .seg_patt(SEG),
        .seg_sel(AN)
    );
    vga_top u_vga_top (
        .CLK100MHZ  (clkx),
        .CLKCPU     (clkCPU),
        .CLKVGA     (clkVGA), // Use system clock for VGA clock input
        .CPU_RESETN (vga_rst_n), // 使用经过 MMCM 锁定信号门控的复位信号
        .SW         (vga_sel),
        .fb_we      (fb_we_cpu),
        .fb_addr    (fb_addr_cpu),
        .fb_wdata   (fb_wdata_cpu),
        .VGA_R      (VGA_R),
        .VGA_G      (VGA_G),
        .VGA_B      (VGA_B),
        .VGA_HS     (VGA_HS),
        .VGA_VS     (VGA_VS),
        .LED        () // Disconnect LED output to avoid multiple drivers
    );

endmodule
