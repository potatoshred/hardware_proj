`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: MonoCycleCPU (RV32IM Edition)
// Description: Single-cycle RISC-V CPU with full RV32IM support
//
// Enhancements:
// - Full RV32I base instruction set (40 instructions)
// - RV32M extension support (8 multiply/divide instructions)
// - Extended branch support (BEQ, BNE, BLT, BGE, BLTU, BGEU)
// - LUI and AUIPC instructions
// - Extended load/store support (LB, LH, LW, LBU, LHU, SB, SH, SW)
// - Optimized data path for all instruction types
//
// Version: 2.0 - RV32IM
// Date: 2025-12-31
//////////////////////////////////////////////////////////////////////////////////

module MonoCycleCPU(
    input  wire        Clk,
    input  wire        GO,
    input  wire        RST,
    output wire        Done,
    output wire [7:0]  LEDdata,
    output wire [31:0] DisplayDigit,
    output wire [2:0]  vga_sel,
    output wire        fb_we,
    output wire [31:0] fb_addr,
    output wire [31:0] fb_wdata,
    output wire [31:0] PC,
    
    // Keyboard Input
    input wire [31:0] kbd_data,
    output wire       kbd_read,

    // Programming Interface
    input wire prog_clk,
    input wire prog_we,
    input wire [31:0] prog_addr,
    input wire [31:0] prog_data
);

    /******************************************************************************
    ** PC 相关信号
    ******************************************************************************/
    wire        halt;
    wire [31:0] PCcur, PCnxt, PC4;
    wire [31:0] PC_B, PC_Jal, PC_Jalr;

    /******************************************************************************
    ** PC 寄存器
    ******************************************************************************/
    REGISTER_FLIP_FLOP PC_Reg(
        .clk(Clk),
        .rst(RST),
        .e(~halt),
        .d(PCnxt),
        .q(PCcur)
    );
    assign PC4 = PCcur + 4;
    assign PC = PCcur;

    /******************************************************************************
    ** 指令存储器
    ******************************************************************************/
    wire [31:0] IR;
    ROM_instrROM instrROM(
        .Address(PCcur[13:2]),
        .Data(IR),
        .clk(prog_clk),
        .we(prog_we),
        .waddr(prog_addr[13:2]),
        .wdata(prog_data)
    );

    /******************************************************************************
    ** 指令字段解析
    ******************************************************************************/
    wire [6:0] opcode_full = IR[6:0];
    wire [4:0] opcode      = IR[6:2];
    wire [2:0] funct3      = IR[14:12];
    wire [6:0] funct7      = IR[31:25];
    wire       IR30        = IR[30];
    wire       IR25        = IR[25];
    wire       IR21        = IR[21];
    wire [4:0] rs1_addr    = IR[19:15];
    wire [4:0] rs2_addr    = IR[24:20];
    wire [4:0] rd_addr     = IR[11:7];

    /******************************************************************************
    ** 立即数生成
    ******************************************************************************/
    wire [31:0] immI, immS, immB, immJ, immU;

    // 原始立即数组合
    wire [11:0] immI_raw = IR[31:20];
    wire [11:0] immS_raw = {IR[31:25], IR[11:7]};
    wire [12:0] immB_raw = {IR[31], IR[7], IR[30:25], IR[11:8], 1'b0};
    wire [20:0] immJ_raw = {IR[31], IR[19:12], IR[20], IR[30:21], 1'b0};
    wire [19:0] immU_raw = IR[31:12];

    // 符号扩展
    Bit_Extender #(12, 32, 1) ext_immI (.imm_in(immI_raw), .imm_out(immI));
    Bit_Extender #(12, 32, 1) ext_immS (.imm_in(immS_raw), .imm_out(immS));
    Bit_Extender #(13, 32, 1) ext_immB (.imm_in(immB_raw), .imm_out(immB));
    Bit_Extender #(21, 32, 1) ext_immJ (.imm_in(immJ_raw), .imm_out(immJ));
    // Bit_Extender #(20, 32, 0) ext_immU (.imm_in(immU_raw), .imm_out(immU));  // 零扩展
    assign immU = {immU_raw, 12'b0}; // LUI/AUIPC 需要左移 12 位

    // 分支/跳转目标地址
    assign PC_B   = PCcur + immB;
    assign PC_Jal = PCcur + immJ;

    /******************************************************************************
    ** 硬布线控制器 (RV32IM 完整版)
    ******************************************************************************/
    wire [4:0]  ALU_OP;
    wire        ALU_SRC;
    wire        MemToReg, MemWrite, RegWrite;
    wire        Branch;
    wire        Beq, Bne, Blt, Bge, Bltu, Bgeu;
    wire        JAL, JALR;
    wire        LUI, AUIPC;
    wire        Lb, Lh, Lw, Lbu, Lhu;
    wire        Sb, Sh, Sw;
    wire        S_type, B_type, U_type, J_type;
    wire        CSRRSI, CSRRCI, CSRRW, CSRRS, CSRRC;
    wire        ecall, ebreak, uret;
    wire        RsUsed, RtUsed;
    wire        Is_M_Ext, Mul_Op, Div_Op;

    HardWiredController_RV32IM controller(
        .IR_full(funct7),
        .Funct3(funct3),
        .IR30(IR30),
        .IR25(IR25),
        .Rs2_addr(rs2_addr),     // 用于区分 ECALL/EBREAK/URET
        .Opcode(opcode),
        // Control signals
        .ALU_OP(ALU_OP),
        .ALU_SRC(ALU_SRC),
        .MemToReg(MemToReg),
        .MemWrite(MemWrite),
        .RegWrite(RegWrite),
        .Branch(Branch),
        .JAL(JAL),
        .JALR(JALR),
        .LUI(LUI),
        .AUIPC(AUIPC),
        // Branch types
        .Beq(Beq),
        .Bne(Bne),
        .Blt(Blt),
        .Bge(Bge),
        .Bltu(Bltu),
        .Bgeu(Bgeu),
        // Load types
        .Lbu(Lbu),
        .Lhu(Lhu),
        .Lb(Lb),
        .Lh(Lh),
        .Lw(Lw),
        // Store types
        .Sb(Sb),
        .Sh(Sh),
        .Sw(Sw),
        // System instructions
        .CSRRSI(CSRRSI),
        .CSRRCI(CSRRCI),
        .CSRRW(CSRRW),
        .CSRRS(CSRRS),
        .CSRRC(CSRRC),
        .ecall(ecall),
        .ebreak(ebreak),
        .uret(uret),
        // Register usage
        .RsUsed(RsUsed),
        .RtUsed(RtUsed),
        // Immediate types
        .S_type(S_type),
        .B_type(B_type),
        .U_type(U_type),
        .J_type(J_type),
        // M extension
        .Is_M_Ext(Is_M_Ext),
        .Mul_Op(Mul_Op),
        .Div_Op(Div_Op)
    );

    /******************************************************************************
    ** 寄存器文件
    ******************************************************************************/
    wire [4:0]  R1N, R2N;
    wire [31:0] R1, R2, RDin;

    // ECALL 时使用 a0(x10) 和 a7(x17)
    assign R1N = ecall ? 5'd10 : rs1_addr;
    assign R2N = ecall ? 5'd17 : rs2_addr;

    Regifile regfile(
        .Clk(Clk),
        .Din(RDin),
        .R1N(R1N),
        .R2N(R2N),
        .RdN(rd_addr),
        .WE(RegWrite),
        .R1(R1),
        .R2(R2)
    );

    /******************************************************************************
    ** ALU 输入选择
    ******************************************************************************/
    wire [31:0] ALUx, ALUy, ALU_imm;

    // ALU 第一操作数：LUI 使用 0，AUIPC 使用 PC
    assign ALUx = LUI    ? 32'b0 :
                  AUIPC  ? PCcur :
                           R1;

    // ALU 立即数选择
    assign ALU_imm = S_type ? immS :
                     U_type ? immU :
                              immI;

    // ALU 第二操作数
    assign ALUy = ALU_SRC ? ALU_imm : R2;

    /******************************************************************************
    ** ALU (RV32IM Enhanced)
    ******************************************************************************/
    wire        Less, Equal, GE;
    wire        LessU;  // 无符号比较
    wire [31:0] ALUret, ALUret2;

    ALU_RV32IM alu(
        .AluOP(ALU_OP),
        .X(ALUx),
        .Y(ALUy),
        .Less(Less),
        .Equal(Equal),
        .Result(ALUret),
        .Result_2(ALUret2),
        .GE(GE)
    );

    // 从 ALU 提取无符号比较结果（通过 SLTU 操作）
    assign LessU = Less;  // ALU 内部已处理

    /******************************************************************************
    ** 分支判断逻辑 (扩展支持所有 6 种分支)
    ******************************************************************************/
    wire branch_taken;
    assign branch_taken = (Beq  & Equal) |
                         (Bne  & (~Equal)) |
                         (Blt  & Less) |
                         (Bge  & GE) |
                         (Bltu & Less) |   // 使用 ALU 的 SLTU 结果
                         (Bgeu & (~Less)); // 无符号 >=

    wire Btype = Branch & branch_taken;
    wire Jtype = JAL | JALR;

    // JALR 目标地址（最低位清零）
    assign PC_Jalr = ALUret & 32'hfffffffe;

    /******************************************************************************
    ** 存储器和总线
    ******************************************************************************/
    wire [31:0] Bus_ReadData;
    wire [31:0] RAM_Out;
    wire [31:0] ram_addr_bus, ram_wdata_bus;
    wire [3:0]  ram_we_bus; // Changed to 4 bits
    wire [31:0] seg_wdata_bus;
    wire        seg_we_bus;
    wire [7:0]  led_wdata_bus;
    wire        led_we_bus;
    wire [2:0]  vga_sel_wdata_bus;
    wire        vga_sel_we_bus;
    wire        fb_we_bus;
    wire [31:0] fb_addr_bus;
    wire [31:0] fb_wdata_bus;

    // Generate Write Data and Mask for SB/SH/SW
    reg [31:0] aligned_write_data;
    reg [3:0]  write_mask;
    
    always @(*) begin
        aligned_write_data = R2;
        write_mask = 4'b0000;
        
        if (MemWrite) begin
            if (Sb) begin
                aligned_write_data = R2 << (ALUret[1:0] * 8);
                write_mask = 4'b0001 << ALUret[1:0];
            end else if (Sh) begin
                aligned_write_data = R2 << (ALUret[1] * 16);
                write_mask = 4'b0011 << (ALUret[1] * 2);
            end else if (Sw) begin
                aligned_write_data = R2;
                write_mask = 4'b1111;
            end
        end
    end

    SimpleBus bus_inst (
        .addr(ALUret),
        .write_data(aligned_write_data), // Use aligned data
        .mem_write_mask(write_mask),     // Use mask
        .mem_read(MemToReg),
        .ram_addr(ram_addr_bus),
        .ram_wdata(ram_wdata_bus),
        .ram_we(ram_we_bus),
        .ram_rdata(RAM_Out),
        .kbd_rdata(kbd_data),            // Keyboard input
        .peripheral_wdata(seg_wdata_bus),
        .peripheral_we(seg_we_bus),
        .led_we(led_we_bus),
        .led_wdata(led_wdata_bus),
        .vga_sel_we(vga_sel_we_bus),
        .vga_sel_wdata(vga_sel_wdata_bus),
        .fb_we(fb_we_bus),
        .fb_addr(fb_addr_bus),
        .fb_wdata(fb_wdata_bus),
        .read_data(Bus_ReadData)
    );

    // Generate Keyboard Read Signal
    // Address 0x1000C is for Keyboard
    assign kbd_read = MemToReg && (ALUret == 32'h1000C);

    RAM_dataRAM dataRam(
        .addr(ram_addr_bus[13:2]),
        .clk(Clk),
        .d(ram_wdata_bus),
        .we(ram_we_bus), // 4 bits
        .ld(MemToReg),
        .clr(RST),
        .q(RAM_Out),
        // Programming Port
        .prog_clk(prog_clk),
        .prog_we(prog_we),
        .prog_addr(prog_addr[13:2]),
        .prog_data(prog_data)
    );

    /******************************************************************************
    ** Load 数据处理 (支持 LB, LH, LW, LBU, LHU)
    ******************************************************************************/
    wire [31:0] load_data;
    wire [7:0]  load_byte;
    wire [15:0] load_half;

    // 字节选择
    assign load_byte = (ALUret[1:0] == 2'b00) ? Bus_ReadData[7:0] :
                      (ALUret[1:0] == 2'b01) ? Bus_ReadData[15:8] :
                      (ALUret[1:0] == 2'b10) ? Bus_ReadData[23:16] :
                                                Bus_ReadData[31:24];

    // 半字选择
    assign load_half = (ALUret[1] == 1'b0) ? Bus_ReadData[15:0] :
                                              Bus_ReadData[31:16];

    // Load 数据扩展
    assign load_data = Lbu ? {24'b0, load_byte} :                    // LBU: 零扩展字节
                       Lb  ? {{24{load_byte[7]}}, load_byte} :       // LB:  符号扩展字节
                       Lhu ? {16'b0, load_half} :                    // LHU: 零扩展半字
                       Lh  ? {{16{load_half[15]}}, load_half} :      // LH:  符号扩展半字
                             Bus_ReadData;                           // LW:  字

    /******************************************************************************
    ** 寄存器写回数据选择
    ******************************************************************************/
    wire [31:0] alu_or_mem;
    wire [31:0] alu_result_final;

    // ALU 结果直接使用 Result，不再需要从 Result_2 选择余数
    // MULH 系列指令的 Result 已经是高位结果
    assign alu_result_final = ALUret;

    // 选择 ALU 结果或内存数据
    assign alu_or_mem = MemToReg ? load_data : alu_result_final;

    // 最终写回数据：JAL/JALR 写入 PC+4
    assign RDin = Jtype ? PC4 : alu_or_mem;

    /******************************************************************************
    ** PC 下一值选择
    ******************************************************************************/
    wire       valid;
    wire [1:0] PCsel;

    Priority_Encoder priorityEncoder(
        .in({JALR, JAL, Btype, 1'b1}),
        .out(PCsel),
        .valid(valid)
    );

    Multiplexer_4 #(.NrOfBits(32)) MultiplexerPC(
        .Enable(1'b1),
        .MuxIn_0(PC4),
        .MuxIn_1(PC_B),
        .MuxIn_2(PC_Jal),
        .MuxIn_3(PC_Jalr),
        .Sel(PCsel),
        .MuxOut(PCnxt)
    );

    /******************************************************************************
    ** HALT 控制
    ******************************************************************************/
    assign halt = GO ? 1'b0 : (ecall & (R2 == 32'd10));
    assign Done = ~halt;

    /******************************************************************************
    ** MMIO 外设
    ******************************************************************************/
    // 7 段数码管
    wire       SEGupdate = ecall & (R2 == 32'd34);
    wire [31:0] DisplayDigit_in = SEGupdate ? R1 : seg_wdata_bus;

    REGISTER_FLIP_FLOP #(.WIDTH(32)) DisplayDigitReg (
        .clk(Clk),
        .rst(RST),
        .e(SEGupdate | seg_we_bus),
        .d(DisplayDigit_in),
        .q(DisplayDigit)
    );

    // LED
    REGISTER_FLIP_FLOP #(.WIDTH(8)) LEDReg (
        .clk(Clk),
        .rst(RST),
        .e(led_we_bus),
        .d(led_wdata_bus),
        .q(LEDdata)
    );

    // VGA 模式选择
    REGISTER_FLIP_FLOP #(.WIDTH(3)) VGASelReg (
        .clk(Clk),
        .rst(RST),
        .e(vga_sel_we_bus),
        .d(vga_sel_wdata_bus),
        .q(vga_sel)
    );

    /******************************************************************************
    ** Frame Buffer 直通输出
    ******************************************************************************/
    assign fb_we = fb_we_bus;
    assign fb_addr = fb_addr_bus;
    assign fb_wdata = fb_wdata_bus;

endmodule
