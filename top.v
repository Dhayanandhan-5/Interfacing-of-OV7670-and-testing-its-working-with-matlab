`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.07.2026 20:36:29
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


module top(
    // System
    input         clk,
    input         reset,

    // User controls
    input         start_cfg,
    input         start_cam,
    input         uart_start,

    // OV7670 Interface
    input         pclk,
    input         vs,
    input         hs,
    input  [7:0]  d,
    inout         sda,
    inout         scl,

    // Camera outputs
    output        xclk,
    output        ret,
    output        pwdn,

    // UART
    output        tx,

    // LEDs
    output        cam_led,
    output        fsm_led,
    output        uart_led
);

    //========================================================
    // Memory interface
    //========================================================

    wire [16:0] mem_addr;
    wire [11:0] mem_data;
    wire        mem_read_en;

    //========================================================
    // Camera Capture
    //========================================================

    ov7670 u_cam (
        .clk(clk),
        .vs(vs),
        .hs(hs),
        .reset(reset),
        .start_cam(start_cam),
        .d(d),
        .pclk(pclk),

        .read_addr(mem_addr),
        .read_data(mem_data),
        .read_en(mem_read_en),

        .xclk(xclk),
        .ret(ret),
        .pwdn(pwdn),
        .cam_led(cam_led)
    );

    //========================================================
    // Camera Configuration (SCCB)
    //========================================================

    fsm u_fsm (
        .clk(clk),
        .s_fsm(start_cfg),
        .reset(reset),

        .sda(sda),
        .scl(scl),

        .fsm_led(fsm_led)
    );

    //========================================================
    // UART Image Transmitter
    //========================================================

    uart u_uart (
        .clk(clk),
        .reset(reset),
        .st(uart_start),

        .mem_addr(mem_addr),
        .mem_data(mem_data),
        .mem_read_en(mem_read_en),

        .tx(tx),
        .led(uart_led)
    );

endmodule
