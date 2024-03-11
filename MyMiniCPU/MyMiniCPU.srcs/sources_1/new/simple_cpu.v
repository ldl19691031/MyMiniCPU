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
    input clk,            // ʱ���ź�
    input reset,          // ��λ�ź�
    output reg [5:0] mem_address, // �ڴ��ַ
    input [31:0] mem_data,   // �ڴ�����
    output reg mem_write,   // �ڴ�дʹ��
    input mem_read_ready,  // �ڴ�������ź�
    output reg mem_read,   // �ڴ�������ź�
    output reg [31:0] mem_data_out
);
    reg [5:0] PC;          // ���������
    reg [3:0] stage;       // �����ֽ׶Σ�IF0, IF1, IF2, EX, WB
    reg [31:0] instruction; // ��ǰָ��
    reg [31:0] operand_a_data, operand_b_data, operand_c_data; // ����������
    reg [31:0] temp_result; // ��ʱ���
    //reg [31:0] mem_data_out; // �������ڴ�д������
    reg mem_data_out_valid; // �����źţ�ָʾ�Ƿ�Ӧ�����ڴ�д������
    wire [3:0] op_code;
    wire [7:0] value;
    wire [7:0] target;
    wire [7:0] operand_a_value, operand_b_value, operand_c_value;
    
    // �����ڴ�������Ϊ��̬�߼�
    assign op_code = instruction[31:28];
    assign value = instruction[11:4];
    assign target = instruction[27:20];
    assign operand_a_value = instruction[27:20];
    assign operand_b_value = instruction[19:12];
    assign operand_c_value = instruction[11:4];
    // ����ÿ���׶εı���
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
                IF0: begin // ��һ�׶ζ�ȡָ��
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
                IF1: begin // �ڶ��׶ζ�ȡ��һ��������
                    if (mem_read_ready) begin
                        if_wait_counter <= if_wait_counter + 1;
                        if (if_wait_counter == IF_CYCLE) begin
                            instruction <= mem_data; // �洢ָ��
                            mem_address <= mem_data[27:20]; // ��ȡ������A �ر𣬲��ܴ�op value��ȡ
                            stage <= IF2;
                            if_wait_counter <= 0;
                        end
                    end
                end
                IF2: begin // �����׶ζ�ȡ�ڶ���������
                    if (mem_read_ready) begin
                        if_wait_counter <= if_wait_counter + 1;
                        if (if_wait_counter == IF_CYCLE) begin
                            operand_a_data <= mem_data; // �洢������A
                            mem_address <= operand_b_value; // ��ȡ������B
                            stage <= IF3;
                            if_wait_counter <= 0;
                        end
                    end
                end
                IF3: begin
                    if (mem_read_ready) begin
                        if_wait_counter <= if_wait_counter + 1;
                        if (if_wait_counter == IF_CYCLE) begin
                            operand_b_data <= mem_data; // �洢������B
                            mem_address <= operand_c_value; // ��ȡ������C
                            stage <= IF4;
                            if_wait_counter <= 0;
                        end
                    end
                end
                IF4: begin // ��ȡ���洢�ڶ���������
                    if (mem_read_ready) begin
                        if_wait_counter <= if_wait_counter + 1;
                        if (if_wait_counter == IF_CYCLE) begin
                            operand_c_data <= mem_data; // �洢������C
                            mem_read <= 0; // ֹͣ��ȡ
                            stage <= EX; // ׼��ִ��ָ��
                            if_wait_counter <= 0;
                        end
                    end
                end
                EX: begin // ִ�н׶�
                    mem_read <= 0; // ֹͣ��ȡ����
                    // ����ָ�����ͽ�����Ӧ����
                    // �����Ϊ���ӣ�����Ҫ��������ָ�����
                    case (op_code)
                        OP_ADD: begin // ADD
                            temp_result <= operand_b_data + operand_c_data; // ʹ�����¶�ȡ�Ĳ�����B
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
                                PC <= PC + 1; // ���� PC
                            end
                        end
                        // ��������...
                    endcase
                    stage <= WB;
                end
                WB: begin // д�ؽ׶�
                    if(op_code != OP_NOP && op_code != OP_BNE) begin
                        mem_data_out <= temp_result; // ׼��д�������
                        mem_write <= 1;       // ����д��
                        mem_data_out_valid <= 1; // ʹ���������
                        PC <= PC + 1; // ���� PC
                        mem_address <= operand_a_value;
                    end
                    stage <= IF0; // ���ص� IF0��Ϊ��һ��ָ��׼��
                end
                default: begin
                    stage <= IF0; // �������δ����״̬�����õ� IF0
                end
            endcase
            // ��������źţ�Ϊ��һ��������׼��
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
    input clk_i,    // �ⲿʱ���źţ�100MHz
    input rstn_i,    // �ⲿ��λ�źţ��͵�ƽ��Ч
    output uart0_txd_o
    );
    wire [5:0] mem_address;
    wire [31:0] mem_data;
    wire [31:0] mem_data_out;
    wire mem_write;
    wire mem_read;
    (*rom_style = "block" *) reg [31:0] Mem[0:63]; // �����ڴ�
    reg mem_read_ready;

    localparam UART_OUT_MEM_ADDRESS=63;
    // SimpleCPU ʵ��
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

    // �ڴ��д�߼�
    reg [31:0] mem_data_reg;  // ���ڴ洢���ڴ��ȡ������
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
                  send <= 1; // ����Ϊ 1 �Կ�ʼ���� 'H'
                  data <= pending_send_data;
                  pending_send_data <= 0;
            end
            else begin
            pending_send_data <= Mem[UART_OUT_MEM_ADDRESS];
            end
        end else begin
            send <= 0; // ���ַ����ź�ֱ�� busy �ź��ͷ�;
        end
    end
    
    
    always @(posedge clk_i) begin
        if (rstn_i) begin
            // �����������ʼ���ڴ棬�����Ҫ�Ļ�
            $readmemb("init_mem.mem", Mem, 0, 63);
        end
        else begin
            if (mem_write) begin
                Mem[mem_address] <= mem_data_out;  // д���ڴ�
                mem_read_ready <= 0;
            end
            if (mem_read) begin
                mem_data_reg <= Mem[mem_address];  // ���ڴ��ȡ����
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