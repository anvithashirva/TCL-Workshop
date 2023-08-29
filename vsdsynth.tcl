#! /bin/env tclsh

set enable_prelayout_timing 1


#Variable creation for the design details present in the .csv file#

puts "Info: Automated variable creation"
set filename [lindex $argv 0]
package require csv
package require struct::matrix
struct::matrix m
set f [open $filename]
csv::read2matrix $f m , auto
close $f
set num_columns [m columns]
set num_rows [m rows]
puts "number of columns $num_columns"
puts "number of rows $num_rows"
m link arr
set i 0
while {$i < $num_rows} {
	puts "\nInfo: setting $arr(0,$i) as $arr(1,$i)"
	if {$i == 0} {
		set [string map {" " ""} $arr(0,$i)] $arr(1,$i)
	} else {
		set [string map {" " ""} $arr(0,$i)] [file normalize $arr(1,$i)]
	}
	set i [expr {$i+1}]
}
puts "\nPrinting out the variables and their values"
puts "\nDesignName = $DesignName"
puts "\nOutputDirectory = $OutputDirectory"
puts "\nNetlistDirectory = $NetlistDirectory"
puts "\nEarlyLibraryPath = $EarlyLibraryPath"
puts "\nLateLibraryPath = $LateLibraryPath"
puts "\nConstraintsFile = $ConstraintsFile"

#Checking the presence of files and directories mentioned in the design details CSV file#

if {![file isdirectory $OutputDirectory]} {
	puts "\nInfo: Cannot find output directory at $OutputDirectory. Creating $OutputDirectory"
	file mkdir $OutputDirectory
} else {
	puts "\nInfo: Output directory found in path $OutputDirectory"
}

if {![file isdirectory $NetlistDirectory]} {
        puts "\nError: Cannot netlist directory at $NetlistDirectory. Exiting..."
        exit
} else {
        puts "\nInfo: Verilog files found in path $NetlistDirectory"
}

if {![file exists $EarlyLibraryPath]} {
        puts "\nError: Cannot find early cell library in path $EarlyLibraryPath. Exiting..."
        exit
} else {
        puts "\nInfo: Early cell library found in path $EarlyLibraryPath"
}

if {![file exists $LateLibraryPath]} {
        puts "\nError: Cannot find late cell library in path $LateLibraryPath. Exiting..."
        exit
} else {
        puts "\nInfo: Late cell library found in path $LateLibraryPath"
}

if {![file exists $ConstraintsFile]} {
        puts "\nError: Cannot find constraints file in path $ConstraintsFile. Exiting..."
        exit
} else {
        puts "\nInfo: Constraints File found in path $ConstraintsFile"
}

#Convert constraints present in CSV file to SDC format.#

#Convert CSV to matrix.#

puts "\nInfo: Dumping SDC constraints for $DesignName"
::struct::matrix constraints
set chan [open $ConstraintsFile]
csv::read2matrix $chan constraints , auto
close $chan
set number_of_columns [constraints columns]
puts "number of columns = $number_of_columns"
set number_of_rows [constraints rows]
puts "number of rows = $number_of_rows"

#Search for Clocks, Input ports, and Output ports and determine their row number in the matrix..#
set clock_start_row [lindex [lindex [constraints search all CLOCKS] 0] 1]
puts "clock start row = $clock_start_row"

set clock_start_column [lindex [lindex [constraints search all CLOCKS] 0] 0]
puts "clock start column = $clock_start_column"

set input_ports_start [lindex [lindex [constraints search all INPUTS] 0] 1]
puts "inputs ports start = $input_ports_start"

set output_ports_start [lindex [lindex [constraints search all OUTPUTS] 0] 1]
puts "outputs ports start = $output_ports_start"

#.......Processing Clock constraints............#

# Column number for clock latency constraints #
set clock_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start_row [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_rise_delay] 0] 0]
set clock_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start_row [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_fall_delay] 0] 0]
set clock_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start_row [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_rise_delay] 0] 0]
set clock_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start_row [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_fall_delay] 0] 0]

# Column number for clock transition constraints #
set clock_early_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start_row [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_rise_slew] 0] 0]
set clock_early_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start_row [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_fall_slew] 0] 0]
set clock_late_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start_row [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_rise_slew] 0] 0]
set clock_late_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start_row [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_fall_slew] 0] 0]

