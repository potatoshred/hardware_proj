`timescale 1ns / 1ps

module UART_Controller #(
    parameter CLK_FREQ = 100000000,
    parameter BAUD_RATE = 115200
) (
    input wire clk,
    input wire rst,
    // Bus interface
    input wire [31:0] addr, // Only need low bits really, but taking full for simplicity
    input wire [31:0] wdata,
    input wire we,
    input wire re,
    output reg [31:0] rdata,
    // UART pins
    input wire rx_pin,
    output wire tx_pin
);

    // Register Offsets
    localparam REG_DATA = 0; // 0x00
    localparam REG_STATUS = 4; // 0x04

    // UART RX Signals
    wire [7:0] rx_data;
    wire rx_valid_pulse;
    reg [7:0] rx_buffer;
    reg rx_data_available;

    // UART TX Signals
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_busy;
    wire tx_pin_wire;

    assign tx_pin = tx_pin_wire;

    // Instantiate UART RX
    UART_RX #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_rx_inst (
        .clk(clk),
        .rst(rst),
        .rx(rx_pin),
        .data(rx_data),
        .valid(rx_valid_pulse)
    );

    // Instantiate UART TX
    UART_TX #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_tx_inst (
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .data(tx_data),
        .tx(tx_pin_wire),
        .busy(tx_busy)
    );

    // RX Buffer Logic
    // When a byte is received, store it and set available flag.
    // When CPU reads data register, clear available flag.
    always @(posedge clk) begin
        if (rst) begin
            rx_buffer <= 0;
            rx_data_available <= 0;
        end else begin
            if (rx_valid_pulse) begin
                rx_buffer <= rx_data;
                rx_data_available <= 1;
            end else if (re && addr[3:0] == REG_DATA) begin
                rx_data_available <= 0;
            end
        end
    end
    
    // TX Logic
    always @(posedge clk) begin
        if (rst) begin
            tx_start <= 0;
            tx_data <= 0;
        end else begin
            tx_start <= 0; // Default: no pulse
            if (we && addr[3:0] == REG_DATA) begin
                if (!tx_busy) begin
                    tx_data <= wdata[7:0];
                    tx_start <= 1;
                end
            end
        end
    end

    // Read Data Logic
    always @(*) begin
        rdata = 32'b0;
        case (addr[3:0])
            REG_DATA: rdata = {24'b0, rx_buffer};
            REG_STATUS: rdata = {30'b0, tx_busy, rx_data_available}; // Bit 1: TX Busy, Bit 0: RX Ready
            default: rdata = 32'b0;
        endcase
    end

endmodule
