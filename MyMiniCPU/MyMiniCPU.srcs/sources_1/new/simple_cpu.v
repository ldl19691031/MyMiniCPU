`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/09 11:30:06
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SimpleCPU(
    input clk,            // 时钟信号
    input reset,          // 复位信号
    output reg [5:0] mem_address, // 内存地址
    input [31:0] mem_data,   // 内存数据
    output reg mem_write,   // 内存写使能
    input mem_read_ready,  // 内存读就绪信号
    output reg mem_read,   // 内存读请求信号
    output reg [31:0] mem_data_out
);
    reg [5:0] PC;          // 程序计数器
    reg [3:0] stage;       // 控制现阶段：IF0, IF1, IF2, EX, WB
    reg [31:0] instruction; // 当前指令
    reg [31:0] operand_a_data, operand_b_data, operand_c_data; // 操作数数据
    reg [31:0] temp_result; // 临时结果
    //reg [31:0] mem_data_out; // 用于向内存写入数据
    reg mem_data_out_valid; // 控制信号，指示是否应该向内存写入数据
    wire [3:0] op_code;
    wire [7:0] value;
    wire [7:0] target;
    wire [7:0] operand_a_value, operand_b_value, operand_c_value;
    
    // 定义内存数据线为三态逻辑
    assign op_code = instruction[31:28];
    assign value = instruction[11:4];
    assign target = instruction[27:20];
    assign operand_a_value = instruction[27:20];
    assign operand_b_value = instruction[19:12];
    assign operand_c_value = instruction[11:4];
    // 定义每个阶段的编码
    localparam IF0 = 3'b000, IF1 = 3'b001, IF2 = 3'b010, IF3 = 3'b011, IF4=3'b100, EX = 3'b101, WB = 3'b110;
    localparam OP_NOP = 4'b0000, OP_ADD = 4'b0001, OP_SUB = 4'b0010, OP_IMM = 4'b0011, OP_BNE=4'b0100;
    localparam IF_MAX = IF4;
    localparam IF_CYCLE = 3;
    reg [2:0] if_wait_counter = 0;
    
    initial begin
            PC = 0;
            stage = IF0;
            mem_read = 0;
            mem_write = 0;
    end
    
    always @(posedge clk) begin
        if (reset) begin
            PC <= 0;
            stage <= IF0;
            mem_read <= 0;
            mem_write <= 0;
            if_wait_counter <= 0;
        end else begin
            case (stage)
                IF0: begin // 第一阶段读取指令
                    if(if_wait_counter == 0) begin
                        mem_address <= PC;
                        mem_read <= 1;
                    end
                    if_wait_counter <= if_wait_counter + 1;
                    if (if_wait_counter == IF_CYCLE) begin
                        stage <= IF1;
                        if_wait_counter <= 0;
                    end
                end
                IF1: begin // 第二阶段读取第一个操作数
                    if (mem_read_ready) begin
                        if_wait_counter <= if_wait_counter + 1;
                        if (if_wait_counter == IF_CYCLE) begin
                            instruction <= mem_data; // 存储指令
                            mem_address <= mem_data[27:20]; // 读取操作数A 特别，不能从op value读取
                            stage <= IF2;
                            if_wait_counter <= 0;
                        end
                    end
                end
                IF2: begin // 第三阶段读取第二个操作数
                    if (mem_read_ready) begin
                        if_wait_counter <= if_wait_counter + 1;
                        if (if_wait_counter == IF_CYCLE) begin
                            operand_a_data <= mem_data; // 存储操作数A
                            mem_address <= operand_b_value; // 读取操作数B
                            stage <= IF3;
                            if_wait_counter <= 0;
                        end
                    end
                end
                IF3: begin
                    if (mem_read_ready) begin
                        if_wait_counter <= if_wait_counter + 1;
                        if (if_wait_counter == IF_CYCLE) begin
                            operand_b_data <= mem_data; // 存储操作数B
                            mem_address <= operand_c_value; // 读取操作数C
                            stage <= IF4;
                            if_wait_counter <= 0;
                        end
                    end
                end
                IF4: begin // 读取并存储第二个操作数
                    if (mem_read_ready) begin
                        if_wait_counter <= if_wait_counter + 1;
                        if (if_wait_counter == IF_CYCLE) begin
                            operand_c_data <= mem_data; // 存储操作数C
                            mem_read <= 0; // 停止读取
                            stage <= EX; // 准备执行指令
                            if_wait_counter <= 0;
                        end
                    end
                end
                EX: begin // 执行阶段
                    mem_read <= 0; // 停止读取操作
                    // 根据指令类型进行相应操作
                    // 这里仅为例子，您需要根据您的指令集调整
                    case (op_code)
                        OP_ADD: begin // ADD
                            temp_result <= operand_b_data + operand_c_data; // 使用最新读取的操作数B
                        end
                        OP_SUB: begin
                            temp_result <= operand_b_data - operand_c_data;
                        end
                        OP_IMM: begin
                            temp_result <= value;
                        end
                        OP_BNE: begin
                            if (operand_b_data != operand_c_data)
                            begin
                                PC <= operand_a_value;
                            end
                            else begin
                                PC <= PC + 1; // 更新 PC
                            end
                        end
                        // 其他操作...
                    endcase
                    stage <= WB;
                end
                WB: begin // 写回阶段
                    if(op_code != OP_NOP && op_code != OP_BNE) begin
                        mem_data_out <= temp_result; // 准备写入的数据
                        mem_write <= 1;       // 启动写入
                        mem_data_out_valid <= 1; // 使能数据输出
                        PC <= PC + 1; // 更新 PC
                        mem_address <= operand_a_value;
                    end
                    stage <= IF0; // 返回到 IF0，为下一条指令准备
                end
                default: begin
                    stage <= IF0; // 如果出现未定义状态，重置到 IF0
                end
            endcase
            // 清除控制信号，为下一个周期做准备
            if (stage > IF_MAX) begin
                mem_read <= 0;
            end
            if (stage != WB) begin
                mem_write <= 0;
            end
        end
    end
endmodule

module combined(
    input clk_i,    // 外部时钟信号，100MHz
    input rstn_i,    // 外部复位信号，低电平有效
    output uart0_txd_o
    );
    wire [5:0] mem_address;
    wire [31:0] mem_data;
    wire [31:0] mem_data_out;
    wire mem_write;
    wire mem_read;
    (*rom_style = "block" *) reg [31:0] Mem[0:63]; // 定义内存
    reg mem_read_ready;

    localparam UART_OUT_MEM_ADDRESS=63;
    // SimpleCPU 实例
    SimpleCPU cpu(
        .clk(clk_i),
        .reset(rstn_i),
        .mem_address(mem_address),
        .mem_data(mem_data),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .mem_read_ready(mem_read_ready),
        .mem_data_out(mem_data_out)
    );

    // 内存读写逻辑
    reg [31:0] mem_data_reg;  // 用于存储从内存读取的数据
    assign mem_data = mem_data_reg;
    initial begin
        $readmemb("init_mem.mem", Mem, 0, 63);
        mem_read_ready = 0;
        pending_send_data = 0;
        data = 0;
        mem_data_reg = 0;
    end
    
    


    reg send = 0;
    wire busy;
    reg [7:0] data;
    reg [7:0] pending_send_data;
    uart_tx uart_tx_inst(
        .clk_i(clk_i),
        .reset(rstn_i),
        .send(send),
        .data(data),
        .uart0_txd_o(uart0_txd_o),
        .busy(busy)
    );
    
    //UART Output 
    always @(posedge clk_i) begin
        if (rstn_i) begin
            send <= 0;
        end else if (!busy) begin
            if(pending_send_data != 0) begin
                  send <= 1; // 设置为 1 以开始发送 'H'
                  data <= pending_send_data;
                  pending_send_data <= 0;
            end
            else begin
            pending_send_data <= Mem[UART_OUT_MEM_ADDRESS];
            end
        end else begin
            send <= 0; // 保持发送信号直到 busy 信号释放;
        end
    end
    
    
    always @(posedge clk_i) begin
        if (rstn_i) begin
            // 可以在这里初始化内存，如果需要的话
            $readmemb("init_mem.mem", Mem, 0, 63);
        end
        else begin
            if (mem_write) begin
                Mem[mem_address] <= mem_data_out;  // 写入内存
                mem_read_ready <= 0;
            end
            if (mem_read) begin
                mem_data_reg <= Mem[mem_address];  // 从内存读取数据
                mem_read_ready <= 1;
            end
            else begin
                mem_read_ready <= 0;
            end
        end
        
        if(pending_send_data != 0) begin
            Mem[UART_OUT_MEM_ADDRESS] <= 0;
        end
    end
endmodule