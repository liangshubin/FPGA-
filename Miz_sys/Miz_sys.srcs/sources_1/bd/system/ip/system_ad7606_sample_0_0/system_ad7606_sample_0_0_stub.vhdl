-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.4 (win64) Build 2086221 Fri Dec 15 20:55:39 MST 2017
-- Date        : Fri Nov 22 16:48:45 2019
-- Host        : Lab-9999 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               E:/Shuai666/IP_test/glitchfilter_4_4_2gate_dmatimeout/Miz_sys/Miz_sys.srcs/sources_1/bd/system/ip/system_ad7606_sample_0_0/system_ad7606_sample_0_0_stub.vhdl
-- Design      : system_ad7606_sample_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg400-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity system_ad7606_sample_0_0 is
  Port ( 
    adc_clk : in STD_LOGIC;
    adc_rst_n : in STD_LOGIC;
    ad7606_data : in STD_LOGIC_VECTOR ( 15 downto 0 );
    ad7606_busy : in STD_LOGIC;
    ad7606_first_data : in STD_LOGIC;
    ad7606_os : out STD_LOGIC_VECTOR ( 2 downto 0 );
    ad7606_cs : out STD_LOGIC;
    ad7606_rd : out STD_LOGIC;
    ad7606_reset : out STD_LOGIC;
    ad7606_convstab : out STD_LOGIC;
    m00_axis_tdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m00_axis_tkeep : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m00_axis_tlast : out STD_LOGIC;
    m00_axis_tready : in STD_LOGIC;
    m00_axis_tvalid : out STD_LOGIC;
    m00_axis_aresetn : in STD_LOGIC;
    m00_axis_aclk : in STD_LOGIC;
    s00_axi_awaddr : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s00_axi_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s00_axi_awvalid : in STD_LOGIC;
    s00_axi_awready : out STD_LOGIC;
    s00_axi_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s00_axi_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s00_axi_wvalid : in STD_LOGIC;
    s00_axi_wready : out STD_LOGIC;
    s00_axi_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s00_axi_bvalid : out STD_LOGIC;
    s00_axi_bready : in STD_LOGIC;
    s00_axi_araddr : in STD_LOGIC_VECTOR ( 3 downto 0 );
    s00_axi_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    s00_axi_arvalid : in STD_LOGIC;
    s00_axi_arready : out STD_LOGIC;
    s00_axi_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s00_axi_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s00_axi_rvalid : out STD_LOGIC;
    s00_axi_rready : in STD_LOGIC;
    s00_axi_aclk : in STD_LOGIC;
    s00_axi_aresetn : in STD_LOGIC
  );

end system_ad7606_sample_0_0;

architecture stub of system_ad7606_sample_0_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "adc_clk,adc_rst_n,ad7606_data[15:0],ad7606_busy,ad7606_first_data,ad7606_os[2:0],ad7606_cs,ad7606_rd,ad7606_reset,ad7606_convstab,m00_axis_tdata[63:0],m00_axis_tkeep[7:0],m00_axis_tlast,m00_axis_tready,m00_axis_tvalid,m00_axis_aresetn,m00_axis_aclk,s00_axi_awaddr[3:0],s00_axi_awprot[2:0],s00_axi_awvalid,s00_axi_awready,s00_axi_wdata[31:0],s00_axi_wstrb[3:0],s00_axi_wvalid,s00_axi_wready,s00_axi_bresp[1:0],s00_axi_bvalid,s00_axi_bready,s00_axi_araddr[3:0],s00_axi_arprot[2:0],s00_axi_arvalid,s00_axi_arready,s00_axi_rdata[31:0],s00_axi_rresp[1:0],s00_axi_rvalid,s00_axi_rready,s00_axi_aclk,s00_axi_aresetn";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "ad7606_sample_v1_0,Vivado 2017.4";
begin
end;
