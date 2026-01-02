/******************************************************************************
** PS/2 收发器模块 (支持PS/2键盘协议)
**
** 功能说明:
**   - 实现PS/2协议的串并转换
**   - 支持从PS/2设备接收数据（如键盘扫描码）
**   - 支持向PS/2设备发送命令（如LED控制、复位等）
**   - 包含奇偶校验和错误检测
**
** 数据格式:
**   - 11位帧: 1起始位(0) + 8数据位(LSB先) + 1奇偶位 + 1停止位(1)
**   - 奇偶校验: 奇校验
**
** 使用说明:
**   - 本模块仅处理PS/2物理层和协议层
**   - 上层模块需要处理扫描码解析和ASCII转换
******************************************************************************/

module ps2_transmitter(
    input            clk,
    input            rst,

    // 输入数据端口 (从PS/2设备接收)
    input            clock_in,           // 连接到USB/PS2时钟输入信号
    input            serial_data_in,     // 连接到USB/PS2数据输入信号
    output reg [7:0] parallel_data_in,   // 8位接收数据缓冲区，来自PS/2接口
    output reg       parallel_data_valid,// 指示接收数据是否准备好
    output reg       data_in_error,      // 当奇偶校验不匹配时的读取错误标志

    // 输出数据端口 (向PS/2设备发送)
    output reg       clock_out,           // 连接到USB/PS2时钟输出信号
    output reg       serial_data_out,     // 连接到USB/PS2数据输出信号
    input      [7:0] parallel_data_out,   // 8位发送数据缓冲区，发送到PS/2接口
    input            parallel_data_enable,// 启动写入过程的控制信号
    output reg       data_out_complete,   // 数据发送完成标志

    output reg       busy,                // 指示发送器正在忙碌
    output reg       clock_output_oe,     // 时钟输出使能
    output reg       data_output_oe       // 数据输出使能
);

// 状态机
parameter [3:0] IDLE = 4'd0;
parameter [3:0] WAIT_IO = 4'd1;
parameter [3:0] DATA_IN = 4'd2;
parameter [3:0] DATA_OUT = 4'd3;
parameter [3:0] INITIALIZE = 4'd4;

reg  [3:0]  state;
reg  [3:0]  next_state;

// 并行数据缓冲区
reg  [10:0] data_out_buf;
reg  [10:0] data_in_buf;
reg  [3:0]  data_count;

// 时钟和数据输出计数器
reg  [15:0] clock_count;

// 用于检测clock_in的下降沿，判断是否有数据进入
// 如果有数据进入，则不能开始写出数据
reg  [1:0]  clock_in_delay;
wire        clock_in_negedge;
always @(posedge clk) begin
    clock_in_delay <= {clock_in_delay[0], clock_in};
end
assign clock_in_negedge = (clock_in_delay == 2'b10) ? 1'b1 : 1'b0;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

always @(posedge clk) begin
    case(state)
    IDLE: begin
        next_state <= WAIT_IO;
        clock_output_oe <= 1'b0;
        data_output_oe <= 1'b0;
        data_in_error <= 1'b0;
        data_count <= 4'd0;
        busy <= 1'b0;
        parallel_data_valid <= 1'b0;
        clock_count <= 16'd0;
        data_in_buf <= 11'h0;
        data_out_buf <= 11'h0;
        clock_out <= 1'b1;
        serial_data_out <= 1'b1;
        data_out_complete <= 1'b0;
        parallel_data_in <= 8'h00;
    end
    // 如果时钟被鼠标拉低，则开始读取
    // 如果需要发送数据，且不在数据读取模式下，则开始发送
    // 离开此状态时指示忙碌
    WAIT_IO: begin
        if(clock_in_negedge) begin  // 检测到输入数据，起始位被忽略
            next_state <= DATA_IN;
            busy <= 1'b1;
            data_count <= 4'd0;
        end
        else if(parallel_data_enable) begin // 检测到输出数据使能，在此发送起始位
            next_state <= INITIALIZE;
            busy <= 1'b1;
            data_count <= 4'd0;
            clock_output_oe <= 1'b1;
            clock_out <= 1'b0;  // 拉低约60us以初始化输出
            data_out_buf <= {parallel_data_out[0],parallel_data_out[1],parallel_data_out[2],parallel_data_out[3],
                             parallel_data_out[4],parallel_data_out[5],parallel_data_out[6],parallel_data_out[7],
                             ~^(parallel_data_out), 2'b11};
            data_output_oe <= 1'b1;
            serial_data_out <= 1'b0;
        end
    end
    // 起始位之后，检测时钟引脚上的10个下降沿，并移位记录数据
    // 完成后，反转字节并发送并行数据
    DATA_IN: begin
        if(clock_in_negedge && (data_count < 4'd10)) begin
            data_in_buf <= {data_in_buf[9:0], serial_data_in};
            data_count <= data_count + 4'd1;
        end
        else if(data_count == 4'd10) begin
            next_state <= IDLE;
            data_count <= 4'd0;
            busy <= 1'b0;
            parallel_data_valid <= 1'b1;
            parallel_data_in <= {data_in_buf[2],data_in_buf[3],data_in_buf[4],data_in_buf[5],
                                 data_in_buf[6],data_in_buf[7],data_in_buf[8],data_in_buf[9]};
            if(data_in_buf[1] == ^(data_in_buf[9:2])) begin
                data_in_error <= 1'b1;
            end
        end
    end
    // 发送前需要将时钟和数据拉低约60us，60us后时钟将恢复高电平
    INITIALIZE : begin
        if(clock_count < 16'd6000) begin
            clock_count <= clock_count + 16'd1;
            clock_output_oe <= 1'b1;
            clock_out <= 1'b0;
        end
        else begin
            next_state <= DATA_OUT;
            clock_output_oe <= 1'b0;
            clock_out <= 1'b1;
        end
    end
    // 鼠标将再次驱动时钟，等待并检测10个时钟下降沿以发送复位数据
    DATA_OUT : begin
        if(clock_in_negedge) begin
            if(data_count < 4'd10) begin
                data_count <= data_count + 4'd1;
                serial_data_out <= data_out_buf[10];
                data_out_buf <= {data_out_buf[9:0], 1'b0};
            end
            else if(data_count == 4'd10) begin
                data_out_complete <= 1'b1;
                next_state <= IDLE;
                busy <= 1'b0;
            end
        end
    end
    endcase
end

endmodule
