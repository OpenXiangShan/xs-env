puts "probe .ltx path:"
puts [lindex $argv 0]
set file_name [lindex $argv 0]

if {![file exists $file_name]} {
    puts "ERROR: .ltx file not found: $file_name"
    exit 1
}

open_hw_manager
connect_hw_server
open_hw_target

current_hw_device [get_hw_devices *]

# load .ltx file
set_property PROBES.FILE $file_name [current_hw_device]

refresh_hw_device [current_hw_device]
refresh_hw_vio hw_vio_1

puts [get_hw_probes -of_objects [get_hw_vios hw_vio_1]]
# vio_sw4 0
set_property OUTPUT_VALUE 0 [get_hw_probes vio_sw4 -of_objects [get_hw_vios hw_vio_1]]
commit_hw_vio [get_hw_probes {vio_sw4} -of_objects [get_hw_vios hw_vio_1]]
puts [get_property OUTPUT_VALUE [get_hw_probes -of_objects [get_hw_vios hw_vio_1]]]
# vio_sw4 1
set_property OUTPUT_VALUE 1 [get_hw_probes vio_sw4 -of_objects [get_hw_vios hw_vio_1]]
commit_hw_vio [get_hw_probes {vio_sw4} -of_objects [get_hw_vios hw_vio_1]]
puts [get_property OUTPUT_VALUE [get_hw_probes -of_objects [get_hw_vios hw_vio_1]]]
# vio_sw6 0
set_property OUTPUT_VALUE 0 [get_hw_probes vio_sw6 -of_objects [get_hw_vios hw_vio_1]]
commit_hw_vio [get_hw_probes {vio_sw6} -of_objects [get_hw_vios hw_vio_1]]
puts [get_property OUTPUT_VALUE [get_hw_probes -of_objects [get_hw_vios hw_vio_1]]]
exit