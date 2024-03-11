module uart_tx(
    input clk_i,            // ����ʱ�ӣ�100MHz
    input reset,            // ��λ�ź�
    input [7:0] data,       // Ҫ���͵�����
    input send,             // �������������ź�
    output reg uart0_txd_o, // UART������
    output reg busy         // UARTģ���Ƿ�æ
);

    // UART��������
    localparam BAUD_RATE = 19200;                // ������
    localparam CLOCK_FREQ = 100_000_000;         // ����ʱ��Ƶ��
    localparam COUNTER_MAX = CLOCK_FREQ / BAUD_RATE; // ����������ֵ

    // ״̬����
    localparam IDLE = 0;
    localparam START_BIT = 1;
    localparam DATA_BITS = 2;
    localparam STOP_BIT = 3;
    localparam CLEANUP = 4;

    reg [2:0] state = IDLE;
    reg [7:0] tx_buffer;     // ���ͻ�����
    reg [3:0] bit_index;     // ��ǰ���͵�λ����
    reg [15:0] counter;      // ���ڲ��������ɵļ�����
    initial begin
        busy = 0;
    end
    always @(posedge clk_i) begin
        if (reset) begin
            state <= IDLE;
            uart0_txd_o <= 1; // ����״̬ʱ��UART������Ϊ�ߵ�ƽ
            busy <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (send) begin
                        tx_buffer <= data; // ����Ҫ���͵�����
                        bit_index <= 0;
                        state <= START_BIT;
                        busy <= 1;
                    end
                    uart0_txd_o <= 1;
                end
                START_BIT: begin
                    if (counter < COUNTER_MAX - 1) begin
                        counter <= counter + 1;
                        uart0_txd_o <= 0; // ������ʼλ
                    end else begin
                        counter <= 0;
                        state <= DATA_BITS;
                    end
                end
                DATA_BITS: begin
                    if (counter < COUNTER_MAX - 1) begin
                        counter <= counter + 1;
                        uart0_txd_o <= tx_buffer[bit_index]; // ��������λ
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
                        uart0_txd_o <= 1; // ����ֹͣλ
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
