`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.06.2026 18:13:23
// Design Name: 
// Module Name: ov7670
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


module ov7670(
    input clk,vs,hs,reset,start_cam,
    input [7:0]d,
    input pclk,
    
    input [16:0] read_addr,      // Address to read from UART
    output reg [11:0] read_data,     // Data to UART
    input read_en ,
    
    output reg xclk,
    output reg ret,pwdn,
    output reg cam_led   
    );
    //memory
    reg [11:0]mem[0:76799];
    reg [2:0]c;
    //internal reg
    reg en;
    always @(posedge clk)begin
        if(reset)begin
            c<=3'b0;
            xclk<=1'b0;
        end
        else begin
            if(c==3'd4)begin
                xclk<=~xclk;
                c<=0;
            end
            else
                c<=c+1;
        end     
    end
    
     reg start_cam_sync, vs_sync, vs_delayed;
    always @(posedge pclk) begin
        if(reset) begin
            start_cam_sync <= 1'b0;
            vs_sync        <= 1'b0;
            vs_delayed     <= 1'b0;
        end else begin
            start_cam_sync <= start_cam;
            vs_sync        <= vs;
            vs_delayed     <= vs_sync;
        end
    end
        wire vs_falling = (!vs_sync && vs_delayed);
    
    //state regs
    localparam s0=0,s1=1,s2=2,s3=3,s4=4,s5=5,s6=6,s7=7;
    reg[2:0]state,nextstate;
    reg clr_addr;
    reg [3:0]f_c,f_c_reg;
    reg [16:0]addr;
    always@(posedge pclk)begin
            if(reset)begin
                state<=s0;
                f_c_reg<=0;
            end
            else begin
                state<=nextstate;
                f_c_reg<=f_c;
            end
    end
    always @(*)begin
        ret=1'b1;
        pwdn=1'b0;
        nextstate=state;
        en=0;
        clr_addr=0;
        f_c=f_c_reg;
        cam_led=1'b0;
        case(state) 
            s0:begin
                 pwdn=1'b1;
                 if(start_cam_sync)
                       nextstate=s1;
               end
             s1: begin
                if(vs_falling) begin
                    if(f_c_reg == 4'd10) begin
                        clr_addr  = 1;   
                        nextstate = s2;  
                    end
                    else begin
                        f_c = f_c_reg + 1; 
                    end
                end
            end
            
            s2: begin
                en = 1;
                if(addr>17'd76799) begin 
                    nextstate = s3;
                end
            end         
            s3:begin
                    cam_led=1'b1;
                    if(start_cam_sync == 1'b0)
                        nextstate = s0;
               end      
        endcase
    end
    reg byte_sel;
    reg [7:0]temp;
    
    reg [9:0]x,y;
    always @(posedge pclk) begin
        if(reset || clr_addr) begin
            addr <= 0;
            byte_sel <= 0;
        end
        else if(en) begin
            if(hs) begin
                if(!byte_sel) begin
                    temp <= d;
                    byte_sel <= 1;
                end
                else begin
                    mem[addr] <= {temp[7:4], temp[3:0], d[7:4]};
                    addr <= addr + 1;
                    byte_sel <= 0;
                end
            end
            else begin
                byte_sel <= 0;      
            end
        end
    end
    always @(posedge clk) begin
    if (read_en)
        read_data <= mem[read_addr];
    end
   
endmodule
