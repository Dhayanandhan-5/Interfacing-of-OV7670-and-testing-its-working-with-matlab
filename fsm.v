`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.06.2026 16:46:14
// Design Name: 
// Module Name: fsm
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


module fsm(
    input clk,s_fsm,reset,
    inout sda,
    inout scl,
    output reg fsm_led
    );
    reg s_fsm_sync;   
    parameter s0=0,s1=1,s2=2,s3=3,s4=4,s5=5,s6=6,s7=7,s8=8,s9=9,s10=10,s11=11,s12=12,s13=13,s14=14,s15=15,s16=16,s17=17,s18=18,s19=19,s20=20,s21=21,s22=22,s23=23,s24=24,s25=25,s26=26,s27=27,s28=28,s29=29;
    reg sda_en,sda_en_reg;
    reg scl_en;
    reg [4:0]state,nextstate;
    //reg en;
    reg[13:0]c;
    reg[12:0]co;
    reg p;
    
    reg [2:0]c1;
    reg en;
    parameter ele=75;
reg [7:0] addr [0:ele];
reg [7:0] data [0:ele];

initial begin

// Reset Configuration
addr[0]  = 8'h12; data[0]  = 8'h80;   // COM7: Reset SCCB registers
addr[1]  = 8'hFF; data[1]  = 8'hF0;   // Delay

// Output Format (RGB, QVGA)
addr[2]  = 8'h12; data[2]  = 8'h14;   // FIX: Restored to 0x14 for QVGA (320x240) resolution
addr[3]  = 8'h11; data[3]  = 8'h07;   // FIX: Restored to 0x07 to slow down PCLK and stop zebra noise
addr[4]  = 8'h0C; data[4]  = 8'h00;   // COM3
addr[5]  = 8'h3E; data[5]  = 8'h00;   // COM14: No scaling, normal pclock
addr[6]  = 8'h04; data[6]  = 8'h00;   // COM1: Disable CCIR656
addr[7]  = 8'h8C; data[7]  = 8'h02;   // RGB444: Enable RGB444 mode with xRGB
addr[8]  = 8'h40; data[8]  = 8'hF0;   // FIX: Changed to 0xF0 to fix the Red/Blue color swap!
addr[9]  = 8'h3A; data[9]  = 8'h04;   // TSLB: Set correct output data sequence

// Automatic Gain & Matrix Coefficients
addr[10] = 8'h14; data[10] = 8'h18;   // COM9: MAX AGC value x4
addr[11] = 8'h4F; data[11] = 8'hB3;   // MTX1: Matrix Coefficient 1
addr[12] = 8'h50; data[12] = 8'hB3;   // MTX2: Matrix Coefficient 2
addr[13] = 8'h51; data[13] = 8'h00;   // MTX3: Matrix Coefficient 3
addr[14] = 8'h52; data[14] = 8'h3D;   // MTX4: Matrix Coefficient 4
addr[15] = 8'h53; data[15] = 8'hA7;   // MTX5: Matrix Coefficient 5
addr[16] = 8'h54; data[16] = 8'hE4;   // MTX6: Matrix Coefficient 6
addr[17] = 8'h58; data[17] = 8'h9E;   // MTXS: Matrix Sign Bits
addr[18] = 8'h3D; data[18] = 8'hC0;   // COM13: Gamma enable

// Frame Window Layout Calibration
addr[19] = 8'h17; data[19] = 8'h14;   // HSTART
addr[20] = 8'h18; data[20] = 8'h02;   // HSTOP
addr[21] = 8'h32; data[21] = 8'h80;   // HREF
addr[22] = 8'h19; data[22] = 8'h03;   // VSTART
addr[23] = 8'h1A; data[23] = 8'h7B;   // VSTOP
addr[24] = 8'h03; data[24] = 8'h0A;   // VREF

// Timing & Internals
addr[25] = 8'h0F; data[25] = 8'h41;   // COM6: Reset timings
addr[26] = 8'h1E; data[26] = 8'h00;   // MVFP: Disable mirror / flip
addr[27] = 8'h33; data[27] = 8'h0B;   // CHLF
addr[28] = 8'h3C; data[28] = 8'h78;   // COM12: No HREF when VSYNC low
addr[29] = 8'h69; data[29] = 8'h00;   // GFIX: Fix gain control
addr[30] = 8'h74; data[30] = 8'h00;   // REG74: Digital gain control
addr[31] = 8'hB0; data[31] = 8'h84;   // RSVD: Required for good color
addr[32] = 8'hB1; data[32] = 8'h0C;   // ABLC1
addr[33] = 8'hB2; data[33] = 8'h0E;   // RSVD
addr[34] = 8'hB3; data[34] = 8'h80;   // THL_ST

// Scaling Controls
addr[35] = 8'h70; data[35] = 8'h3A;   // SCALING_XSC
addr[36] = 8'h71; data[36] = 8'h35;   // SCALING_YSC
addr[37] = 8'h72; data[37] = 8'h11;   // SCALING_DCWCTR
addr[38] = 8'h73; data[38] = 8'hF0;   // SCALING_PCLK_DIV
addr[39] = 8'hA2; data[39] = 8'h02;   // SCALING_PCLK_DELAY

// Gamma Curve Arrays
addr[40] = 8'h7A; data[40] = 8'h20;   // SLOP
addr[41] = 8'h7B; data[41] = 8'h10;   // GAM1
addr[42] = 8'h7C; data[42] = 8'h1E;   // GAM2
addr[43] = 8'h7D; data[43] = 8'h35;   // GAM3
addr[44] = 8'h7E; data[44] = 8'h5A;   // GAM4
addr[45] = 8'h7F; data[45] = 8'h69;   // GAM5
addr[46] = 8'h80; data[46] = 8'h76;   // GAM6
addr[47] = 8'h81; data[47] = 8'h80;   // GAM7
addr[48] = 8'h82; data[48] = 8'h88;   // GAM8
addr[49] = 8'h83; data[49] = 8'h8F;   // GAM9
addr[50] = 8'h84; data[50] = 8'h96;   // GAM10
addr[51] = 8'h85; data[51] = 8'hA3;   // GAM11
addr[52] = 8'h86; data[52] = 8'hAF;   // GAM12
addr[53] = 8'h87; data[53] = 8'hC4;   // GAM13
addr[54] = 8'h88; data[54] = 8'hD7;   // GAM14
addr[55] = 8'h89; data[55] = 8'hE8;   // GAM15

// Automatic Exposure & Automatic Gain Control Loop
addr[56] = 8'h13; data[56] = 8'hE0;   // COM8: Disable AGC / AEC
addr[57] = 8'h00; data[57] = 8'h00;   // GAIN: Set gain reg to 0
addr[58] = 8'h10; data[58] = 8'h00;   // ARCJ: Set reg to 0
addr[59] = 8'h0D; data[59] = 8'h40;   // COM4
addr[60] = 8'h14; data[60] = 8'h18;   // COM9: 4x gain + magic bit
addr[61] = 8'hA5; data[61] = 8'h05;   // BD50MAX
addr[62] = 8'hAB; data[62] = 8'h07;   // DB60MAX
addr[63] = 8'h24; data[63] = 8'h95;   // AGC Upper Limit
addr[64] = 8'h25; data[64] = 8'h33;   // AGC Lower Limit
addr[65] = 8'h26; data[65] = 8'hE3;   // AGC/AEC Fast Mode Operating Region
addr[66] = 8'h9F; data[66] = 8'h78;   // HAECC1
addr[67] = 8'hA0; data[67] = 8'h68;   // HAECC2
addr[68] = 8'hA1; data[68] = 8'h03;   // HAECC3 Magic
addr[69] = 8'hA6; data[69] = 8'hD8;   // HAECC4
addr[70] = 8'hA7; data[70] = 8'hD8;   // HAECC5
addr[71] = 8'hA8; data[71] = 8'hF0;   // HAECC6
addr[72] = 8'hA9; data[72] = 8'h90;   // HAECC7
addr[73] = 8'hAA; data[73] = 8'h94;   // HAECC8
addr[74] = 8'h13; data[74] = 8'hA7;   // COM8: Enable AGC / AEC loops
addr[75] = 8'h69; data[75] = 8'h06;   // GFIX

end





 
    always@(posedge clk)begin
        if(reset)
            s_fsm_sync<=0;
        else    
            s_fsm_sync<=s_fsm;
    end
        
    always@(posedge clk)begin
        if(reset)begin
            c<=14'b0;
            scl_en<=1;
        end
        else begin
            if(!en)begin
                if(c==14'd4999)begin
                    c<=14'b0;
                    scl_en<=~scl_en;
                end
                else begin
                    c<=c+1;
                end
            end
            else begin
                scl_en <= 1'b1;
                c <= 14'd0;         // ← add this line
            end    
        end
    end
    
    always@(posedge  clk)begin
        if(reset)begin
            co<=13'b0;
            p<=0;
        end
        else begin
            if(scl_en==1'b0)begin
                if(co==13'd2500)begin
                    p<=1;
                    co<=13'd0;
                end
                else begin
                    p<=0;
                    co<=co+1;
                end 
             
            end
            else   
                co<=0; 
        end
    end
    reg [12:0]h_c;
    reg h;
    always@(posedge clk)begin
        if(reset)begin
            h_c<=13'b0;
            h<=0;
        end
        else begin
            if(scl_en==1'b1)begin
                if(h_c==13'd2500)begin
                    h<=1;
                    h_c<=13'd0;
                end
                else begin
                    h<=0;
                    h_c<=h_c+1;
                end 
             
            end
            else   
               h_c<=0; 
        end
    end

    reg [13:0]str_count,str_count_reg;
    reg [7:0]b_next,b_reg;
    reg [3:0]n_next,n_reg;
    reg[13:0]o,o_reg;
    reg[7:0]d;
    reg en_1;
    reg[12:0]f,f_reg;
    reg [6:0]ptr,ptr_reg;
    always @(posedge clk)begin
        if(reset)begin
            state<=s0;
            sda_en_reg<=1'b1;
            str_count_reg<=0;
            b_reg<=0;
            n_reg<=0;
            o_reg<=0;
            d<=0;
            f_reg<=0;
            ptr_reg<=1;
        end
        else begin
            state<=nextstate;
            str_count_reg<=str_count;
            b_reg<=b_next;
            n_reg<=n_next;
            o_reg<=o;
            f_reg<=f;
            ptr_reg<=ptr;
             sda_en_reg<=sda_en;
             if (en_1)
                d   <= { d[6:0],sda};
        end
    end
    always@(*)begin
        nextstate=state;
        str_count=str_count_reg;
        b_next=b_reg;
        n_next=n_reg;
        o=o_reg;
        sda_en=sda_en_reg;
        en_1=0;
        f=f_reg;
        ptr=ptr_reg;
        fsm_led=0;
        case(state)
            s0:begin
                    if(s_fsm_sync) 
                        nextstate=s1;
               end
            s1:begin
                    if(str_count_reg==14'd4999)begin
                         sda_en=1'b0;
                         str_count=0;
                         nextstate=s2;
                         b_next=8'b0100_0010;
                   end
                   else
                        str_count=str_count_reg+1;
                end
            s2:begin
                    if(p) begin 
                        if(n_reg==8) begin
                            n_next=4'b0;
                            sda_en=1'b1;
                            nextstate=s3;
                            b_next=addr[ptr_reg];
                        end
                        else begin
                            n_next=n_reg+1;
                            sda_en=b_reg[7];
                            b_next=b_reg<<1;
                        end
                    end
                end
            s3: begin
                                nextstate=s4;
        
                end
             s4:begin
                    if(p) begin
                        if(n_reg==8) begin
                            n_next=4'b0;
                            sda_en=1'b1;
                            nextstate=s5;
                            b_next=data[ptr_reg] ;
                        end
                        else begin
                            n_next=n_reg+1;
                            sda_en=b_reg[7];
                            b_next=b_reg<<1; 
                        end
                    end
                end
             s5: begin
                                nextstate=s6;
                        
                end
             s6:begin
                    if(p) begin 
                        if(n_reg==8) begin
                            n_next=4'b0;
                            sda_en=1'b1;
                            nextstate=s7;
                        end
                        else begin
                            n_next=n_reg+1;
                            sda_en=b_reg[7];
                            b_next=b_reg<<1;
                        end
                    end
                end
             s7: begin
                            if(p)
                                nextstate=s8;
                end
             s8: begin
                        sda_en=0;
                        if(o_reg==14'd4999)begin
                            nextstate=s9;
                            o=14'b0;
                        end
                        else    
                            o=o_reg+1;
                end
                
              s9:begin
                        sda_en=1;
                        if(f_reg==13'd2499)begin
                            nextstate=s10;
                            f=13'b0;
                        end
                        else    
                            f=f_reg+1;
                 end
              s10:begin
                   if(str_count_reg==14'd4999)begin
                         sda_en=1'b0;
                         str_count=0;
                         nextstate=s11;
                         b_next=8'b0100_0010;
                   end
                   else
                        str_count=str_count_reg+1;
               end
            s11:begin
                    if(p) begin
                        if(n_reg==8) begin
                            n_next=4'b0;
                            sda_en=1'b1;
                            nextstate=s12;
                            b_next=addr[ptr_reg];
                        end
                        else begin
                            n_next=n_reg+1;
                            sda_en=b_reg[7];
                            b_next=b_reg<<1; 
                        end
                    end
                end
             s12: begin
                            nextstate=s13;
                end
             s13:begin
                    if(p) begin
                        if(n_reg==8) begin
                            n_next=4'b0;
                            sda_en=1'b1;
                            nextstate=s14;
                        end
                        else begin
                            n_next=n_reg+1;
                            sda_en=b_reg[7];
                            b_next=b_reg<<1; 
                        end
                    end
                end
                s14: begin
                            if(p)
                                nextstate=s15;
                        
                end
                
                s15: begin
                            sda_en=0;
                            if(o_reg==14'd4999)begin
                                nextstate=s16;
                                o=14'b0;
                            end
                            else    
                                o=o_reg+1;
                    end
                
                s16:begin
                        sda_en=1;
                        if(f_reg==13'd2499)begin
                            nextstate=s17;
                            f=13'b0;
                        end
                        else    
                            f=f_reg+1;
                 end
               s17:begin
                   if(str_count_reg==14'd4999)begin
                         sda_en=1'b0;
                         str_count=0;
                         nextstate=s18;
                         b_next=8'b0100_0011;
                   end
                   else
                        str_count=str_count_reg+1;
               end
               s18:begin
                    if(p) begin
                        if(n_reg==8) begin
                            n_next=4'b0;
                            sda_en=1'b1;
                            nextstate=s19;
                        end
                        else begin
                            n_next=n_reg+1;
                            sda_en=b_reg[7];
                            b_next=b_reg<<1; 
                        end
                    end
                end
              s19:begin
                            if(p)
                              nextstate=s20;
                  end  
              s20:begin
                    if(h) begin
                        en_1=1; 
                        if(n_reg==7) begin
                            n_next=4'b0;
                            sda_en=1'b1;
                            nextstate=s21;
                        end
                        else
                            n_next=n_reg+1;
                    end
                end
                s21: begin
                            if(p)
                                nextstate=s22;
                    end
                s22:begin
                    if(p)
                        nextstate=s23;
                end
                s23: begin
                        sda_en=0;
                        if(o_reg==14'd4999)begin
                            nextstate=s24;
                            o=14'b0;
                        end
                        else    
                            o=o_reg+1;
                end
                s24:begin
                        sda_en=1;
                        if(f_reg==13'd2499)begin
                            nextstate=s25;
                            f=13'b0;
                        end
                        else    
                            f=f_reg+1;
                 end
                s25:begin
                    sda_en=1'b1;
                    if(data[ptr_reg]==d)
                        nextstate=s26;
                    else    
                        nextstate=s28;
                end
               
                s26:begin
                        if(ptr_reg==ele)begin
                            ptr=0;
                            nextstate=s27;
                        end
                        else begin
                            ptr=ptr_reg+1;
                            nextstate=s1;
                        end       
                    end
                s27:begin
                        fsm_led=1;
                    end
                s28:begin
                        fsm_led=0;
                    end
        
        endcase
    end
    always@(*)begin
        if((state==s0)||(state==s1)||(state==s9)||(state==s10)||(state==16)||(state==s17)||(state==s24)||(state==25)||(state==s26)||(state==s27))
            en=1;
        else
            en=0;
    end
    
    
    assign sda=(sda_en_reg)?1'bz:1'b0;
    assign scl=(scl_en)?1'bz:1'b0;
endmodule
