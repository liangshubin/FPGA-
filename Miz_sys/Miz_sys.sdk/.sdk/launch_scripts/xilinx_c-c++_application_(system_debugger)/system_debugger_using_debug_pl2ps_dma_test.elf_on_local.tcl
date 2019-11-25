connect -url tcp:127.0.0.1:3121
source E:/Shuai666/IP_test/CH22_AXI_DMA_PL2PS_1/Miz_sys/Miz_sys.sdk/system_wrapper_hw_platform_0/ps7_init.tcl
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent JTAG-HS1 210512180081"} -index 0
rst -system
after 3000
targets -set -filter {jtag_cable_name =~ "Digilent JTAG-HS1 210512180081" && level==0} -index 1
fpga -file E:/Shuai666/IP_test/CH22_AXI_DMA_PL2PS_1/Miz_sys/Miz_sys.runs/impl_1/system_wrapper.bit
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent JTAG-HS1 210512180081"} -index 0
loadhw -hw E:/Shuai666/IP_test/CH22_AXI_DMA_PL2PS_1/Miz_sys/Miz_sys.sdk/system_wrapper_hw_platform_0/system.hdf -mem-ranges [list {0x40000000 0xbfffffff}]
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent JTAG-HS1 210512180081"} -index 0
ps7_init
ps7_post_config
configparams force-mem-access 0
bpadd -addr &main