# Create the SDC file. write constraints to the file in SDC format. #
set sdc_file [open $OutputDirectory/$DesignName.sdc "w"]
set i [expr {$clock_start_row+1}]
set end_of_ports [expr {$input_ports_start-1}]
puts "\nInfo-SDC: Working on clock constraints.."
while {$i < $end_of_ports} {
	puts "Working on clock [constraints get  cell 0 $i]"

	puts -nonewline $sdc_file "\ncreate_clock -name [constraints get cell 0 $i] -period [constraints get cell 1 $i] -waveform \{0 [expr {[constraints get cell 1 $i]*[constraints get cell 2 $i]/100}]\} \[get_ports [constraints get cell 0 $i]\]"

	puts -nonewline $sdc_file "\nset_clock_transition -rise -min [constraints get cell $clock_early_rise_slew_start $i] \[get_clocks [constraints get  cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -fall -min [constraints get cell $clock_early_fall_slew_start $i] \[get_clocks [constraints get  cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -rise -max [constraints get cell $clock_late_rise_slew_start $i] \[get_clocks [constraints get  cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -fall -max [constraints get cell $clock_late_fall_slew_start $i] \[get_clocks [constraints get  cell 0 $i]\]"

	puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [constraints get cell $clock_early_rise_delay_start $i] \[get_clocks [constraints get  cell 0 $i]\]"
        puts -nonewline $sdc_file "\nset_clock_latency -source -early -fall [constraints get cell $clock_early_fall_delay_start $i] \[get_clocks [constraints get  cell 0 $i]\]"
        puts -nonewline $sdc_file "\nset_clock_latency -source -late -rise [constraints get cell $clock_late_rise_delay_start $i] \[get_clocks [constraints get  cell 0 $i]\]"
        puts -nonewline $sdc_file "\nset_clock_latency -source -late -fall [constraints get cell $clock_late_fall_delay_start $i] \[get_clocks [constraints get  cell 0 $i]\]"

	set i [expr {$i+1}]
}

#....... Processing constraints for input ports........ #
# Column number for input constraints #
set input_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_rise_delay] 0] 0]
set input_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_fall_delay] 0] 0]
set input_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_rise_delay] 0] 0]
set input_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_fall_delay] 0] 0]

set input_early_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_rise_slew] 0] 0]
set input_early_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_fall_slew] 0] 0]
set input_late_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_rise_slew] 0] 0]
set input_late_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_fall_slew] 0] 0]

set related_clock [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] clocks] 0] 0]

# Identifying single bit input ports and multi-bit input ports #
set i [expr {$input_ports_start+1}]
set end_of_ports [expr {$output_ports_start-1}]
puts "\nInfo-SDC: Working on IO constraints"
puts "\nInfo-SDC: Categorizing input ports based on the number of bits"
while {$i < $end_of_ports } { 
	set netlist [glob -dir $NetlistDirectory *.v]
	set tmp_file [open /tmp/1 w]
	foreach f $netlist {
		set fd [open $f]
		while {[gets $fd line] != -1} {
			set pattern1 " [constraints get cell 0 $i];"
			if {[regexp -all -- $pattern1 $line]} {
				set pattern2 [lindex [split $line ";"] 0]
				if {[regexp -all {input} [lindex [split $pattern2 "\S+"] 0]]} {
					set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"
					puts -nonewline $tmp_file "\n[regsub -all {\s+} $s1 " "]"
				}	
			}
		}
		close $fd
	}
	close $tmp_file
	
	# In the above 'foreach loop' Multiple occurance of same port name is stored at /tmp/1.
	# In this block the tmp file is further uniquified and sorted to determine the number
	# of bits in each input port. 
	set tmp_file [open /tmp/1 r]
	set tmp2_file [open /tmp/2 w]
	puts -nonewline $tmp2_file "[join [lsort -unique [split [read $tmp_file] \n] ] \n]"
	close $tmp_file
	close $tmp2_file
	set tmp2_file [open /tmp/2 r]
	set count [llength [read $tmp2_file]]
	if {$count > 2} {
		set inp_ports [concat [constraints get cell 0 $i]*]
	} else {
		set inp_ports [constraints get cell 0 $i]
	}

	puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_early_rise_delay_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -fall -source_latency_included [constraints get cell $input_early_fall_delay_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -rise -source_latency_included [constraints get cell $input_late_rise_delay_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -fall -source_latency_included [constraints get cell $input_late_fall_delay_start $i] \[get_ports $inp_ports\]"

	puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_early_rise_slew_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -fall -source_latency_included [constraints get cell $input_early_fall_slew_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -rise -source_latency_included [constraints get cell $input_late_rise_slew_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -fall -source_latency_included [constraints get cell $input_late_fall_slew_start $i] \[get_ports $inp_ports\]"

	set i [expr {$i+1}]
}
close $tmp2_file

#....... Processing constraints for output ports........ #
# Column number for output constraints #
set output_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] early_rise_delay] 0] 0]
set output_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] early_fall_delay] 0] 0]
set output_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] late_rise_delay] 0] 0]
set output_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] late_fall_delay] 0] 0]

