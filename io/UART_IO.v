`timescale 1ns / 1ps

module UART_IO #(
    parameter CLK_FREQ = 100000000,
    parameter BAUD_RATE = 115200
) (
    input wire clk,
    input wire rst,
    
    // Bus Interface
    input wire [31:0] addr,
    input wire [31:0] wdata,
    input wire we,      // Write Enable (active high)
    input wire re,      // Read Enable (active high)
    output reg [31:0] rdata,
    
    // UART Pins
    input wire rx,
    output wire tx
);

    // Internal Signals
    wire [7:0] rx_byte;
    wire rx_valid;
    wire tx_busy;
    reg [7:0] rx_data_latched;
    reg rx_ready;
    
    // UART Modules
    UART_RX #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_rx_inst (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .data(rx_byte),
        .valid(rx_valid)
    );
    
    reg tx_start;
    reg [7:0] tx_byte;
    
    UART_TX #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_tx_inst (
        .clk(clk),
        .rst(rst),
        .start(tx_start),
        .data(tx_byte),
        .tx(tx),
        .busy(tx_busy)
    );
    
    // RX Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_data_latched <= 0;
            rx_ready <= 0;
        end else begin
            if (rx_valid) begin
                rx_data_latched <= rx_byte;
                rx_ready <= 1; // Set ready flag
            end else if (re && addr[3:0] == 4'h0) begin
                rx_ready <= 0; // Clear ready flag on read of data register
            end
        end
    end
    
    // TX Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_start <= 0;
            tx_byte <= 0;
        end else begin
            tx_start <= 0; // Pulse
            if (we && addr[3:0] == 4'h0) begin
                if (!tx_busy) begin
                    tx_byte <= wdata[7:0];
                    tx_start <= 1;
                end
            end
        end
    end
    
    // Read Logic
    always @(*) begin
        case (addr[3:0])
            4'h0: rdata = {24'b0, rx_data_latched};
            4'h4: rdata = {30'b0, tx_busy, rx_ready}; // Bit 1: TX Busy, Bit 0: RX Ready
            default: rdata = 32'b0;
        endcase
    end

endmodule
