//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//  Author: meisq                                                               //
//          msq@qq.com                                                          //
//          ALINX(shanghai) Technology Co.,Ltd                                  //
//          heijin                                                              //
//     WEB: http://www.alinx.cn/                                                //
//     BBS: http://www.heijin.org/                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
// Copyright (c) 2017,ALINX(shanghai) Technology Co.,Ltd                        //
//                    All rights reserved                                       //
//                                                                              //
// This source file may be used and distributed without restriction provided    //
// that this copyright statement is not removed from the file and that any      //
// derivative work contains the original copyright notice and the associated    //
// disclaimer.                                                                  //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////

//================================================================================
//  Revision History:
//  Date          By            Revision    Change Description
//--------------------------------------------------------------------------------
//2017/8/28                   1.0          Original
//*******************************************************************************/
module ad7606_sample(
	input                       adc_clk,
	input                       adc_rst_n,
	
	(* MARK_DEBUG="true" *)input[15:0]                 ad7606_data,             //ad7606 data
	(* MARK_DEBUG="true" *)input                       ad7606_busy,             //ad7606 busy
	(* MARK_DEBUG="true" *)input                       ad7606_first_data,       //ad7606 first data
	output[2:0]                 ad7606_os,               //ad7606
	output                      ad7606_cs,               //ad7606 AD cs
	(* MARK_DEBUG="true" *)output                      ad7606_rd,               //ad7606 AD data read
	output                      ad7606_reset,            //ad7606 AD reset
	output                      ad7606_convstab,         //ad7606 AD convert start
	
    (* MARK_DEBUG="true" *)input  [31:0]               sample_len,
	(* MARK_DEBUG="true" *)input                       sample_start,
	output reg                  st_clr,
	input  [7:0]                ch_sel,
	(* MARK_DEBUG="true" *)input signed [15:0]         gate,               //信号有效门限值
	(* MARK_DEBUG="true" *)input signed [15:0]         gate_high, 
	(* MARK_DEBUG="true" *)input signed [31:0]         glitch_time,

	
    (* MARK_DEBUG="true" *)output [63:0]               DMA_AXIS_tdata,
    (* MARK_DEBUG="true" *)output [7:0]                DMA_AXIS_tkeep,
    (* MARK_DEBUG="true" *)output                      DMA_AXIS_tlast,
    (* MARK_DEBUG="true" *)input                       DMA_AXIS_tready,
    (* MARK_DEBUG="true" *)output                      DMA_AXIS_tvalid,
    (* MARK_DEBUG="true" *)input [0:0]                 DMA_RST_N,
	(* MARK_DEBUG="true" *)input                       DMA_CLK
);
/******************************************/
//reg     [31:0]  sample_len;                        //手动赋值
//reg             sample_start;
//initial begin
//    sample_len <= 13'd1920;
//    sample_start <= 1'b1;
//end
/******************************************/
localparam       S_IDLE    = 0;
localparam       S_SAMPLE  = 1;
localparam       S_SAMP_WAIT    = 2;


(* MARK_DEBUG="true" *)reg[31:0]         sample_cnt;
reg[7:0]          wait_cnt;
(* MARK_DEBUG="true" *)reg[2:0]          state;

(* MARK_DEBUG="true" *)reg          adc_buf_wr   ;
(* MARK_DEBUG="true" *)reg signed[63:0]   adc_buf_data ;

reg          sample_start_d0 ;
reg          sample_start_d1 ;
reg          sample_start_d2 ;
reg [31:0]   sample_len_d0 ;
reg [31:0]   sample_len_d1 ;
reg [31:0]   sample_len_d2 ;
reg [7:0]    ch_sel_d0 ;
reg [7:0]    ch_sel_d1 ;
(* MARK_DEBUG="true" *)reg [7:0]    ch_sel_d2 ;

reg [31:0]   dma_len_d0 ;
reg [31:0]   dma_len_d1 ;
reg [31:0]   dma_len_d2 ;
reg [31:0]   dma_len ;
reg [31:0]   dma_cnt ;

reg         tvalid_en ;
wire[9:0]   rd_data_count ;              //手动赋值
(* MARK_DEBUG="true" *)wire        adc_buf_rd  ;
reg         adc_buf_rd_d0 ;
(* MARK_DEBUG="true" *)wire        empty;

(* MARK_DEBUG="true" *)reg          adc_buf_en ;
wire                        [7:0]        data_valid_ch;

wire signed[15:0]               ad_ch1;
wire signed[15:0]               ad_ch2;
wire signed[15:0]               ad_ch3;
wire signed[15:0]               ad_ch4;
wire signed[15:0]               ad_ch5;
wire signed[15:0]               ad_ch6;
wire signed[15:0]               ad_ch7;
wire signed[15:0]               ad_ch8;

