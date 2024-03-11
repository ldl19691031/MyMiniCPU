module uart_tx(
    input clk_i,            // 输入时钟，100MHz
    input reset,            // 复位信号
    input [7:0] data,       // 要发送的数据
    input send,             // 发送数据请求信号
    output reg uart0_txd_o, // UART发送线
    output reg busy         // UART模块是否忙
);

    // UART参数设置
    localparam BAUD_RATE = 19200;                // 波特率
    localparam CLOCK_FREQ = 100_000_000;         // 输入时钟频率
    localparam COUNTER_MAX = CLOCK_FREQ / BAUD_RATE; // 计数器上限值

    // 状态定义
    localparam IDLE = 0;
    localparam START_BIT = 1;
    localparam DATA_BITS = 2;
    localparam STOP_BIT = 3;
    localparam CLEANUP = 4;

    reg [2:0] state = IDLE;
    reg [7:0] tx_buffer;     // 发送缓冲区
    reg [3:0] bit_index;     // 当前发送的位索引
    reg [15:0] counter;      // 用于波特率生成的计数器
    initial begin
        busy = 0;
    end
    always @(posedge clk_i) begin
        if (reset) begin
            state <= IDLE;
            uart0_txd_o <= 1; // 空闲状态时，UART发送线为高电平
            busy <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (send) begin
                        tx_buffer <= data; // 加载要发送的数据
                        bit_index <= 0;
                        state <= START_BIT;
                        busy <= 1;
                    end
                    uart0_txd_o <= 1;
                end
                START_BIT: begin
                    if (counter < COUNTER_MAX - 1) begin
                        counter <= counter + 1;
                        uart0_txd_o <= 0; // 发送起始位
                    end else begin
                        counter <= 0;
                        state <= DATA_BITS;
                    end
                end
                DATA_BITS: begin
                    if (counter < COUNTER_MAX - 1) begin
                        counter <= counter + 1;
                        uart0_txd_o <= tx_buffer[bit_index]; // 发送数据位
                    end else begin
                        counter <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            state <= STOP_BIT;
                        end
                    end
                end
                STOP_BIT: begin
                    if (counter < COUNTER_MAX - 1) begin
                        counter <= counter + 1;
                        uart0_txd_o <= 1; // 发送停止位
                    end else begin
                        state <= CLEANUP;
                        counter <= 0;
                    end
                end
                CLEANUP: begin
                    busy <= 0;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
