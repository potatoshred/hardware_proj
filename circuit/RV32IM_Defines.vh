/******************************************************************************
 ** RV32IM Instruction Set Definitions
 ** This file contains all opcode, funct3, and funct7 definitions
 ******************************************************************************/

`ifndef RV32IM_DEFINES_VH
`define RV32IM_DEFINES_VH

// ============================================================================
// Opcode Definitions (IR[6:2])
// ============================================================================
`define OPCODE_LUI      5'b01101
`define OPCODE_AUIPC    5'b00101
`define OPCODE_JAL      5'b11011
`define OPCODE_JALR     5'b11001
`define OPCODE_BRANCH   5'b11000
`define OPCODE_LOAD     5'b00000
`define OPCODE_STORE    5'b01000
`define OPCODE_OP_IMM   5'b00100
`define OPCODE_OP       5'b01100
`define OPCODE_SYSTEM   5'b11100

// ============================================================================
// Funct3 Definitions
// ============================================================================
// Branch instructions
`define FUNCT3_BEQ      3'b000
`define FUNCT3_BNE      3'b001
`define FUNCT3_BLT      3'b100
`define FUNCT3_BGE      3'b101
`define FUNCT3_BLTU     3'b110
`define FUNCT3_BGEU     3'b111

// Load instructions
`define FUNCT3_LB       3'b000
`define FUNCT3_LH       3'b001
`define FUNCT3_LW       3'b010
`define FUNCT3_LBU      3'b100
`define FUNCT3_LHU      3'b101

// Store instructions
`define FUNCT3_SB       3'b000
`define FUNCT3_SH       3'b001
`define FUNCT3_SW       3'b010

// ALU operations
`define FUNCT3_ADD_SUB  3'b000
`define FUNCT3_SLL      3'b001
`define FUNCT3_SLT      3'b010
`define FUNCT3_SLTU     3'b011
`define FUNCT3_XOR      3'b100
`define FUNCT3_SRL_SRA  3'b101
`define FUNCT3_OR       3'b110
`define FUNCT3_AND      3'b111

// M extension (RV32M)
`define FUNCT3_MUL      3'b000
`define FUNCT3_MULH     3'b001
`define FUNCT3_MULHSU   3'b010
`define FUNCT3_MULHU    3'b011
`define FUNCT3_DIV      3'b100
`define FUNCT3_DIVU     3'b101
`define FUNCT3_REM      3'b110
`define FUNCT3_REMU     3'b111

// System instructions
`define FUNCT3_PRIV     3'b000
`define FUNCT3_CSRRW    3'b001
`define FUNCT3_CSRRS    3'b010
`define FUNCT3_CSRRC    3'b011
`define FUNCT3_CSRRWI   3'b101
`define FUNCT3_CSRRSI   3'b110
`define FUNCT3_CSRRCI   3'b111

// ============================================================================
// Funct7 Definitions
// ============================================================================
`define FUNCT7_NORMAL   7'b0000000
`define FUNCT7_ALT      7'b0100000  // For SUB, SRA
`define FUNCT7_MULDIV   7'b0000001  // M extension

// ============================================================================
// ALU Operation Codes (5-bit) - Expanded for future use
// ============================================================================
`define ALU_SLL         5'b00000  // Shift left logical
`define ALU_SRA         5'b00001  // Shift right arithmetic
`define ALU_SRL         5'b00010  // Shift right logical
`define ALU_MUL         5'b00011  // Multiply (low 32 bits)
`define ALU_DIV         5'b00100  // Divide
`define ALU_ADD         5'b00101  // Add
`define ALU_SUB         5'b00110  // Subtract
`define ALU_AND         5'b00111  // Bitwise AND
`define ALU_OR          5'b01000  // Bitwise OR
`define ALU_XOR         5'b01001  // Bitwise XOR
`define ALU_DIVU        5'b01010  // Divide Unsigned
`define ALU_SLT         5'b01011  // Set less than (signed)
`define ALU_SLTU        5'b01100  // Set less than unsigned
`define ALU_MULH        5'b01101  // Multiply high signed
`define ALU_MULHU       5'b01110  // Multiply high unsigned
`define ALU_MULHSU      5'b01111  // Multiply high signed-unsigned

// Additional operations for REM (use DIV and get Result_2)
`define ALU_REM         5'b10000  // Remainder (signed)
`define ALU_REMU        5'b10001  // Remainder (unsigned)


`endif // RV32IM_DEFINES_VH
