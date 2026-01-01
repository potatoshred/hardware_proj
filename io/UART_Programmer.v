`timescale 1ns / 1ps

module UART_Programmer (
    input wire clk,
    input wire rst,
    input wire uart_rx_pin,
    output reg [31:0] ram_addr,
    output reg [31:0] ram_wdata,
    output reg ram_we,
    output reg [7:0] debug_led
);

    wire [7:0] rx_byte;
    wire rx_valid;

    UART_RX #(
        .CLK_FREQ(100000000),
        .BAUD_RATE(115200)
    ) uart_rx_inst (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx_pin),
        .data(rx_byte),
        .valid(rx_valid)
    );

    reg [1:0] byte_ptr;
    reg [31:0] word_buffer;
    
    // State machine
    // 0: Waiting for byte 0 (LSB)
    // 1: Waiting for byte 1
    // 2: Waiting for byte 2
    // 3: Waiting for byte 3 (MSB) -> Write
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_addr <= 0;
            ram_wdata <= 0;
            ram_we <= 0;
            byte_ptr <= 0;
            word_buffer <= 0;
            debug_led <= 0;
        end else begin
            ram_we <= 0; // Default
            
            if (rx_valid) begin
                debug_led <= rx_byte; // Show last received byte on LEDs
                
                case (byte_ptr)
                    0: begin
                        word_buffer[7:0] <= rx_byte;
                        byte_ptr <= 1;
                    end
                    1: begin
                        word_buffer[15:8] <= rx_byte;
                        byte_ptr <= 2;
                    end
                    2: begin
                        word_buffer[23:16] <= rx_byte;
                        byte_ptr <= 3;
                    end
                    3: begin
                        word_buffer[31:24] <= rx_byte;
                        // Prepare write
                        ram_wdata <= {rx_byte, word_buffer[23:0]};
                        ram_we <= 1;
                        // Address will be incremented in next cycle logic or here?
                        // Let's increment address AFTER write.
                        // But ram_we is 1 for this cycle.
                        byte_ptr <= 0;
                    end
                endcase
            end
            
            if (ram_we) begin
                ram_addr <= ram_addr + 4; // Increment by 4 bytes
            end
        end
    end

endmodule
