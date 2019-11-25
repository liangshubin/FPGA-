`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/24 00:27:58
// Design Name: 
// Module Name: system_dma_top
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


module system_dma_top(
  inout [14:0]DDR_addr,
  inout [2:0]DDR_ba,
  inout DDR_cas_n,
  inout DDR_ck_n,
  inout DDR_ck_p,
  inout DDR_cke,
  inout DDR_cs_n,
  inout [3:0]DDR_dm,
  inout [31:0]DDR_dq,
  inout [3:0]DDR_dqs_n,
  inout [3:0]DDR_dqs_p,
  inout DDR_odt,
  inout DDR_ras_n,
  inout DDR_reset_n,
  inout DDR_we_n,
  inout FIXED_IO_ddr_vrn,
  inout FIXED_IO_ddr_vrp,
  inout [53:0]FIXED_IO_mio,
  inout FIXED_IO_ps_clk,
  inout FIXED_IO_ps_porb,
  inout FIXED_IO_ps_srstb
);

  reg [31:0]S_AXIS_tdata;
  reg  S_AXIS_tlast;
  reg S_AXIS_tvalid; 
  wire FCLK_CLK0;
  wire s_axis_aclk;
  wire s_axis_aresetn;
  wire [3:0]S_AXIS_tkeep;
  wire S_AXIS_tready;
  wire [0:0]gpio_rtl_tri_o;
  wire [0:0]peripheral_aresetn;
  reg [1:0] state;
  
assign S_AXIS_tkeep = 4'b1111;  
assign s_axis_aclk =  FCLK_CLK0;
assign s_axis_aresetn = peripheral_aresetn;
  
always@(posedge FCLK_CLK0)
   begin
       if(!peripheral_aresetn) begin
           S_AXIS_tvalid <= 1'b0;
           S_AXIS_tdata <= 32'd0;
           S_AXIS_tlast <= 1'b0;
           state <=0;
       end
       else begin
          case(state)
            0: begin
                if(gpio_rtl_tri_o&& S_AXIS_tready) begin
                   S_AXIS_tvalid <= 1'b1;
                   state <= 1;
                end
                else begin
                   S_AXIS_tvalid <= 1'b0;
                   state <= 0;
                end
              end
            1:begin
                 if(S_AXIS_tready) begin
                     S_AXIS_tdata <= S_AXIS_tdata + 1'b1;
                     if(S_AXIS_tdata == 16'd510) begin
                        S_AXIS_tlast <= 1'b1;
                        state <= 2;
                     end
                     else begin
                        S_AXIS_tlast <= 1'b0;
                        state <= 1;
                     end
                 end
                 else begin
                    S_AXIS_tdata <= S_AXIS_tdata;                   
                    state <= 1;
                 end
              end       
            2:begin
                 if(!S_AXIS_tready) begin
                    S_AXIS_tvalid <= 1'b1;
                    S_AXIS_tlast <= 1'b1;
                    S_AXIS_tdata <= S_AXIS_tdata;
                    state <= 2;
                 end
                 else begin
                    S_AXIS_tvalid <= 1'b0;
                    S_AXIS_tlast <= 1'b0;
                    S_AXIS_tdata <= 32'd0;
                    state <= 0;
                 end
              end
           default: state <=0;
           endcase
       end              
   end  




  system system_i
       (.DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FCLK_CLK0(FCLK_CLK0),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .S_AXIS_tdata(S_AXIS_tdata),
        .S_AXIS_tkeep(S_AXIS_tkeep),
        .S_AXIS_tlast(S_AXIS_tlast),
        .S_AXIS_tready(S_AXIS_tready),
        .S_AXIS_tvalid(S_AXIS_tvalid),
        .gpio_rtl_tri_o(gpio_rtl_tri_o),
        .peripheral_aresetn(peripheral_aresetn),
        .s_axis_aclk(s_axis_aclk),
        .s_axis_aresetn(s_axis_aresetn));
endmodule
