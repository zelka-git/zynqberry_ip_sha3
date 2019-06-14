connect -url tcp:127.0.0.1:3121
source /home/anzhelika/projekt/diplom/debug_progectv5/debug_sha3/debug_sha3.sdk/diagramm_wrapper_hw_platform_0/ps7_init.tcl
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "JTAG-ONB4 251633000000A"} -index 0
loadhw -hw /home/anzhelika/projekt/diplom/debug_progectv5/debug_sha3/debug_sha3.sdk/diagramm_wrapper_hw_platform_0/system.hdf -mem-ranges [list {0x40000000 0xbfffffff}]
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "JTAG-ONB4 251633000000A"} -index 0
stop
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "JTAG-ONB4 251633000000A"} -index 0
rst -processor
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "JTAG-ONB4 251633000000A"} -index 0
dow /home/anzhelika/projekt/diplom/debug_progectv5/debug_sha3/debug_sha3.sdk/test/Debug/test.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "JTAG-ONB4 251633000000A"} -index 0
con
