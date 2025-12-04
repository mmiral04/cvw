#set partNumber $::env(XILINX_PART)
#set boardName $::env(XILINX_BOARD)

set partNumber xc7a100tcsg324-1
set boardName digilentinc.com:arty-a7-100:part0:1.1

set ipName xlnx_axi_dma

create_project $ipName . -force -part $partNumber
set_property board_part $boardName [current_project]
create_ip -name axi_dma -vendor xilinx.com -library ip -version 7.1 -module_name $ipName

set_property -dict [list CONFIG.c_include_sg {0} \
                        CONFIG.c_m_axi_mm2s_data_width {64} \
                        CONFIG.c_m_axi_s2mm_data_width {64}] [get_ips $ipName]

generate_target {instantiation_template} [get_files ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
generate_target all [get_files  ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1
