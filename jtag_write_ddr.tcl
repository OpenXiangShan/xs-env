puts "workload path:"
puts [lindex $argv 0]
set file_name [lindex $argv 0]
# 初始化 LabTools 系统
if {[catch {open_hw_manager} errmsg]} {
    puts "Error initializing LabTools system: $errmsg"
    exit
} else {
    puts "LabTools system initialized"
}

# 连接到硬件服务器
if {[catch {connect_hw_server} errmsg]} {
    puts "Error connecting to hardware server: $errmsg"
    exit
} else {
    puts "Connected to hardware server"
}

# 打开硬件目标（JTAG 设备）
if {[catch {open_hw_target} errmsg]} {
    puts "Error opening hardware target: $errmsg"
    exit
} else {
    puts "Opened hardware target"
}

# 获取 JTAG 设备句柄
set hw_device [lindex [get_hw_devices] 0]
if {$hw_device eq ""} {
    puts "Error: No hardware device found. Please check the hardware connection."
    exit
} else {
    puts "Hardware device found: $hw_device"
}
puts "Refreshing hardware device..."
refresh_hw_device $hw_device

# 列出所有 AXI 接口
set hw_axi_list [get_hw_axis]
if {[llength $hw_axi_list] == 0} {
    puts "No AXI interfaces found. Please check the hardware design."
    exit
} else {
    puts "Available AXI interfaces:"
    foreach axi $hw_axi_list {
        puts $axi
    }
}

# 获取 AXI 接口句柄
set hw_axi [get_hw_axis hw_axi_1]
if {$hw_axi eq ""} {
    puts "Error: hw_axi_1 not found. Please check the AXI interface configuration."
    exit
} else {
    puts "hw_axi_1 found: $hw_axi"
}

proc write_to_ddr {fn} { 
  puts "Write to DDR: $fn ..."
  set fdata [open $fn r]
  set idx 0
  set total [exec sh -c "wc -l < $fn | awk '{print \$1/2}'"]
  set terminal_width [exec tput cols]
  set progress_bar_length [expr {int($terminal_width * 0.4)}]
  set start_time [clock seconds]

  while {[eof $fdata] != 1} {
    gets $fdata aline
    set AddrString [lindex $aline 0]
    gets $fdata dline
    set DataString [lindex $dline 0]

    if {[string trim $aline] eq "" || [string trim $dline] eq ""} {
      break
    }
    # 获取 DataString 的长度
    set len [expr {[string length $DataString] / 8}]
    # 检查 len 的值是否合理
    set max_len 256;
    if {$len > $max_len} {
        puts "Error: DataString length exceeds maximum allowed length."
        return -code error
    }

    # 使用 len 进行 AXI 写操作
    create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address $AddrString -data $DataString -len $len -burst INCR -type write

    run_hw_axi wr_txn
    delete_hw_axi_txn wr_txn
    # 计算当前进度的百分比
    set percent [expr {int(($idx * 100) / $total) + 1}]
    # 计算已完成的进度条长度
    set completed_length [expr {int(($percent * $progress_bar_length) / 100)}]
    # 构建进度条的 '#' 和空格部分
    set progress [string repeat "#" $completed_length]
    set spaces [string repeat " " [expr {$progress_bar_length - $completed_length}]]

    set end_time [clock seconds]
    set time_diff [expr {$end_time - $start_time}]
    set minutes [expr {$time_diff / 60}]
    set seconds [expr {$time_diff % 60}]
    incr idx
    set progress_bar [format "\r\[%s%s\] %3d%% | %d/%d Total %02d:%02d" $progress $spaces $percent $idx $total $minutes $seconds]
    puts -nonewline $progress_bar
    flush stdout
  }
  close $fdata
  exit
}

if {[catch {[write_to_ddr $file_name]} errmsg]} {
  puts "ErrorMsg: $errmsg"
}
puts "After Error"