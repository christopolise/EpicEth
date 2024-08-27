connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent Basys3 210183B037D8A" && level==0 && jtag_device_ctx=="jsn-Basys3-210183B037D8A-0362d093-0"}
fpga -file epic_eth_wrapper_final.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw ETH_WRAPPER_6.xsa -regs # I think it's only used for debugging
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
dow ETH_TEST.elf
bpadd -addr &main
con