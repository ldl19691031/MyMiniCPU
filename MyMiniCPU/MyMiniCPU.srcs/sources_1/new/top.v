`timescale 1ns / 1ps
module top (
    input clk_i,    // �ⲿʱ���źţ�100MHz
    input rstn_i,    // �ⲿ��λ�źţ��͵�ƽ��Ч
    output uart0_txd_o
);
    combined combined_inst(
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .uart0_txd_o(uart0_txd_o)
    );
endmodule
