read_liberty $::env(LIBERTY)
read_verilog $::env(NETLIST)
link_design $::env(TOP)

create_clock -name clk -period 10.0 [get_ports clk]
set_input_delay 0.0 -clock clk [get_ports imem_rdata]
set_input_delay $::env(DMEM_DELAY) -clock clk [get_ports dmem_rdata]
set_output_delay 0.0 -clock clk [get_ports imem_addr]
set_output_delay 0.0 -clock clk [get_ports dmem_addr]
set_output_delay 0.0 -clock clk [get_ports dmem_wdata]
set_output_delay 0.0 -clock clk [get_ports dmem_wstrb]

puts "=== DESIGN: $::env(TOP); DMEM_DELAY=$::env(DMEM_DELAY) ns ==="
puts "=== REGISTER TO REGISTER ==="
report_checks -path_delay max -from [all_registers] -to [all_registers] -group_count 5 -fields {slew cap input_pin}
puts "=== DMEM INPUT TO REGISTERS ==="
report_checks -path_delay max -from [get_ports dmem_rdata] -to [all_registers] -group_count 5 -fields {slew cap input_pin}
puts "=== WORST SLACK ==="
report_worst_slack