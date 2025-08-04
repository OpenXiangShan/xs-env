puts "Bitstream folder path:"
puts [lindex $argv 0]
set bitdir [lindex $argv 0]

if {![file exists $bitdir]} {
    puts "ERROR: Bitstream folder not found: $bitdir"
    exit 1
}

set bit_file [glob -nocomplain -directory $bitdir *.bit]
set ltx_file [glob -nocomplain -directory $bitdir *.ltx]

if { $bit_file eq "" } {
    puts "ERROR: No .bit file found in $bitdir"
    exit 1
}
if { $ltx_file eq "" } {
    puts "ERROR: No .ltx file found in $bitdir"
    exit 1
}

puts "Found bitstream: $bit_file"
puts "Found ltx: $ltx_file"

open_hw_manager
connect_hw_server
open_hw_target

current_hw_device [get_hw_devices *]
refresh_hw_device [current_hw_device]

set_property PROGRAM.FILE $bit_file [current_hw_device]
set_property PROBES.FILE $ltx_file [current_hw_device]
puts "Programming FPGA, this make take more than 10 minutes..."
program_hw_devices [current_hw_device]

puts "FPGA programmed successfully."
exit