wire     [63:0]           data_buf_ch1;  
wire     [63:0]           data_buf_ch2;
wire     [63:0]           data_buf_ch3;
wire     [63:0]           data_buf_ch4;
wire     [63:0]           data_buf_ch5;
wire     [63:0]           data_buf_ch6;
wire     [63:0]           data_buf_ch7;
wire     [63:0]           data_buf_ch8;

always@(posedge adc_clk or negedge adc_rst_n)
begin
	if(adc_rst_n == 1'b0)
	begin
		sample_start_d0 <= 1'b0;
		sample_start_d1 <= 1'b0;
		sample_start_d2 <= 1'b0;
		sample_len_d0   <= 32'd0 ;
		sample_len_d1   <= 32'd0 ;
		sample_len_d2   <= 32'd0 ;
		ch_sel_d0       <= 8'd0 ;
		ch_sel_d1       <= 8'd0 ;
		ch_sel_d2       <= 8'd0 ;
	end	
	else 
	begin
         sample_start_d0 <= sample_start;
         sample_start_d1 <= sample_start_d0;
         sample_start_d2 <= sample_start_d1;
         sample_len_d0   <= sample_len ;
         sample_len_d1   <= sample_len_d0 ;
         sample_len_d2   <= sample_len_d1 ;
         ch_sel_d0       <= ch_sel ;
         ch_sel_d1       <= ch_sel_d0 ;
         ch_sel_d2       <= ch_sel_d1 ;
     end    
end






always@(posedge adc_clk or posedge adc_rst_n)
begin
	if(adc_rst_n == 1'b0)
	begin
		state <= S_IDLE;
		wait_cnt <= 8'd0;
		sample_cnt <= 32'd0;
	end
	else
		case(state)
			S_IDLE:
			begin
			  if (sample_start_d2)
			  begin
				state  <= S_SAMP_WAIT ;
				st_clr <= 1'b1 ;
			  end		    
			end
			S_SAMP_WAIT :
			begin
			  if(wait_cnt == 8'd20)
			  begin
				state    <= S_SAMPLE;
				wait_cnt <= 8'd0;
			  end
			  else
			  begin
			  	wait_cnt <= wait_cnt + 8'd1;
			  end
			  st_clr <= 1'b0 ;
			end
			S_SAMPLE:
			begin
			  if (data_valid_ch)
			  begin
				if(sample_cnt == sample_len_d2 - 1)
				begin
					sample_cnt <= 32'd0;
					state <= S_IDLE;
				end
				else
				begin
					sample_cnt <= sample_cnt + 32'd1;
				end
			  end				
			end		
			default:
				state <= S_IDLE;
		endcase
end

/*****************************************/
always@(posedge adc_clk or posedge adc_rst_n)
begin
	if(adc_rst_n == 1'b0)
	begin
      adc_buf_data <= 64'd0 ;
      adc_buf_en <= 1'b0 ;
	end
    else 
    begin
        case (data_valid_ch)
            8'b0000_0001 : begin
                                adc_buf_data <= data_buf_ch1  ;
                                adc_buf_en <= 1'b1 ;
                           end
            8'b0000_0010 : begin
                                adc_buf_data <= data_buf_ch2  ;
                                adc_buf_en <= 1'b1 ;
                           end
            8'b0000_0100 : begin
                                adc_buf_data <= data_buf_ch3  ;
                                adc_buf_en <= 1'b1 ;
                           end
            8'b0000_1000 : begin
                                adc_buf_data <= data_buf_ch4  ;
                                adc_buf_en <= 1'b1 ;
                           end
            8'b0001_0000 : begin
                                adc_buf_data <= data_buf_ch5  ;
                                adc_buf_en <= 1'b1 ;
                           end
            8'b0010_0000 : begin
                                adc_buf_data <= data_buf_ch6  ;
                                adc_buf_en <= 1'b1 ;
                           end
            8'b0100_0000 : begin
                                adc_buf_data <= data_buf_ch7  ;
                                adc_buf_en <= 1'b1 ;
                           end
            8'b1000_0000 : begin
                                adc_buf_data <= data_buf_ch8  ;
                                adc_buf_en <= 1'b1 ;
                           end
            default      : begin
                                adc_buf_data <= 64'd0 ;
                                adc_buf_en <= 1'b0 ;
                           end
        endcase   
    end    
end
/*****************************************/

afifo afifo_inst
(
  .rst                (~DMA_RST_N),
  .wr_clk             (adc_clk   ),
  .rd_clk             (DMA_CLK   ),
  .din                (adc_buf_data   ),
  .wr_en              (adc_buf_en     ),
  .rd_en              (adc_buf_rd     ),
  .dout               (DMA_AXIS_tdata      ),
  .full               (          ), 
  .empty              (empty         ),
  .rd_data_count      (rd_data_count  ),
  .wr_data_count      (          ) 

) ;

ad7606_if ad7606_if_m0(
	.clk                   (adc_clk                    ),
	.rst_n                 (adc_rst_n                  ),
	.ad_data               (ad7606_data                ), //ad7606 data
	.ad_busy               (ad7606_busy                ), //ad7606 busy
	.first_data            (ad7606_first_data          ), //ad7606 first data
	.ad_os                 (ad7606_os                  ), //ad7606
	.ad_cs                 (ad7606_cs                  ), //ad7606 AD cs
	.ad_rd                 (ad7606_rd                  ), //ad7606 AD data read
	.ad_reset              (ad7606_reset               ), //ad7606 AD reset
	.ad_convstab           (ad7606_convstab            ), //ad7606 AD convert start
    .data_valid_ch         (data_valid_ch              ),
    .gate                  (gate                       ),
    .gate_high             (gate_high                  ),
    .glitch_time           (glitch_time                ),
	
	
	
	.ad_ch1                (ad_ch1                     ),
	.ad_ch2                (ad_ch2                     ),
	.ad_ch3                (ad_ch3                     ),
	.ad_ch4                (ad_ch4                     ),
	.ad_ch5                (ad_ch5                     ),
	.ad_ch6                (ad_ch6                     ),
	.ad_ch7                (ad_ch7                     ),
	.ad_ch8                (ad_ch8                     ),
	.data_buf_ch1          (data_buf_ch1               ),    
    .data_buf_ch2          (data_buf_ch2               ), 
    .data_buf_ch3          (data_buf_ch3               ), 
    .data_buf_ch4          (data_buf_ch4               ), 
    .data_buf_ch5          (data_buf_ch5               ), 
    .data_buf_ch6          (data_buf_ch6               ), 
    .data_buf_ch7          (data_buf_ch7               ), 
    .data_buf_ch8          (data_buf_ch8               )
);



assign adc_buf_rd = DMA_AXIS_tready && ~empty ;

always@(posedge DMA_CLK or negedge DMA_RST_N)
begin
	if(DMA_RST_N == 1'b0)
		adc_buf_rd_d0 <= 1'b0;
	else 
	    adc_buf_rd_d0 <= adc_buf_rd ;
end

always@(posedge DMA_CLK or negedge DMA_RST_N)
begin
	if(DMA_RST_N == 1'b0)
		tvalid_en <= 1'b0;
	else if (adc_buf_rd_d0 & ~DMA_AXIS_tready)
	    tvalid_en <= 1'b1 ;
	else if (DMA_AXIS_tready)
	    tvalid_en <= 1'b0;
end

always@(posedge DMA_CLK or negedge DMA_RST_N)
begin
	if(DMA_RST_N == 1'b0)
	begin
		dma_len_d0   <= 32'd0 ;
		dma_len_d1   <= 32'd0 ;
		dma_len_d2   <= 32'd0 ;
	end	
	else 
	begin
         dma_len_d0   <= sample_len ;
         dma_len_d1   <= dma_len_d0 ;
         dma_len_d2   <= dma_len_d1 ;
     end    
end

always@(posedge DMA_CLK or negedge DMA_RST_N)
begin
	if(DMA_RST_N == 1'b0)
		dma_len <= 32'd0;
	else if (rd_data_count > 10'd0)
	    dma_len <= dma_len_d2 ;
end

always@(posedge DMA_CLK or negedge DMA_RST_N)
begin
	if(DMA_RST_N == 1'b0)
		dma_cnt <= 32'd0;
	else if (DMA_AXIS_tvalid & ~DMA_AXIS_tlast)
	    dma_cnt <= dma_cnt + 1'b1 ;
	else if (DMA_AXIS_tvalid & DMA_AXIS_tlast)
	    dma_cnt <= 32'd0 ;
end




(* MARK_DEBUG="true" *)reg        timeout;
reg [31:0] timmer;
parameter integer delay_500ms = 25000000;
always @ (posedge DMA_CLK or negedge DMA_RST_N)begin
    if(DMA_RST_N == 1'b0) 
        timmer <= 32'd0;
    else if(dma_cnt < 8*dma_len - 1)    
        timmer <= timmer + 32'd1;
    else if (timmer > delay_500ms)
        timmer <= 32'd0;
    else if (DMA_AXIS_tlast == 1'b1)  
        timmer <= 32'd0;
end

always @ (posedge DMA_CLK or negedge DMA_RST_N)begin
    if(DMA_RST_N == 1'b0) 
        timeout <= 1'b0;
    else if (timmer == delay_500ms - 1'b1)
        timeout <= 1'b1;
    else if(DMA_AXIS_tlast == 1'b1)
        timeout <= 1'b0;
end


assign DMA_AXIS_tvalid =  DMA_AXIS_tready & (tvalid_en | adc_buf_rd_d0)  ;
assign DMA_AXIS_tkeep  = 8'b11111111 ;
//assign DMA_AXIS_tlast  = DMA_AXIS_tvalid & (dma_cnt == 8*dma_len - 1);
assign DMA_AXIS_tlast  = DMA_AXIS_tvalid & (dma_cnt == 8*dma_len - 1) | timeout ;

endmodule