set output_load_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] load] 0] 0]
set related_clock [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] clocks] 0] 0]

# Identifying single bit output ports and multi-bit output ports #
set i [expr {$output_ports_start+1}]
set end_of_ports [expr {$number_of_rows}]
puts "\nInfo-SDC: Working on IO constraints"
puts "\nInfo-SDC: Categorizing output ports based on the number of bits"
while {$i < $end_of_ports} {
        set netlist [glob -dir $NetlistDirectory *.v]
        set tmp_file [open /tmp/1 w]
        foreach f $netlist {
                set fd [open $f]
                while {[gets $fd line] != -1} {
                        set pattern1 " [constraints get cell 0 $i];"
                        if {[regexp -all -- $pattern1 $line]} {
                                set pattern2 [lindex [split $line ";"] 0]
                                if {[regexp -all {output} [lindex [split $pattern2 "\S+"] 0]]} {
                                        set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"
					puts -nonewline $tmp_file "\n[regsub -all {\s+} $s1 " "]"
                                }
                        }
                }
                close $fd
        }
        close $tmp_file

        # In the above 'foreach loop' Multiple occurance of same port name is stored at /tmp/1.
        # In this block the tmp file is further uniquified and sorted to determine the number
        # of bits in each output port. 
        set tmp_file [open /tmp/1 r]
        set tmp2_file [open /tmp/2 w]
        puts -nonewline $tmp2_file "[join [lsort -unique [split [read $tmp_file] \n] ] \n]"
        close $tmp_file
        close $tmp2_file
        set tmp2_file [open /tmp/2 r]
        set count [llength [read $tmp2_file]]
        if {$count > 2} {
                set op_ports [concat [constraints get cell 0 $i]*]
        } else {
                set op_ports [constraints get cell 0 $i]
        }
	
	puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $output_early_rise_delay_start $i] \[get_ports $op_ports\]"
        puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -fall -source_latency_included [constraints get cell $output_early_fall_delay_start $i] \[get_ports $op_ports\]"
        puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -rise -source_latency_included [constraints get cell $output_late_rise_delay_start $i] \[get_ports $op_ports\]"
        puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -fall -source_latency_included [constraints get cell $output_late_fall_delay_start $i] \[get_ports $op_ports\]"

	puts -nonewline $sdc_file "\nset_load [constraints get cell $output_load_start $i] \[get_ports $op_ports\]"

        set i [expr {$i+1}]
}
close $tmp2_file
close $sdc_file

puts "SDC file created in path $OutputDirectory/$DesignName.sdc"

#...........Hierarchy Check...................#

#..Test to check if the all the modules are 
# connected hierarchically in the top module

puts "\nInfo: Creating hierarchy check script to be used by yosys" 
set data "read_liberty -lib -ignore_miss_dir -setattr blackbox ${LateLibraryPath}"
set filename "$DesignName.hier.ys"
set fileId [open $OutputDirectory/$filename "w"]
puts -nonewline $fileId $data
set netlist [glob -dir $NetlistDirectory *.v]
foreach f $netlist {
	set data $f
	puts -nonewline $fileId "\nread_verilog $f"
}
puts -nonewline $fileId "\nhierarchy -check"
close $fileId
puts "\nclose \"$OutputDirectory/$filename\""
puts "\nChecking Hierarchy"

if {[catch { exec yosys -s $OutputDirectory/$DesignName.hier.ys >& $OutputDirectory/$DesignName.hierarchy_check.log} msg]} {
	set filename "$OutputDirectory/$DesignName.hierarchy_check.log"
	set pattern {referenced in module}
	set count 0
	set fid [open $filename r]
	while {[gets $fid line] != -1} {
		incr count [regexp -all -- $pattern $line]
		if {[regexp -all -- $pattern $line]} {
			puts "\nError: module [lindex $line 2] is not part of the design $DesignName. Please use corrrect RTL in path '$NetlistDirectory'"
			puts "\nError: Hierarchy check FAIL"
		}
	}
	close $fid
} else {
	puts "\nInfo: Hierarchy check PASS" 
}

puts "\nInfo: Please find hierarchy check details in [file normalize $OutputDirectory/$DesignName.hierarchy_check.log] for more information"

