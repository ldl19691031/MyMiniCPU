`timescale 1ns / 1ps
module top (
    input clk_i,    // 外部时钟信号，100MHz
    input rstn_i,    // 外部复位信号，低电平有效
    output uart0_txd_o
);
    combined combined_inst(
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .uart0_txd_o(uart0_txd_o)
    );
endmodule
