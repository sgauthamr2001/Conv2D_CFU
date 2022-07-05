
# Create Project

create_project -force -name digilent_nexys4ddr -part xc7a100t-CSG324-1
set_msg_config -id {Common 17-55} -new_severity {Warning}

# Add Sources

read_verilog {/home/gautham/Desktop/Conv2D_CFU/proj/accel/cfu.v}
read_verilog {/home/gautham/Desktop/Conv2D_CFU/third_party/python/pythondata_cpu_vexriscv/pythondata_cpu_vexriscv/verilog/VexRiscv_dbpl8Cfu.v}
read_verilog {/home/gautham/Desktop/Conv2D_CFU/soc/build/digilent_nexys4ddr.accel/gateware/digilent_nexys4ddr.v}

# Add EDIFs


# Add IPs


# Add constraints

read_xdc digilent_nexys4ddr.xdc
set_property PROCESSING_ORDER EARLY [get_files digilent_nexys4ddr.xdc]

# Add pre-synthesis commands


# Synthesis

synth_design -directive default -top digilent_nexys4ddr -part xc7a100t-CSG324-1

# Synthesis report

report_timing_summary -file digilent_nexys4ddr_timing_synth.rpt
report_utilization -hierarchical -file digilent_nexys4ddr_utilization_hierarchical_synth.rpt
report_utilization -file digilent_nexys4ddr_utilization_synth.rpt

# Optimize design

opt_design -directive default

# Add pre-placement commands


# Placement

place_design -directive default

# Placement report

report_utilization -hierarchical -file digilent_nexys4ddr_utilization_hierarchical_place.rpt
report_utilization -file digilent_nexys4ddr_utilization_place.rpt
report_io -file digilent_nexys4ddr_io.rpt
report_control_sets -verbose -file digilent_nexys4ddr_control_sets.rpt
report_clock_utilization -file digilent_nexys4ddr_clock_utilization.rpt

# Add pre-routing commands


# Routing

route_design -directive default
phys_opt_design -directive default
write_checkpoint -force digilent_nexys4ddr_route.dcp

# Routing report

report_timing_summary -no_header -no_detailed_paths
report_route_status -file digilent_nexys4ddr_route_status.rpt
report_drc -file digilent_nexys4ddr_drc.rpt
report_timing_summary -datasheet -max_paths 10 -file digilent_nexys4ddr_timing.rpt
report_power -file digilent_nexys4ddr_power.rpt

# Bitstream generation

write_bitstream -force digilent_nexys4ddr.bit 

# End

quit