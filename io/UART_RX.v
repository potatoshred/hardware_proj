`timescale 1ns / 1ps

module UART_RX #(
    parameter CLK_FREQ = 100000000,
    parameter BAUD_RATE = 115200
) (
    input wire clk,
    input wire rst,
    input wire rx,
    output reg [7:0] data,
    output reg valid
);

    localparam CLK_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam STATE_IDLE  = 2'b00;
    localparam STATE_START = 2'b01;
    localparam STATE_DATA  = 2'b10;
    localparam STATE_STOP  = 2'b11;

    reg [1:0] state;
    reg [13:0] clk_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    
    // Synchronization
    reg rx_sync1, rx_sync2;
    always @(posedge clk) begin
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            clk_cnt <= 0;
            bit_cnt <= 0;
            data <= 0;
            valid <= 0;
            shift_reg <= 0;
        end else begin
            valid <= 0;
            case (state)
                STATE_IDLE: begin
                    if (rx_sync2 == 0) begin // Start bit detected
                        state <= STATE_START;
                        clk_cnt <= 0;
                    end
                end
                
                STATE_START: begin
                    if (clk_cnt == (CLK_PER_BIT / 2)) begin
                        if (rx_sync2 == 0) begin
                            state <= STATE_DATA;
                            clk_cnt <= 0;
                            bit_cnt <= 0;
                        end else begin
                            state <= STATE_IDLE; // False start
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                
                STATE_DATA: begin
                    if (clk_cnt == CLK_PER_BIT) begin
                        clk_cnt <= 0;
                        shift_reg[bit_cnt] <= rx_sync2;
                        if (bit_cnt == 7) begin
                            state <= STATE_STOP;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                
                STATE_STOP: begin
                    if (clk_cnt == CLK_PER_BIT) begin
                        state <= STATE_IDLE;
                        data <= shift_reg;
                        valid <= 1;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
            endcase
        end
    end

endmodule
