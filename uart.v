`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.06.2026 11:09:02
// Design Name: 
// Module Name: uart
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


module uart(
    input clk,reset,
    input st,
    
    output reg [16:0] mem_addr,
    input [11:0] mem_data,
    output reg mem_read_en,
    
    output tx,
    output reg led
);
wire s_tick;
reg [16:0] mem_ad;
topp xx(.clk(clk),.s_tick(s_tick));
localparam [3:0]s0=4'b0000,s1=4'b0001,s2=4'b0010,s3=4'b0011,s4=4'b0100,s5=4'b0101,s6=4'b0110,s7=4'b0111,s8=4'b1000;

reg [3:0]state,nextstate=4'b000;
reg [15:0]b_reg,b_next;
reg [3:0]n_reg,n_next;
reg t_reg,t_next;
reg byte_sel,byte_sel_reg;
reg [16:0] p_reg, p_next;


always@(posedge clk) begin

    if (reset)
    begin
        state <= s0;
        n_reg <= 0;
        b_reg <= 0;
        t_reg<=1;
        p_reg<=0;
        byte_sel_reg<=0;
        mem_addr<=0;
    end 
    else begin
        state<=nextstate;
        b_reg<=b_next;
        n_reg<=n_next;
        t_reg<=t_next;
        p_reg<=p_next;
        byte_sel_reg<=byte_sel;
        mem_addr<=mem_ad;
    end
end

always@(*) begin
    nextstate=state;
    b_next=b_reg;
    n_next=n_reg;
    t_next=t_reg;
    p_next=p_reg;
    byte_sel=byte_sel_reg;
    
    mem_read_en=0;
    mem_ad=mem_addr;
    case(state)
    s0: begin 
                t_next=1'b1;
                if(st==1'b1) begin
                    nextstate=s1;
                    
                    p_next=0;
                end
          end
    
    s1: begin
                if(s_tick) begin
                    t_next=0;
                    n_next=4'b0;
                    mem_ad = p_reg;        // Set address to read
                     
                    nextstate=s6;
                end
        end
    
    s2:begin    
              
              if(s_tick) begin
                    t_next=b_reg[0];
                    b_next=b_reg>>1; 
                    if(n_reg==7) begin
                        n_next=4'b0;
                        if(byte_sel_reg==0)begin
                            nextstate=s4;
                            byte_sel=1;
                        end
                        else
                            nextstate=s3; 
                    end
                    else
                        n_next=n_reg+1;
              end
       end
    s3: begin
              if(s_tick) begin
                  t_next=1'b1;
                  byte_sel=0;
                  if(p_reg==17'd76799) begin
                        nextstate=s8;
                        
                  end
                  else begin
                        p_next=p_reg+1; 
                        nextstate=s1;
              end
              end
        end
     s4: begin
                if(s_tick) begin
                    t_next=1'b1;
                    n_next=4'b0;
                    nextstate=s5;
                end
        end
     s5: begin
                if(s_tick) begin
                    t_next=1'b0;
                    n_next=4'b0;
                    nextstate=s2;
                end
         end
      s6:begin
                mem_read_en = 1;         // Enable memory read
                
                nextstate=s7;
         end
      s7:begin
            b_next = {mem_data,4'b0};
            nextstate=s2;
         end
      s8:begin
            if(!st)
                nextstate=s0;
         end
    endcase
end
  assign tx=t_reg; 
  
endmodule


module topp( input clk, output reg s_tick=1'b0

    );
    
    reg [13:0] count=11'b0;
    
        
    always @(posedge clk) begin
    if(count==14'd867) begin
        s_tick<=1'b1;count<=14'b0; end
    else begin
        s_tick<=1'b0;
        count<=count+1; end
    end
    
    
endmodule


