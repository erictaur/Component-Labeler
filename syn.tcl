# Setting environment
sh mkdir -p Netlist
sh mkdir -p Report

# Import Design
set DESIGN "ipdc"

read_file -format verilog  "../01_RTL/$DESIGN.v"
current_design [get_designs $DESIGN]
link

source -echo -verbose ./ipdc_dc.sdc
set_max_area 0
# Compile Design
current_design [get_designs ${DESIGN}]

check_design > Report/check_design.txt
check_timing > Report/check_timing.txt
#set high_fanout_net_threshold 0

uniquify
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
# compile
compile_ultra
optimize_netlist -area
compile_ultra -retime -inc

# Report Output
current_design [get_designs ${DESIGN}]
report_timing > "./Report/${DESIGN}_syn.timing"
report_timing -path full -delay max -max_paths 2 -nworst 2 > Design.timing
report_area > "./Report/${DESIGN}_syn.area"

# Output Design
current_design [get_designs ${DESIGN}]

remove_unconnected_ports -blast_buses [get_cells -hierarchical *]
set verilogout_higher_designs_first true
change_names -hierarchy -rule verilog
change_names -hierarchy -rules name_rule
write -format ddc     -hierarchy -output "./Netlist/${DESIGN}_syn.ddc"
write -format verilog -hierarchy -output "./Netlist/${DESIGN}_syn.v"
write_sdf -version 2.1  -context verilog -load_delay cell ./Netlist/${DESIGN}_syn.sdf
write_sdc  ./Netlist/${DESIGN}_syn.sdc -version 1.8

report_timing
report_area
check_design
exit
