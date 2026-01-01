`timescale 1ns / 1ps

module clkDivider(clk, clk_N);
    input wire clk;               // 系统时钟
    output clk_N;                 // 分频后的时钟
    parameter N = 4_000_000;      // 1Hz的时钟,N=fclk/fclk_N
    reg [31:0] counter;           /* 计数器变量，通过计数实现分频。
                                     当计数器从0计数到(N/2-1)时，
                                     输出时钟翻转，计数器清零 */ 
    reg flag = 0;
    assign clk_N = flag;
    
    always @(posedge clk)  begin  // 时钟上升沿
                                  // 功能实现
        if(counter == (N/2-1)) begin
            flag <= ~flag; 
            counter <= 0;
        end
        else counter <= counter + 1;
    end
    
endmodule