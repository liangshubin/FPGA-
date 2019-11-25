connect -url tcp:127.0.0.1:3121
source E:/Shuai666/AX7020_2017/03_demo_src/03_demo_code/02_example_SOC_mz7xa/CH22_AXI_DMA_PL2PS/Miz_sys/Miz_sys.sdk/system_dma_top_hw_platform_0/ps7_init.tcl
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent JTAG-HS1 210512180081"} -index 0
loadhw -hw E:/Shuai666/AX7020_2017/03_demo_src/03_demo_code/02_example_SOC_mz7xa/CH22_AXI_DMA_PL2PS/Miz_sys/Miz_sys.sdk/system_dma_top_hw_platform_0/system.hdf -mem-ranges [list {0x40000000 0xbfffffff}]
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent JTAG-HS1 210512180081"} -index 0
stop
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent JTAG-HS1 210512180081"} -index 0
rst -processor
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent JTAG-HS1 210512180081"} -index 0
dow E:/Shuai666/AX7020_2017/03_demo_src/03_demo_code/02_example_SOC_mz7xa/CH22_AXI_DMA_PL2PS/Miz_sys/Miz_sys.sdk/helloworld/Debug/helloworld.elf
configparams force-mem-access 0
bpadd -addr &main
