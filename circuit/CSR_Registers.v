`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: CSR_Registers
// Description: Control and Status Registers for RISC-V privilege architecture
//
// Implements Machine-level CSRs:
// - mtvec   (0x305): Machine trap-handler base address
// - mepc    (0x341): Machine exception program counter
// - mcause  (0x342): Machine trap cause
// - mstatus (0x300): Machine status register
// - mscratch(0x340): Machine scratch register (optional)
//
// Version: 1.0
// Date: 2026-01-03
//////////////////////////////////////////////////////////////////////////////////

module CSR_Registers(
    input  wire        clk,
    input  wire        rst,

    // CSR Read/Write Interface
    input  wire        csr_we,           // CSR write enable
    input  wire [11:0] csr_addr,         // CSR address (12-bit)
    input  wire [31:0] csr_wdata,        // CSR write data
    output reg  [31:0] csr_rdata,        // CSR read data

    // Trap Interface
    input  wire        trap_entry,       // Trap entry signal (ECALL/exception)
    input  wire [31:0] trap_pc,          // PC to save in mepc
    input  wire [31:0] trap_cause,       // Trap cause code

    // Trap Return Interface
    input  wire        mret,             // Machine return instruction

    // Trap Vector Output
    output wire [31:0] mtvec_out,        // Trap handler address
    output wire [31:0] mepc_out          // Exception return address
);

    //=========================================================================
    // CSR Address Definitions
    //=========================================================================
    localparam CSR_MSTATUS  = 12'h300;
    localparam CSR_MTVEC    = 12'h305;
    localparam CSR_MSCRATCH = 12'h340;
    localparam CSR_MEPC     = 12'h341;
    localparam CSR_MCAUSE   = 12'h342;

    //=========================================================================
    // CSR Registers
    //=========================================================================
    reg [31:0] mstatus;   // Machine status
    reg [31:0] mtvec;     // Trap handler base address
    reg [31:0] mepc;      // Exception PC
    reg [31:0] mcause;    // Trap cause
    reg [31:0] mscratch;  // Scratch register

    //=========================================================================
    // mstatus bit definitions (simplified)
    //=========================================================================
    // bit 3: MIE  - Machine Interrupt Enable
    // bit 7: MPIE - Previous MIE

    //=========================================================================
    // Trap Entry Logic
    //=========================================================================
    always @(posedge clk) begin
        if (rst) begin
            mstatus  <= 32'h00000000;
            mtvec    <= 32'h00000000;  // Default trap handler at 0x0
            mepc     <= 32'h00000000;
            mcause   <= 32'h00000000;
            mscratch <= 32'h00000000;
        end
        else begin
            // Handle trap entry (ECALL, exceptions, interrupts)
            if (trap_entry) begin
                mepc   <= trap_pc;              // Save current PC
                mcause <= trap_cause;           // Save trap cause
                mstatus[7] <= mstatus[3];       // MPIE = MIE
                mstatus[3] <= 1'b0;             // MIE = 0 (disable interrupts)
            end

            // Handle mret (return from trap)
            else if (mret) begin
                mstatus[3] <= mstatus[7];       // MIE = MPIE
                mstatus[7] <= 1'b1;             // MPIE = 1
            end

            // CSR Write
            else if (csr_we) begin
                case (csr_addr)
                    CSR_MSTATUS:  mstatus  <= csr_wdata;
                    CSR_MTVEC:    mtvec    <= csr_wdata;
                    CSR_MEPC:     mepc     <= csr_wdata;
                    CSR_MCAUSE:   mcause   <= csr_wdata;
                    CSR_MSCRATCH: mscratch <= csr_wdata;
                    default: ;  // Ignore writes to undefined CSRs
                endcase
            end
        end
    end

    //=========================================================================
    // CSR Read Logic
    //=========================================================================
    always @(*) begin
        case (csr_addr)
            CSR_MSTATUS:  csr_rdata = mstatus;
            CSR_MTVEC:    csr_rdata = mtvec;
            CSR_MEPC:     csr_rdata = mepc;
            CSR_MCAUSE:   csr_rdata = mcause;
            CSR_MSCRATCH: csr_rdata = mscratch;
            default:      csr_rdata = 32'h00000000;
        endcase
    end

    //=========================================================================
    // Output Assignments
    //=========================================================================
    assign mtvec_out = mtvec;
    assign mepc_out  = mepc;

endmodule
