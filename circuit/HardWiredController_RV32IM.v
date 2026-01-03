/******************************************************************************
 ** RV32IM Hard-Wired Controller (Optimized Design)
 **
 ** This controller uses a modular, table-based approach for easy extension
 ** Supports full RV32I base instruction set + M extension (Multiply/Divide)
 **
 ** Author: Optimized for RV32IM
 ** Date: 2025-12-31
 ******************************************************************************/

`timescale 1ns/1ps

// Include shared definitions
`include "RV32IM_Defines.vh"

module HardWiredController_RV32IM(
    // Inputs
    input  wire [6:0]  IR_full,      // funct7: IR[31:25]
    input  wire [2:0]  Funct3,       // IR[14:12]
    input  wire        IR30,         // IR[30] for funct7 disambiguation
    input  wire        IR25,         // IR[25] for M extension
    input  wire [4:0]  Rs2_addr,     // IR[24:20] for ECALL/EBREAK/URET distinction
    input  wire [4:0]  Opcode,       // IR[6:2]

    // Outputs - Control Signals
    output wire [4:0]  ALU_OP,       // ALU operation select
    output wire        ALU_SRC,      // ALU source: 0=R2, 1=Imm
    output wire        MemToReg,     // Write memory data to register
    output wire        MemWrite,     // Memory write enable
    output wire        RegWrite,     // Register write enable
    output wire        Branch,       // Branch instruction
    output wire        JAL,          // JAL instruction
    output wire        JALR,         // JALR instruction
    output wire        LUI,          // LUI instruction
    output wire        AUIPC,        // AUIPC instruction

    // Branch condition outputs
    output wire        Beq,          // Branch equal
    output wire        Bne,          // Branch not equal
    output wire        Blt,          // Branch less than
    output wire        Bge,          // Branch greater or equal
    output wire        Bltu,         // Branch less than unsigned
    output wire        Bgeu,         // Branch greater or equal unsigned

    // Load/Store type outputs
    output wire        Lbu,          // Load byte unsigned
    output wire        Lhu,          // Load halfword unsigned
    output wire        Lb,           // Load byte
    output wire        Lh,           // Load halfword
    output wire        Lw,           // Load word
    output wire        Sb,           // Store byte
    output wire        Sh,           // Store halfword
    output wire        Sw,           // Store word

    // System & CSR
    output wire        CSRRSI,       // CSR read and set immediate
    output wire        CSRRCI,       // CSR read and clear immediate
    output wire        CSRRW,        // CSR read and write
    output wire        CSRRS,        // CSR read and set
    output wire        CSRRC,        // CSR read and clear
    output wire        ecall,        // ECALL instruction
    output wire        ebreak,       // EBREAK instruction
    output wire        uret,         // URET instruction

    // Register usage flags
    output wire        RsUsed,       // Rs is used
    output wire        RtUsed,       // Rt is used

    // Immediate type
    output wire        S_type,       // S-type immediate
    output wire        B_type,       // B-type immediate
    output wire        U_type,       // U-type immediate
    output wire        J_type,       // J-type immediate

    // M extension flags
    output wire        Is_M_Ext,     // M extension instruction
    output wire        Mul_Op,       // Multiply operation
    output wire        Div_Op        // Divide operation
);

    // ========================================================================
    // Instruction Type Decode
    // ========================================================================
    wire is_lui     = (Opcode == `OPCODE_LUI);
    wire is_auipc   = (Opcode == `OPCODE_AUIPC);
    wire is_jal     = (Opcode == `OPCODE_JAL);
    wire is_jalr    = (Opcode == `OPCODE_JALR);
    wire is_branch  = (Opcode == `OPCODE_BRANCH);
    wire is_load    = (Opcode == `OPCODE_LOAD);
    wire is_store   = (Opcode == `OPCODE_STORE);
    wire is_op_imm  = (Opcode == `OPCODE_OP_IMM);
    wire is_op      = (Opcode == `OPCODE_OP);
    wire is_system  = (Opcode == `OPCODE_SYSTEM);

    // M extension detection (funct7[0] = 1 for M extension in OP instructions)
    wire is_m_ext   = is_op & IR25 & (~IR30);

    // ========================================================================
    // Branch Type Decode
    // ========================================================================
    assign Beq  = is_branch & (Funct3 == `FUNCT3_BEQ);
    assign Bne  = is_branch & (Funct3 == `FUNCT3_BNE);
    assign Blt  = is_branch & (Funct3 == `FUNCT3_BLT);
    assign Bge  = is_branch & (Funct3 == `FUNCT3_BGE);
    assign Bltu = is_branch & (Funct3 == `FUNCT3_BLTU);
    assign Bgeu = is_branch & (Funct3 == `FUNCT3_BGEU);
    assign Branch = is_branch;

    // ========================================================================
    // Load Type Decode
    // ========================================================================
    assign Lb   = is_load & (Funct3 == `FUNCT3_LB);
    assign Lh   = is_load & (Funct3 == `FUNCT3_LH);
    assign Lw   = is_load & (Funct3 == `FUNCT3_LW);
    assign Lbu  = is_load & (Funct3 == `FUNCT3_LBU);
    assign Lhu  = is_load & (Funct3 == `FUNCT3_LHU);

    // ========================================================================
    // Store Type Decode
    // ========================================================================
    assign Sb   = is_store & (Funct3 == `FUNCT3_SB);
    assign Sh   = is_store & (Funct3 == `FUNCT3_SH);
    assign Sw   = is_store & (Funct3 == `FUNCT3_SW);
    assign S_type = is_store;

    // ========================================================================
    // Jump Instructions
    // ========================================================================
    assign JAL  = is_jal;
    assign JALR = is_jalr;

    // ========================================================================
    // Upper Immediate Instructions
    // ========================================================================
    assign LUI   = is_lui;
    assign AUIPC = is_auipc;
    assign U_type = is_lui | is_auipc;
    assign J_type = is_jal;
    assign B_type = is_branch;

    // ========================================================================
    // System Instructions Decode
    // ========================================================================
    // ECALL/EBREAK/URET are distinguished by IR[24:20] (Rs2_addr) and IR[31:25] (IR_full)
    // ECALL:  funct7=0000000, rs2=00000 -> imm[11:0] = 000000000000
    // EBREAK: funct7=0000000, rs2=00001 -> imm[11:0] = 000000000001
    // URET:   funct7=0000000, rs2=00010 -> imm[11:0] = 000000000010
    wire is_priv = is_system & (Funct3 == `FUNCT3_PRIV);

    assign ecall   = is_priv & (IR_full == 7'b0000000) & (Rs2_addr == 5'b00000);
    assign ebreak  = is_priv & (IR_full == 7'b0000000) & (Rs2_addr == 5'b00001);
    assign uret    = is_priv & (IR_full == 7'b0000000) & (Rs2_addr == 5'b00010);

    assign CSRRW   = is_system & (Funct3 == `FUNCT3_CSRRW);
    assign CSRRS   = is_system & (Funct3 == `FUNCT3_CSRRS);
    assign CSRRC   = is_system & (Funct3 == `FUNCT3_CSRRC);
    assign CSRRSI  = is_system & (Funct3 == `FUNCT3_CSRRSI);
    assign CSRRCI  = is_system & (Funct3 == `FUNCT3_CSRRCI);

    // ========================================================================
    // M Extension Decode
    // ========================================================================
    assign Is_M_Ext = is_m_ext;

    wire is_mul     = is_m_ext & (Funct3 == `FUNCT3_MUL);
    wire is_mulh    = is_m_ext & (Funct3 == `FUNCT3_MULH);
    wire is_mulhsu  = is_m_ext & (Funct3 == `FUNCT3_MULHSU);
    wire is_mulhu   = is_m_ext & (Funct3 == `FUNCT3_MULHU);
    wire is_div     = is_m_ext & (Funct3 == `FUNCT3_DIV);
    wire is_divu    = is_m_ext & (Funct3 == `FUNCT3_DIVU);
    wire is_rem     = is_m_ext & (Funct3 == `FUNCT3_REM);
    wire is_remu    = is_m_ext & (Funct3 == `FUNCT3_REMU);

    assign Mul_Op = is_mul | is_mulh | is_mulhsu | is_mulhu;
    assign Div_Op = is_div | is_divu | is_rem | is_remu;

    // ========================================================================
    // ALU Operation Decode
    // ========================================================================
    reg [4:0] alu_op_internal;

    always @(*) begin
        // Default
        alu_op_internal = `ALU_ADD;

        // R-type and I-type ALU operations
        if (is_op | is_op_imm) begin
            case (Funct3)
                `FUNCT3_ADD_SUB: begin
                    // Check for M extension first
                    if (is_m_ext) begin
                        alu_op_internal = `ALU_MUL;  // MUL
                    end else if (is_op & IR30) begin
                        alu_op_internal = `ALU_SUB;  // SUB (only R-type)
                    end else begin
                        alu_op_internal = `ALU_ADD;  // ADD/ADDI
                    end
                end
                `FUNCT3_SLL: begin
                    if (is_m_ext) begin
                        alu_op_internal = `ALU_MULH;  // MULH
                    end else begin
                        alu_op_internal = `ALU_SLL;
                    end
                end
                `FUNCT3_SLT: begin
                    if (is_m_ext) begin
                        alu_op_internal = `ALU_MULHSU;  // MULHSU
                    end else begin
                        alu_op_internal = `ALU_SLT;
                    end
                end
                `FUNCT3_SLTU: begin
                    if (is_m_ext) begin
                        alu_op_internal = `ALU_MULHU;  // MULHU
                    end else begin
                        alu_op_internal = `ALU_SLTU;
                    end
                end
                `FUNCT3_XOR: begin
                    if (is_m_ext) begin
                        alu_op_internal = `ALU_DIV;  // DIV
                    end else begin
                        alu_op_internal = `ALU_XOR;
                    end
                end
                `FUNCT3_SRL_SRA: begin
                    if (is_m_ext) begin
                        alu_op_internal = `ALU_DIVU;  // DIVU (use unsigned divider)
                    end else if (IR30) begin
                        alu_op_internal = `ALU_SRA;
                    end else begin
                        alu_op_internal = `ALU_SRL;
                    end
                end
                `FUNCT3_OR: begin
                    if (is_m_ext) begin
                        alu_op_internal = `ALU_REM;  // REM
                    end else begin
                        alu_op_internal = `ALU_OR;
                    end
                end
                `FUNCT3_AND: begin
                    if (is_m_ext) begin
                        alu_op_internal = `ALU_REMU;  // REMU
                    end else begin
                        alu_op_internal = `ALU_AND;
                    end
                end
                default: alu_op_internal = `ALU_ADD;
            endcase
        end
        // Load/Store use ADD for address calculation
        else if (is_load | is_store) begin
            alu_op_internal = `ALU_ADD;
        end
        // Branch comparisons
        else if (is_branch) begin
            case (Funct3)
                `FUNCT3_BEQ, `FUNCT3_BNE:  alu_op_internal = `ALU_SUB;
                `FUNCT3_BLT, `FUNCT3_BGE:  alu_op_internal = `ALU_SLT;
                `FUNCT3_BLTU, `FUNCT3_BGEU: alu_op_internal = `ALU_SLTU;
                default: alu_op_internal = `ALU_SUB;
            endcase
        end
        // JALR uses ADD for address calculation
        else if (is_jalr) begin
            alu_op_internal = `ALU_ADD;
        end
        // AUIPC uses ADD
        else if (is_auipc) begin
            alu_op_internal = `ALU_ADD;
        end
        // Default
        else begin
            alu_op_internal = `ALU_ADD;
        end
    end

    assign ALU_OP = alu_op_internal;

    // ========================================================================
    // ALU Source Select
    // ========================================================================
    // Use immediate when: I-type ALU, Load, Store, JALR, AUIPC, LUI
    assign ALU_SRC = is_op_imm | is_load | is_store | is_jalr | is_auipc | is_lui;

    // ========================================================================
    // Memory Control Signals
    // ========================================================================
    assign MemWrite = is_store;
    assign MemToReg = is_load;

    // ========================================================================
    // Register Write Enable
    // ========================================================================
    // Write to register for: ALU ops, Load, JAL, JALR, LUI, AUIPC, CSR
    assign RegWrite = is_op | is_op_imm | is_load | is_jal | is_jalr |
                      is_lui | is_auipc |
                      (is_system & ~is_priv) | is_m_ext;

    // ========================================================================
    // Register Usage Flags
    // ========================================================================
    // Rs is used by most instructions except LUI, AUIPC, JAL, CSRxI
    assign RsUsed = ~(is_lui | is_auipc | is_jal |
                      is_system & (Funct3[2])); // CSRxI uses immediate

    // Rt (Rs2) is used by: R-type, Store, Branch
    assign RtUsed = is_op | is_store | is_branch | is_m_ext;

endmodule
