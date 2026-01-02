`timescale 1ns / 1ps

module UART_TX #(
    parameter CLK_FREQ = 100000000,
    parameter BAUD_RATE = 115200
) (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] data,
    output reg tx,
    output reg busy
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

    always @(posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
            clk_cnt <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
            tx <= 1; // Idle high
            busy <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (start) begin
                        state <= STATE_START;
                        clk_cnt <= 0;
                        shift_reg <= data;
                        busy <= 1;
                        tx <= 0; // Start bit
                    end else begin
                        tx <= 1;
                        busy <= 0;
                    end
                end
                
                STATE_START: begin
                    if (clk_cnt == CLK_PER_BIT - 1) begin
                        state <= STATE_DATA;
                        clk_cnt <= 0;
                        bit_cnt <= 0;
                        tx <= shift_reg[0];
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                
                STATE_DATA: begin
                    if (clk_cnt == CLK_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        if (bit_cnt == 7) begin
                            state <= STATE_STOP;
                            tx <= 1; // Stop bit
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                            tx <= shift_reg[bit_cnt + 1]; // Shift next bit
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
                
                STATE_STOP: begin
                    if (clk_cnt == CLK_PER_BIT - 1) begin
                        state <= STATE_IDLE;
                        clk_cnt <= 0;
                        busy <= 0;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
            endcase
        end
    end

endmodule
