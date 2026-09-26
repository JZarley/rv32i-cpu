read_liberty /home/zarleyjh/STA-Foundations/lib/NangateOpenCellLibrary_typical.lib
read_verilog results/synth_rv32i_core_mapped_timing.v

link_design rv32i_core

create_clock -name clk -period 10.0 [get_ports clk]

set_input_delay 0.0 -clock clk [get_ports imem_rdata]
set_input_delay 0.0 -clock clk [get_ports dmem_rdata]

set_output_delay 0.0 -clock clk [get_ports imem_addr]
set_output_delay 0.0 -clock clk [get_ports dmem_addr]
set_output_delay 0.0 -clock clk [get_ports dmem_wdata]
set_output_delay 0.0 -clock clk [get_ports dmem_wstrb]

report_checks \
    -path_delay max \
    -from [all_registers] \
    -to [all_registers] \
    -group_count 20 \
    -fields {slew cap input_pin}
report_checks \
    -path_delay max \
    -through [get_cells -hierarchical *alu*] \
    -group_count 10 \
    -fields {slew cap input_pin}
report_checks \
    -path_delay max \
    -through [get_cells -hierarchical *branch_compare*] \
    -group_count 10 \
    -fields {slew cap input_pin}
report_worst_slack