#.......Script for Synthesis......#
puts "\nInfo: Creating synthesis script to be used by yosys"
set data "read_liberty -lib -ignore_miss_dir -setattr blackbox ${LateLibraryPath}"
set filename "$DesignName.ys"
set fileId [open $OutputDirectory/$filename "w"]
puts -nonewline $fileId $data
set netlist [glob -dir $NetlistDirectory *.v]
foreach f $netlist {
        set data $f
        puts -nonewline $fileId "\nread_verilog $f"
}
puts -nonewline $fileId "\nhierarchy -top $DesignName"
puts -nonewline $fileId "\nsynth -top $DesignName"
puts -nonewline $fileId "\nsplitnets -ports -format ___\ndfflibmap -liberty ${LateLibraryPath}\nopt"
puts -nonewline $fileId "\nabc -liberty ${LateLibraryPath}"
puts -nonewline $fileId "\nflatten"
puts -nonewline $fileId "\nclean -purge\niopadmap -outpad BUFX2 A:Y -bits\nopt\nclean"
puts -nonewline $fileId "\nwrite_verilog $OutputDirectory/$DesignName.synth.v"
close $fileId
puts "\nInfo: Synthesis script created and can be accessed from path $OutputDirectory/$DesignName.ys"
puts "\nInfo: Running synthesis"

# Execute the synthesis script on the tool Yosys

if {[catch { exec yosys -s $OutputDirectory/$DesignName.ys >& $OutputDirectory/$DesignName.synthesis.log} msg]} {
	puts "\nError: Synthesis failed due to errors. Please refer to log $OutputDirectory/$DesignName.synthesis.log for errors."
	exit
} else {
        puts "\nInfo: Synthesis is successful."
}

puts "\nInfo: Please refer to log $OutputDirectory/$DesignName.synthesis.log for more information"

#.... Edit the output file of synthesis and pass it to the timing tool...#
set fileId [open /tmp/1 "w"]
puts -nonewline $fileId [exec grep -v -w "*" $OutputDirectory/$DesignName.synth.v]
close $fileId
set output [open $OutputDirectory/$DesignName.final.synth.v "w"]
set filename "/tmp/1"
set fid [open $filename r]
while {[gets $fid line] != -1} {
	puts -nonewline $output [string map {"\\" ""} $line]
	puts -nonewline $output "\n"
}
close $fid
close $output
puts "\nInfo: Please find the synthesised netlist for $DesignName at $OutputDirectory/$DesignName.final.synth.v"

#..........STATIC TIMING ANALYSIS using Opentimer..........#

puts "\nInfo: Timing analysis started"
puts "\nInfo: Initialising number of threads, libraries, sdc, verilog netlist path...."

source /home/vsduser/vsdsynth/procs/reopenStdout.proc
source /home/vsduser/vsdsynth/procs/set_num_threads.proc

reopenStdout $OutputDirectory/$DesignName.conf
set_multi_cpu_usage -localCpu 4

source /home/vsduser/vsdsynth/procs/read_lib.proc
read_lib -early /home/vsduser/vsdsynth/osu018_stdcells.lib
read_lib -late /home/vsduser/vsdsynth/osu018_stdcells.lib

source /home/vsduser/vsdsynth/procs/read_verilog.proc
read_verilog $OutputDirectory/$DesignName.final.synth.v

source /home/vsduser/vsdsynth/procs/read_sdc.proc
read_sdc $OutputDirectory/$DesignName.sdc

reopenStdout /dev/tty

#...CONF file creation..#
# Conf file consists of the path for verilog netlist and library.
# It is given to the Opentimer tool to perform STA

if {$enable_prelayout_timing == 1} {
	puts "\nInfo: enable_prelayout_timing is $enable_prelayout_timing. Enabling zero-wire load parasitics"
	set spef_file [open $OutputDirectory/$DesignName.spef w]
	
	puts $spef_file "*SPEF \"IEEE 1481-1998\" "
	puts $spef_file "*DESIGN \"$DesignName\" "
	puts $spef_file "*DATE \"Tue Sep 25 11:51:50 2012\" "
	puts $spef_file "*VENDOR \"TAU 2015 Contest\" "
	puts $spef_file "*PROGRAM \"Benchmark Parasitic Generator\" "
	puts $spef_file "*VERSION \"0.0\" "
	puts $spef_file "*DESIGN_FLOW \"NETLIST_TYPE_VERILOG\" "
	puts $spef_file "*DIVIDER / "
	puts $spef_file "*DELIMITER : "
	puts $spef_file "*BUS_DELIMITER [ ] "
	puts $spef_file "*T_UNIT 1 PS "
	puts $spef_file "*C_UNIT 1 FF "
	puts $spef_file "*R_UNIT 1 KOHM "
	puts $spef_file "*L_UNIT 1 UH "
}
close $spef_file

