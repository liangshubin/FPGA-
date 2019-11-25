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
`timescale 1ns / 1ps
module ad7606_if #(
    parameter integer DATA_BUF_CH_WIDTH = 64,
    parameter integer MOMENT_WIDTH = 32,
    parameter delay_1s = 50000000,
//    parameter delay_1s = 1000,
    
    parameter IDLE=4'd0,
    parameter AD_CONV=4'd1,
    parameter Wait_1=4'd2,
    parameter Wait_busy=4'd3,
    parameter READ_CH1=4'd4,
    parameter READ_CH2=4'd5,
    parameter READ_CH3=4'd6,
    parameter READ_CH4=4'd7,
    parameter READ_CH5=4'd8,
    parameter READ_CH6=4'd9,
    parameter READ_CH7=4'd10,
    parameter READ_CH8=4'd11,
    parameter READ_DONE=4'd12,
    parameter cycle = 443                   //此参数与时钟频率有关，必须根据实际情况确定，否则将会导致时间差计算不准确！！！！！！！！
    
    
)
(
	input                        clk,
	input                        rst_n,
	input [15:0]                 ad_data,             //ad7606 data
	input                        ad_busy,             //ad7606 busy
	input                        first_data,          //ad7606 first data
	output [2:0]                 ad_os,               //ad7606
	(* MARK_DEBUG="true" *)output reg                   ad_cs,               //ad7606 AD cs
	(* MARK_DEBUG="true" *)output reg                   ad_rd,               //ad7606 AD data read
	(* MARK_DEBUG="true" *)output reg                   ad_reset,            //ad7606 AD reset
	output reg                   ad_convstab,         //ad7606 AD convert start

	(* MARK_DEBUG="true" *)output reg signed  [15:0]            ad_ch1,
	(* MARK_DEBUG="true" *)output reg signed  [15:0]            ad_ch2,
	output reg signed  [15:0]            ad_ch3,
	output reg signed  [15:0]            ad_ch4,
	output reg signed  [15:0]            ad_ch5,
	output reg signed  [15:0]            ad_ch6,
	output reg signed  [15:0]            ad_ch7,
	output reg signed  [15:0]            ad_ch8,
	
	(* MARK_DEBUG="true" *)output  reg  [DATA_BUF_CH_WIDTH-1:0]       data_buf_ch1,
    (* MARK_DEBUG="true" *)output  reg  [DATA_BUF_CH_WIDTH-1:0]       data_buf_ch2,
    output  reg  [DATA_BUF_CH_WIDTH-1:0]       data_buf_ch3,
    output  reg  [DATA_BUF_CH_WIDTH-1:0]       data_buf_ch4,
    output  reg  [DATA_BUF_CH_WIDTH-1:0]       data_buf_ch5,
    output  reg  [DATA_BUF_CH_WIDTH-1:0]       data_buf_ch6,
    output  reg  [DATA_BUF_CH_WIDTH-1:0]       data_buf_ch7,
    output  reg  [DATA_BUF_CH_WIDTH-1:0]       data_buf_ch8,
    
    output  reg                    validflag,
    
    (* MARK_DEBUG="true" *)output        [7:0]        data_valid_ch,    
    
    input signed [15:0]        gate ,                //信号低门限值
    input signed [15:0]        gate_high,            //信号高门限值
    input signed [31:0]        glitch_time
);
/*******************************************/
reg signed  [15:0]            ad_ch1_pre;
reg signed  [15:0]            ad_ch2_pre;
reg signed  [15:0]            ad_ch3_pre;
reg signed  [15:0]            ad_ch4_pre;
reg signed  [15:0]            ad_ch5_pre;
reg signed  [15:0]            ad_ch6_pre;
reg signed  [15:0]            ad_ch7_pre;
reg signed  [15:0]            ad_ch8_pre;

 (* MARK_DEBUG="true" *)reg [31:0] delay_timmer;
 (* MARK_DEBUG="true" *)reg        count_start;

(* MARK_DEBUG="true" *)reg         pause_ch1;       //通道CH1采样暂停
(* MARK_DEBUG="true" *)reg         pause_ch2;
(* MARK_DEBUG="true" *)reg         pause_ch3;
reg         pause_ch4;
reg         pause_ch5;
reg         pause_ch6;
reg         pause_ch7;
reg         pause_ch8;

reg [11:0] CLK_OFFSET_CH2 ;
reg [11:0] CLK_OFFSET_CH3 ;
reg [11:0] CLK_OFFSET_CH5 ;
reg [11:0] CLK_OFFSET_CH6 ;

initial begin
    CLK_OFFSET_CH2 <= 12'd0;   
    CLK_OFFSET_CH3 <= 12'd2700;
    CLK_OFFSET_CH5 <= 12'd3200;
    CLK_OFFSET_CH6 <= 12'd2700;   
end

//(* MARK_DEBUG="true" *)reg [7:0] begin_flag;
/***********************************************/

reg [15:0]  rst_cnt;
reg [5:0]   i;
(* MARK_DEBUG="true" *)reg [3:0]   state;

(* MARK_DEBUG="true" *)reg [22:0]   sample_cnt;



assign ad_os=3'b000;
always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
	begin
		rst_cnt <= 16'd0;
		ad_reset <= 1'b0;
	end
	else if(rst_cnt < 16'hffff)
//    else if(rst_cnt < 16'hff)             //调试代码
	begin
		rst_cnt <= rst_cnt + 16'd1;
		ad_reset <= 1'b1;
	end
	else if(sample_cnt == 23'h7fffff)
		ad_reset <= 1'b0;
    else
        ad_reset <= 1'b0;
end

/**********************/
(* MARK_DEBUG="true" *)reg rd_valid;
always @ (posedge clk or negedge rst_n)
begin
    if (!rst_n)
        rd_valid <= 1'b0;
    else begin
        if (first_data)
            rd_valid <= 1'b1;
        else if (state == READ_DONE)
            rd_valid <= 1'b0;
        else 
            rd_valid <= rd_valid;
    end
end
/***************************/
always@(posedge clk)
begin
	if(ad_reset==1'b1)
	begin
        ad_ch1_pre <= 0;
        ad_ch2_pre <= 0;
        ad_ch3_pre <= 0;
        ad_ch4_pre <= 0;
        ad_ch5_pre <= 0;
        ad_ch6_pre <= 0;
        ad_ch7_pre <= 0;
        ad_ch8_pre <= 0;	   
	end
	else
	begin  
	    ad_ch1_pre <= ad_ch1;
	    ad_ch2_pre <= ad_ch2;
	    ad_ch3_pre <= ad_ch3;
	    ad_ch4_pre <= ad_ch4;
	    ad_ch5_pre <= ad_ch5;
	    ad_ch6_pre <= ad_ch6;
	    ad_ch7_pre <= ad_ch7;
	    ad_ch8_pre <= ad_ch8;
	end
end	


	
always@(posedge clk)
begin
	if(ad_reset==1'b1)
	begin
		state <= IDLE;
		ad_ch1 <= 0;
		ad_ch2 <= 0;
		ad_ch3 <= 0;
		ad_ch4 <= 0;
		ad_ch5 <= 0;
		ad_ch6 <= 0;
		ad_ch7 <= 0;
		ad_ch8 <= 0;
		ad_cs <= 1'b1;
		ad_rd <= 1'b1;
		ad_convstab <= 1'b1;
		i <= 6'd0;
        sample_cnt <= 15'd0;
	end
	else
	begin
		case(state)
			IDLE:
			begin
				ad_cs<=1'b1;
				ad_rd<=1'b1;
				ad_convstab<=1'b1;
				if(i==20) begin
					i <= 6'd0;
					state<=AD_CONV;
				end
				else
					i <= i + 6'd1;
			end
			AD_CONV:
			begin
				if(i==2) 
				begin                        //wait 2 clock
					i <= 6'd0;
					state<=Wait_1;
					ad_convstab<=1'b1;
				end
				else 
				begin
					i <= i + 6'd1;
					ad_convstab<=1'b0;       
				end
			end
			Wait_1:
			begin
				if(i==5) 
				begin                           //wait 5 clock
					i <= 6'd0;
//					if (ad_sample_valid)            //采样有效才进入下一阶段进行采样
					state<=Wait_busy;
//					else
//					    state <= Wait_1;
				end
				else
					i <= i + 6'd1;
			end
			Wait_busy:
			begin
				if(ad_busy==1'b0) 
				begin                    //wait busy low
					i <= 6'd0;				
					state<=READ_CH1;
				end
			end
			READ_CH1:
            begin
                ad_cs<=1'b0;                              //cs valid
                if(i==3) 
                begin
                    ad_rd<=1'b1;
                    i <= 6'd0;
                    sample_cnt <= sample_cnt + 1;
                    if (pause_ch1 == 1'b0) begin
                       ad_ch1<=ad_data;                        //read CH1
                       state <= READ_CH2;   
                    end
                    else if (pause_ch1 == 1'b1) begin            //如果暂停CH1，ad_ch1赋0，相当于关闭CH1
                       ad_ch1<=16'd0;
                       state <= READ_CH2; 
                    end
                end
                else 
                begin
                    ad_rd<=1'b0;
                    i <= i + 6'd1;
                end
//                if(rd_valid)
//                    state <= READ_CH2;
            end
            READ_CH2:
            begin
                if(i==3) 
                begin
                    ad_rd<=1'b1;
                    i <= 6'd0;
                    if(pause_ch2 == 1'b0) begin
                       ad_ch2<=ad_data;                        //read CH2
                       state<=READ_CH3;
                    end
                    else if (pause_ch2 == 1'b1)begin
                       ad_ch2<=16'd0;
                       state<=READ_CH3;
                    end
                end
                else 
                begin
                    ad_rd<=1'b0;
                    i <= i + 6'd1;
                end
            end
            READ_CH3:
            begin
                if(i==3) 
                begin
                    ad_rd<=1'b1;
                    i <= 6'd0;
                    if(pause_ch3 == 1'b0) begin
                       ad_ch3<=ad_data;                        //read CH3
                       state<=READ_CH4;
                    end
                    else if (pause_ch3 == 1'b1)begin
                       ad_ch3<=16'd0;
                       state<=READ_CH4;
                    end
                end
                else 
                begin
                    ad_rd<=1'b0;
                    i <= i + 6'd1;
                end
            end
            READ_CH4: 
            begin
                if(i==3) 
                begin
                    ad_rd<=1'b1;
                    i <= 6'd0;
                    if(pause_ch4 == 1'b0) begin
                       ad_ch4<=ad_data;                        //read CH4                    
                       state<=READ_CH5;
                    end  
                    else if (pause_ch4 == 1'b1)begin
                       ad_ch4<=16'd0;
                       state<=READ_CH5;
                    end
                end
                else 
                begin
                    ad_rd<=1'b0;
                    i <= i + 6'd1;
                end
            end
            READ_CH5:
            begin
                if(i==3) 
                begin
                    ad_rd<=1'b1;
                    i <= 6'd0;
                    if(pause_ch5 == 1'b0)begin
                       ad_ch5<=ad_data;                        //read CH5
                       state<=READ_CH6;
                    end
                    else if(pause_ch5 == 1'b1)begin
                       ad_ch5<=16'd0;
                       state<=READ_CH6;
                    end
                end
                else 
                begin
                    ad_rd<=1'b0;
                    i <= i + 6'd1;
                end
            end
            READ_CH6:
            begin
                if(i==3) 
                begin
                    ad_rd<=1'b1;
                    i <= 6'd0;
                    if(pause_ch6 == 1'b0) begin
                       ad_ch6<=ad_data;                        //read CH6
                       state<=READ_CH7;
                    end
                    else if(pause_ch6 == 1'b1)begin
                       ad_ch6<=16'd0;
                       state<=READ_CH7;
                    end
                end
                else 
                begin
                    ad_rd<=1'b0;
                    i <= i + 6'd1;
                end
            end
            READ_CH7:
            begin
                if(i==3) 
                begin
                    ad_rd<=1'b1;
                    i <= 6'd0;
                    if(pause_ch7 == 1'b0)begin
                       ad_ch7<=ad_data;                        //read CH7
                       state<=READ_CH8;
                    end
                    else if(pause_ch7 == 1'b1)begin
                        ad_ch7<=16'd0;
                        state<=READ_CH8;
                    end
                end
                else 
                begin
                    ad_rd<=1'b0;
                    i <= i + 6'd1;
                end
            end
            READ_CH8:
            begin
                if(i==3) 
                begin
                    ad_rd<=1'b1;
                    i <= 6'd0;
                    if(pause_ch8 == 1'b0)begin
                       ad_ch8<=ad_data;                        //read CH8
                       state<=READ_DONE;
                    end
                    else if(pause_ch8 == 1'b1)begin
                       ad_ch8<=16'd0;
                       state<=READ_DONE;
                    end
                end
                else 
                begin
                    ad_rd<=1'b0;
                    i <= i + 6'd1;
                end
            end
            READ_DONE:
            begin
                ad_rd<=1'b1;
                ad_cs<=1'b1;
                state<=IDLE;
            end
            default:
                state<=IDLE;
         endcase
	end

 end
 
/*****************************************/
 (* MARK_DEBUG="true" *)reg [MOMENT_WIDTH-1:0] begin_moment_ch1;
 (* MARK_DEBUG="true" *)reg [MOMENT_WIDTH-1:0] begin_moment_ch2;
 reg [MOMENT_WIDTH-1:0] begin_moment_ch3;
 reg [MOMENT_WIDTH-1:0] begin_moment_ch4;
 reg [MOMENT_WIDTH-1:0] begin_moment_ch5;
 reg [MOMENT_WIDTH-1:0] begin_moment_ch6;
 reg [MOMENT_WIDTH-1:0] begin_moment_ch7;
 reg [MOMENT_WIDTH-1:0] begin_moment_ch8;
                             
// (* MARK_DEBUG="true" *)reg [MOMENT_WIDTH-1:0] end_moment_ch1;
// (* MARK_DEBUG="true" *)reg [MOMENT_WIDTH-1:0] end_moment_ch2;
//reg [MOMENT_WIDTH-1:0] end_moment_ch3;
//reg [MOMENT_WIDTH-1:0] end_moment_ch4;
//reg [MOMENT_WIDTH-1:0] end_moment_ch5;
//reg [MOMENT_WIDTH-1:0] end_moment_ch6;
//reg [MOMENT_WIDTH-1:0] end_moment_ch7;
//reg [MOMENT_WIDTH-1:0] end_moment_ch8;

 
 
// (* MARK_DEBUG="true" *)reg        data_valid_ch1;              //发送数据有效
// (* MARK_DEBUG="true" *)reg        data_valid_ch2;              
// reg        data_valid_ch3;              
// reg        data_valid_ch4;              
// reg        data_valid_ch5;              
// reg        data_valid_ch6;              
// reg        data_valid_ch7;              
// reg        data_valid_ch8;              
 
 (* MARK_DEBUG="true" *)reg signed  [MOMENT_WIDTH-1:0] signal_duration_ch1;         //信号持续时间
 (* MARK_DEBUG="true" *)reg signed  [MOMENT_WIDTH-1:0] signal_duration_ch2;         
 reg signed  [MOMENT_WIDTH-1:0] signal_duration_ch3;         
 reg signed  [MOMENT_WIDTH-1:0] signal_duration_ch4;         
 reg signed  [MOMENT_WIDTH-1:0] signal_duration_ch5;         
 reg signed  [MOMENT_WIDTH-1:0] signal_duration_ch6;         
 reg signed  [MOMENT_WIDTH-1:0] signal_duration_ch7;         
 reg signed  [MOMENT_WIDTH-1:0] signal_duration_ch8;         
 
// initial begin
//     signal_duration_ch1 <=32'd0;
//     signal_duration_ch2 <=32'd0;
//     signal_duration_ch3 <=32'd0;
//     signal_duration_ch4 <=32'd0;
//     signal_duration_ch5 <=32'd0;
//     signal_duration_ch6 <=32'd0;
//     signal_duration_ch7 <=32'd0;
//     signal_duration_ch8 <=32'd0;
     
     
//     end_moment_ch1    <= 32'd0;
//     end_moment_ch2    <= 32'd0;
//     end_moment_ch3    <= 32'd0;
//     end_moment_ch4    <= 32'd0;
//     end_moment_ch5    <= 32'd0;
//     end_moment_ch6    <= 32'd0;
//     end_moment_ch7    <= 32'd0;
//     end_moment_ch8    <= 32'd0;    
// end
 //完善系统时需考虑sample_cnt归零的情况，目前系统可持续采样27分钟
 /******************begin_moment_ch******************************/
 reg [DATA_BUF_CH_WIDTH-1:0] data_buf_ch1_backup;
 reg [DATA_BUF_CH_WIDTH-1:0] data_buf_ch2_backup;
 reg [DATA_BUF_CH_WIDTH-1:0] data_buf_ch3_backup;
 reg [DATA_BUF_CH_WIDTH-1:0] data_buf_ch4_backup;
 reg [DATA_BUF_CH_WIDTH-1:0] data_buf_ch5_backup;
 reg [DATA_BUF_CH_WIDTH-1:0] data_buf_ch6_backup;
 (* MARK_DEBUG="true" *)reg [DATA_BUF_CH_WIDTH-1:0] data_buf_ch7_backup;
 (* MARK_DEBUG="true" *)reg [DATA_BUF_CH_WIDTH-1:0] data_buf_ch8_backup;
 
/********************ch1******************************/
always @ (posedge clk or negedge rst_n ) begin
    if (!rst_n) 
        begin_moment_ch1 = 32'd0;    
    else if ((ad_ch1_pre < gate) && (ad_ch1 >= gate)) 
        begin_moment_ch1 = cycle * (sample_cnt - 1);           
end

//always @ (posedge clk) begin     
//         if ((ad_ch1_pre >= gate)&&(ad_ch1 < gate))
//             end_moment_ch1 <= cycle * (sample_cnt - 1);
//end

//  always @ (posedge clk) begin
//    signal_duration_ch1 = end_moment_ch1 - begin_moment_ch1;
//    if(signal_duration_ch1 > glitch_time )
//        data_valid_ch1 = 1'b1;
//    else 
//        data_valid_ch1 = 1'b0;
//  end

always @ (posedge clk or negedge rst_n) begin  
    if (!rst_n) 
        data_buf_ch1 <= 64'd0;
    else if(pause_ch1)
        data_buf_ch1 <= {32'd0,begin_moment_ch1};
end

 always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 0)
        data_buf_ch1_backup <= 64'd0;
    else
        data_buf_ch1_backup <= data_buf_ch1;       
 end
 
assign data_valid_ch[0] = data_buf_ch1_backup != data_buf_ch1 ? 1'b1 : 1'b0;



 /**********************ch2**************************/
always @ (posedge clk or negedge rst_n ) begin
     if (!rst_n) 
         begin_moment_ch2 = 32'd0;        
     else if ((ad_ch2_pre < gate) && (ad_ch2 >= gate)) 
          begin_moment_ch2 = cycle * (sample_cnt - 1) - CLK_OFFSET_CH2;            
 end
 
//always @ (posedge clk) begin     
//          if ((ad_ch2_pre >= gate)&&(ad_ch2 < gate))
//              end_moment_ch2 <= cycle * (sample_cnt - 1);
//end

//always @ (posedge clk) begin
//    signal_duration_ch2 <= end_moment_ch2 - begin_moment_ch2;
//    if(signal_duration_ch2 > glitch_time)
//        data_valid_ch2 <= 1'b1;
//    else 
//        data_valid_ch2 <= 1'b0;
//end
 
 always @ (posedge clk or negedge rst_n) begin  //data_valid_ch2 上升沿触发begin_moment_ch2发送
     if (!rst_n) 
         data_buf_ch2 <= 64'd0;
     else if(pause_ch2)
         data_buf_ch2 <= {32'd1,begin_moment_ch2};
 end

 always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 0)
        data_buf_ch2_backup <= 64'd0;
    else
        data_buf_ch2_backup <= data_buf_ch2;       
 end

assign data_valid_ch[1] = data_buf_ch2_backup != data_buf_ch2 ? 1'b1 : 1'b0;

 /**********************ch3**************************/
always @ (posedge clk or negedge rst_n ) begin
      if (!rst_n) 
          begin_moment_ch3 = 32'd0;        
      else if ((ad_ch3_pre < gate) && (ad_ch3 >= gate)) 
           begin_moment_ch3 = cycle * (sample_cnt - 1) - CLK_OFFSET_CH3;            
  end
  
// always @ (posedge clk) begin     
//          if ((ad_ch3_pre >= gate)&&(ad_ch3 < gate))
//              end_moment_ch3 <= cycle * (sample_cnt - 1);
//  end
  
//always @ (posedge clk) begin
//      signal_duration_ch3 <= end_moment_ch3 - begin_moment_ch3;
//      if(signal_duration_ch3 > glitch_time)
//          data_valid_ch3 <= 1'b1;
//      else
//          data_valid_ch3 <= 1'b0;
//  end
  
  always @ (posedge clk or negedge rst_n) begin  //data_valid_ch3 上升沿触发begin_moment_ch3发送
      if (!rst_n) 
          data_buf_ch3 <= 64'd0;
      else if(pause_ch3)
          data_buf_ch3 <= {32'd2,begin_moment_ch3};
  end

 always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 0)
        data_buf_ch3_backup <= 64'd0;
    else
        data_buf_ch3_backup <= data_buf_ch3;       
 end

 assign data_valid_ch[2] = data_buf_ch3_backup != data_buf_ch3 ? 1'b1 : 1'b0;
  
 /**********************ch4**************************/
always @ (posedge clk or negedge rst_n ) begin
      if (!rst_n) 
          begin_moment_ch4 = 32'd0;        
      else if ((ad_ch4_pre < gate) && (ad_ch4 >= gate)) 
           begin_moment_ch4 = cycle * (sample_cnt - 1);            
  end
  
// always @ (posedge clk) begin     
//          if ((ad_ch4_pre >= gate)&&(ad_ch4 < gate))
//              end_moment_ch4 <= cycle * (sample_cnt - 1);
//  end
 
// always @ (posedge clk) begin
//      signal_duration_ch4 <= end_moment_ch4 - begin_moment_ch4;
//      if(signal_duration_ch4 > glitch_time)
//          data_valid_ch4 <= 1'b1;
//      else
//          data_valid_ch4 <= 1'b0;
//  end
  
  always @ (posedge clk or negedge rst_n) begin  //data_valid_ch4 上升沿触发begin_moment_ch4发送
      if (!rst_n) 
          data_buf_ch4 <= 64'd0;
      else if(pause_ch4)
          data_buf_ch4 <= {32'd3,begin_moment_ch4};
  end

 always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 0)
        data_buf_ch4_backup <= 64'd0;
    else
        data_buf_ch4_backup <= data_buf_ch4;       
 end 

 assign data_valid_ch[3] = data_buf_ch4_backup != data_buf_ch4 ? 1'b1 : 1'b0;

 /**********************ch5**************************/
always @ (posedge clk or negedge rst_n ) begin
      if (!rst_n) 
          begin_moment_ch5 = 32'd0;        
      else if ((ad_ch5_pre < gate) && (ad_ch5 >= gate)) 
           begin_moment_ch5 = cycle * (sample_cnt - 1)- CLK_OFFSET_CH5;            
  end
  
//always @ (posedge clk) begin     
//           if ((ad_ch5_pre >= gate)&&(ad_ch5 < gate))
//               end_moment_ch5 <= cycle * (sample_cnt - 1);
//  end
 
// always @ (posedge clk) begin
//      signal_duration_ch5 <= end_moment_ch5 - begin_moment_ch5;
//      if(signal_duration_ch5 > glitch_time)
//          data_valid_ch5 <= 1'b1;
//      else
//          data_valid_ch5 <= 1'b0;
//  end
  
  always @ (posedge clk or negedge rst_n) begin  //data_valid_ch5 上升沿触发begin_moment_ch5发送
      if (!rst_n) 
          data_buf_ch5 <= 64'd0;
      else if(pause_ch5)
          data_buf_ch5 <= {32'd4,begin_moment_ch5};
  end

 always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 0)
        data_buf_ch5_backup <= 64'd0;
    else 
        data_buf_ch5_backup <= data_buf_ch5;       
 end

assign data_valid_ch[4] = data_buf_ch5_backup != data_buf_ch5 ? 1'b1 : 1'b0;

 /**********************ch6**************************/
always @ (posedge clk or negedge rst_n ) begin
      if (!rst_n) 
          begin_moment_ch6 = 32'd0;        
      else if ((ad_ch6_pre < gate) && (ad_ch6 >= gate)) 
           begin_moment_ch6 = cycle * (sample_cnt - 1) - CLK_OFFSET_CH6;            
  end

//always @ (posedge clk) begin     
//         if ((ad_ch6_pre >= gate)&&(ad_ch6 < gate))
//             end_moment_ch6 <= cycle * (sample_cnt - 1);
//end
 
// always @ (posedge clk) begin
//    signal_duration_ch6 <= end_moment_ch6 - begin_moment_ch6;
//    if(signal_duration_ch6 > glitch_time)
//        data_valid_ch6 <= 1'b1;
//    else
//        data_valid_ch6 <= 1'b0;
//end
  
  always @ (posedge clk or negedge rst_n) begin  //data_valid_ch6 上升沿触发begin_moment_ch6发送
      if (!rst_n) 
          data_buf_ch6 <= 64'd0;
      else if(pause_ch6)
          data_buf_ch6 <= {32'd5,begin_moment_ch6};
  end


 always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 0)
        data_buf_ch6_backup <= 64'd0;
    else
        data_buf_ch6_backup <= data_buf_ch6;       
 end

assign data_valid_ch[5] = data_buf_ch6_backup != data_buf_ch6 ? 1'b1 : 1'b0;

 /**********************ch7**************************/
always @ (posedge clk or negedge rst_n ) begin
      if (!rst_n) 
          begin_moment_ch7 = 32'd0;        
      else if ((ad_ch7_pre < gate) && (ad_ch7 >= gate)) 
           begin_moment_ch7 = cycle * (sample_cnt - 1);            
  end

//always @ (posedge clk) begin     
//         if ((ad_ch7_pre >= gate)&&(ad_ch7 < gate))
//             end_moment_ch7 <= cycle * (sample_cnt - 1);
//end

//always @ (posedge clk) begin
//    signal_duration_ch7 <= end_moment_ch7 - begin_moment_ch7;
//    if(signal_duration_ch7 > glitch_time)
//        data_valid_ch7 <= 1'b1;
//    else
//        data_valid_ch7 <= 1'b0;
//end
  
  always @ (posedge clk or negedge rst_n) begin  //data_valid_ch7 上升沿触发begin_moment_ch7发送
      if (!rst_n) 
          data_buf_ch7 <= 64'd0;
      else if(pause_ch7)
          data_buf_ch7 <= {32'd6,begin_moment_ch7};
  end

 always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 0)
        data_buf_ch7_backup <= 64'd0;
    else
        data_buf_ch7_backup <= data_buf_ch7;       
 end

assign data_valid_ch[6] = data_buf_ch7_backup != data_buf_ch7 ? 1'b1 : 1'b0;

 /**********************ch8**************************/
always @ (posedge clk or negedge rst_n ) begin
      if (!rst_n) 
          begin_moment_ch8 = 32'd0;        
      else if ((ad_ch8_pre < gate) && (ad_ch8 >= gate)) 
           begin_moment_ch8 = cycle * (sample_cnt - 1);            
  end
  
//always @ (posedge clk) begin     
//          if ((ad_ch8_pre >= gate)&&(ad_ch8 < gate))
//               end_moment_ch8 <= cycle * (sample_cnt - 1);
//  end


//always @ (posedge clk) begin
//    signal_duration_ch8 <= end_moment_ch8 - begin_moment_ch8;
//    if(signal_duration_ch8 > glitch_time)
//        data_valid_ch8 <= 1'b1;
//    else
//        data_valid_ch8 <= 1'b0;
//end
  
  always @ (posedge clk or negedge rst_n) begin  //data_valid_ch8 上升沿触发begin_moment_ch8发送
      if (!rst_n) 
          data_buf_ch8 <= 64'd0;
      else if(pause_ch8)
          data_buf_ch8 <= {32'd7,begin_moment_ch8};
  end

 always @ (posedge clk or negedge rst_n) begin
    if (rst_n == 0)
        data_buf_ch8_backup <= 64'd0;
    else
        data_buf_ch8_backup <= data_buf_ch8;       
 end
 
assign data_valid_ch[7] = data_buf_ch8_backup != data_buf_ch8 ? 1'b1 : 1'b0;

 /***********************延时屏蔽通道***************************/ 
 always @ (posedge clk or negedge rst_n) begin
   if (!rst_n) 
       pause_ch1 <= 1'b0;
   else if ((ad_ch1_pre < gate_high) && (ad_ch1 >= gate_high))
       pause_ch1 <= 1'b1;
   else if (delay_timmer >= delay_1s)
       pause_ch1 <= 1'b0;
 end

 always @ (posedge clk or negedge rst_n) begin
   if (!rst_n) 
       pause_ch2 <= 1'b0;
   else if ((ad_ch2_pre < gate_high) && (ad_ch2 >= gate_high))
       pause_ch2 <= 1'b1;
   else if (delay_timmer >= delay_1s)
       pause_ch2 <= 1'b0;
 end

 always @ (posedge clk or negedge rst_n) begin
   if (!rst_n) 
       pause_ch3 <= 1'b0;
   else if ((ad_ch3_pre < gate_high) && (ad_ch3 >= gate_high))
       pause_ch3 <= 1'b1;
   else if (delay_timmer >= delay_1s)
       pause_ch3 <= 1'b0;
 end

 always @ (posedge clk or negedge rst_n) begin
   if (!rst_n) 
       pause_ch4 <= 1'b0;
   else if ((ad_ch4_pre < gate_high) && (ad_ch4 >= gate_high))
       pause_ch4 <= 1'b1;
   else if (delay_timmer >= delay_1s)
       pause_ch4 <= 1'b0;
 end

 always @ (posedge clk or negedge rst_n) begin
   if (!rst_n) 
       pause_ch5 <= 1'b0;
   else if ((ad_ch5_pre < gate_high) && (ad_ch5 >= gate_high))
       pause_ch5 <= 1'b1;
   else if (delay_timmer >= delay_1s)
       pause_ch5 <= 1'b0;
 end

 always @ (posedge clk or negedge rst_n) begin
   if (!rst_n) 
       pause_ch6 <= 1'b0;
   else if ((ad_ch6_pre < gate_high) && (ad_ch6 >= gate_high))
       pause_ch6 <= 1'b1;
   else if (delay_timmer >= delay_1s)
       pause_ch6 <= 1'b0;
 end

 always @ (posedge clk or negedge rst_n) begin
   if (!rst_n) 
       pause_ch7 <= 1'b0;
   else if ((ad_ch7_pre < gate_high) && (ad_ch7 >= gate_high))
       pause_ch7 <= 1'b1;
   else if (delay_timmer >= delay_1s)
       pause_ch7 <= 1'b0;
 end

 always @ (posedge clk or negedge rst_n) begin
   if (!rst_n) 
       pause_ch8 <= 1'b0;
   else if ((ad_ch8_pre < gate_high) && (ad_ch8 >= gate_high))
       pause_ch8 <= 1'b1;
   else if (delay_timmer >= delay_1s)
       pause_ch8 <= 1'b0;
 end

     

 always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        count_start <= 1'b0;
   else if ((ad_ch1_pre < gate_high) && (ad_ch1 >= gate_high)) 
        count_start <= 1'b1;
   else if ((ad_ch2_pre < gate_high) && (ad_ch2 >= gate_high)) 
        count_start <= 1'b1;
   else if ((ad_ch3_pre < gate_high) && (ad_ch3 >= gate_high)) 
        count_start <= 1'b1;   
   else if ((ad_ch4_pre < gate_high) && (ad_ch4 >= gate_high)) 
        count_start <= 1'b1;   
   else if ((ad_ch5_pre < gate_high) && (ad_ch5 >= gate_high)) 
        count_start <= 1'b1;
   else if ((ad_ch6_pre < gate_high) && (ad_ch6 >= gate_high)) 
        count_start <= 1'b1;
   else if ((ad_ch7_pre < gate_high) && (ad_ch7 >= gate_high)) 
         count_start <= 1'b1;
   else if ((ad_ch8_pre < gate_high) && (ad_ch8 >= gate_high)) 
         count_start <= 1'b1;                    
   else if (delay_timmer >= delay_1s)
         count_start <= 1'b0;
   else
        count_start <= count_start;
end


 always @ (posedge clk or negedge rst_n) begin
    if(!rst_n)
        delay_timmer <= 32'd0;
    else if (count_start)
            delay_timmer <= delay_timmer + 1'b1;
    else if (delay_timmer >= delay_1s)
            delay_timmer <= 32'd0;
           
 end
 /**************************************/
endmodule

 /***********************延时屏蔽通道***************************/ 
// (* MARK_DEBUG="true" *)reg [31:0] delay_timmer;
// (* MARK_DEBUG="true" *)reg        count_start;
// parameter delay_1ms = 50000;
// parameter delay_1s = 50000000;


// always @ (posedge clk or negedge rst_n) begin
//   if (!rst_n) 
//       pause_ch1 <= 1'b0;
//   else if ((ad_ch1_pre < gate) && (ad_ch1 >= gate))
//       pause_ch1 <= 1'b1;
//   else if (delay_timmer >= delay_1s)
//       pause_ch1 <= 1'b0;
// end

// always @ (posedge clk or negedge rst_n) begin
//   if (!rst_n) 
//       pause_ch2 <= 1'b0;
//   else if ((ad_ch2_pre < gate) && (ad_ch2 >= gate))
//       pause_ch2 <= 1'b1;
//   else if (delay_timmer >= delay_1s)
//       pause_ch2 <= 1'b0;
// end

// always @ (posedge clk or negedge rst_n) begin
//   if (!rst_n) 
//       pause_ch3 <= 1'b0;
//   else if ((ad_ch3_pre < gate) && (ad_ch3 >= gate))
//       pause_ch3 <= 1'b1;
//   else if (delay_timmer >= delay_1s)
//       pause_ch3 <= 1'b0;
// end

// always @ (posedge clk or negedge rst_n) begin
//   if (!rst_n) 
//       pause_ch4 <= 1'b0;
//   else if ((ad_ch4_pre < gate) && (ad_ch4 >= gate))
//       pause_ch4 <= 1'b1;
//   else if (delay_timmer >= delay_1s)
//       pause_ch4 <= 1'b0;
// end

// always @ (posedge clk or negedge rst_n) begin
//   if (!rst_n) 
//       pause_ch5 <= 1'b0;
//   else if ((ad_ch5_pre < gate) && (ad_ch5 >= gate))
//       pause_ch5 <= 1'b1;
//   else if (delay_timmer >= delay_1s)
//       pause_ch5 <= 1'b0;
// end

// always @ (posedge clk or negedge rst_n) begin
//   if (!rst_n) 
//       pause_ch6 <= 1'b0;
//   else if ((ad_ch6_pre < gate) && (ad_ch6 >= gate))
//       pause_ch6 <= 1'b1;
//   else if (delay_timmer >= delay_1s)
//       pause_ch6 <= 1'b0;
// end

// always @ (posedge clk or negedge rst_n) begin
//   if (!rst_n) 
//       pause_ch7 <= 1'b0;
//   else if ((ad_ch7_pre < gate) && (ad_ch7 >= gate))
//       pause_ch7 <= 1'b1;
//   else if (delay_timmer >= delay_1s)
//       pause_ch7 <= 1'b0;
// end

// always @ (posedge clk or negedge rst_n) begin
//   if (!rst_n) 
//       pause_ch8 <= 1'b0;
//   else if ((ad_ch8_pre < gate) && (ad_ch8 >= gate))
//       pause_ch8 <= 1'b1;
//   else if (delay_timmer >= delay_1s)
//       pause_ch8 <= 1'b0;
// end

     

// always @ (posedge clk or negedge rst_n) begin
//    if (!rst_n)
//        count_start <= 1'b0;
//   else if ((ad_ch1_pre < gate) && (ad_ch1 >= gate)) 
//        count_start <= 1'b1;
//   else if ((ad_ch2_pre < gate) && (ad_ch2 >= gate)) 
//        count_start <= 1'b1;
//   else if ((ad_ch3_pre < gate) && (ad_ch3 >= gate)) 
//        count_start <= 1'b1;   
//   else if ((ad_ch4_pre < gate) && (ad_ch4 >= gate)) 
//        count_start <= 1'b1;   
//   else if ((ad_ch5_pre < gate) && (ad_ch5 >= gate)) 
//        count_start <= 1'b1;
//   else if ((ad_ch6_pre < gate) && (ad_ch6 >= gate)) 
//        count_start <= 1'b1;
//   else if ((ad_ch7_pre < gate) && (ad_ch7 >= gate)) 
//         count_start <= 1'b1;
//   else if ((ad_ch8_pre < gate) && (ad_ch8 >= gate)) 
//         count_start <= 1'b1;                    
//   else if (delay_timmer >= delay_1s)
//         count_start <= 1'b0;
//   else
//        count_start <= count_start;
//end


// always @ (posedge clk or negedge rst_n) begin
//    if(!rst_n)
//        delay_timmer <= 32'd0;
//    else if (count_start)
//            delay_timmer <= delay_timmer + 1'b1;
//    else if (delay_timmer >= delay_1s)
//            delay_timmer <= 32'd0;
           
// end


//always @ (posedge clk or negedge rst_n) begin
//     if(!rst_n)
//         ad_sample_valid <= 1'b1;             //常态应该是正常采样
//    else if ((delay_timmer >= delay_1ms) && (delay_timmer <= delay_1s)) 
//         ad_sample_valid <= 1'b0;
//     else
//         ad_sample_valid <= 1'b1; 
// end