set conf_file [open $OutputDirectory/$DesignName.conf a]
puts $conf_file "set_spef_fpath $OutputDirectory/$DesignName.spef"
puts $conf_file "init_timer "
puts $conf_file "report_timer "
puts $conf_file "report_wns "
puts $conf_file "report_worst_paths -numPaths 10000 "

close $conf_file

# Quality of Results generation algorithm using Opentimer

# Evaluation of RUNTIME 

set time_elasped_in_us [time {exec /home/vsduser/OpenTimer-1.0.5/bin/OpenTimer < $OutputDirectory/$DesignName.conf >& $OutputDirectory/$DesignName.results}]
set time_elasped_in_sec "[expr {[lindex $time_elasped_in_us 0]/100000}]"
puts "\nInfo: STA finished in $time_elasped_in_sec seconds"
puts "\nInfo: Refer to $OutputDirectory/$DesignName.results for warnings and errors"

# Worst Negative Slack for output timing (WNS RAT)

set worst_RAT_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {RAT}
while {[gets $report_file line] != -1} {
	if {[regexp $pattern $line]} {
	       set worst_RAT_slack "[expr {[lindex $line 3]/1000}]"
	       puts "WNS RAT is $worst_RAT_slack ns"
	       break
	} else {
	    continue
	}
}
close $report_file

# Failing endpoints of RAT (FEP RAT) - number of output violations

set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $report_file line] != -1} {
	incr count [regexp -all -- $pattern $line] 
}

set Number_output_violations $count
puts "FEP RAT is $Number_output_violations"
close $report_file

# Worst Negative Slack for setup (WNS Setup)

set worst_negative_setup_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {Setup}
while {[gets $report_file line] != -1} {
        if {[regexp $pattern $line]} {
               set worst_negative_setup_slack "[expr {[lindex $line 3]/1000}]"
               puts "WNS Setup is $worst_negative_setup_slack ns"
               break
        } else {
            continue
        }
}
close $report_file

# Failing endpoints of setup (FEP SEtup) - number of setup violations

set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $report_file line] != -1} {
        incr count [regexp -all -- $pattern $line]
}
set Number_of_setup_violations $count
puts "FEP setup is $Number_of_setup_violations"
close $report_file

# Worst Negative Slack for hold (WNS Hold)

set worst_negative_hold_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {Hold}
while {[gets $report_file line] != -1} {
        if {[regexp $pattern $line]} {
               set worst_negative_hold_slack "[expr {[lindex $line 3]/1000}]"
               puts "WNS Hold is $worst_negative_hold_slack ns"
               break
        } else {
            continue
        }
}
close $report_file

# Failing endpoints of hold (FEP Hold) - number of hold violations

set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $report_file line] != -1} {
        incr count [regexp -all -- $pattern $line]
}
set Number_of_hold_violations $count
puts "FEP hold is $Number_of_hold_violations"
close $report_file

# ... Number of instance ...
set pattern {Num of gates}
set report_file [open $OutputDirectory/$DesignName.results r]
while {[gets $report_file line] != -1} {
        if {[regexp -all -- $pattern $line]} {
               set Instance_count [lindex [join $line " "] 4]
               puts "Instance count is $Instance_count"
               break
        } else {
            continue
        }
}
close $report_file

puts "\n"

# Report Formatting 
puts "                                                   **** PRELAYOUT TIMING RESULTS **** "
set formatStr {%15s%15s%15s%15s%15s%15s%15s%15s%15s}
puts [format $formatStr "-----------" "-------" "--------------" "------------" "---------" "----------" "--------" "----------" "-------"]
puts [format $formatStr "Design Name" "Runtime" "Instance Count" "WNS Setup" "FEP Setup" "WNS Hold" "FEP Hold" "WNS RAT" "FEP RAT"]
puts [format $formatStr "-----------" "-------" "--------------" "------------" "---------" "----------" "--------" "----------" "-------"]

foreach design_name $DesignName run_time $time_elasped_in_sec instance_count $Instance_count wns_setup $worst_negative_setup_slack fep_setup $Number_of_setup_violations wns_hold $worst_negative_hold_slack fep_hold $Number_of_hold_violations wns_rat $worst_RAT_slack fep_rat $Number_output_violations {
	puts [format $formatStr $design_name $run_time $instance_count $wns_setup $fep_setup $wns_hold $fep_hold $wns_rat $fep_rat]
}

puts [format $formatStr "-----------" "-------" "--------------" "------------" "---------" "----------" "--------" "----------" "-------"]
puts "\n"







