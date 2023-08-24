#! /bin/env tclsh


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
puts "Printing out the variables and their values"
puts "DesignName = $DesignName"
puts "OutputDirectory = $OutputDirectory"
puts "NetlistDirectory = $NetlistDirectory"
puts "EarlyLibraryPath = $EarlyLibraryPath"
puts "LateLibraryPath = $LateLibraryPath"
puts "ConstraintsFile = $ConstraintsFile"

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
        puts "\nInfo: Netlist directory found in path $NetlistDirectory"
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

#Search for Clocks, Input ports, and Output ports in the matrix..#
set clock_start_row [lindex [lindex [constraints search all CLOCKS] 0] 1]
puts "clock start row = $clock_start_row"

set clock_start_column [lindex [lindex [constraints search all CLOCKS] 0] 0]
puts "clock start column = $clock_start_column"

set input_ports_start [lindex [lindex [constraints search all INPUTS] 0] 1]
puts "inputs ports start = $input_ports_start"

set output_ports_start [lindex [lindex [constraints search all OUTPUTS] 0] 1]
puts "outputs ports start = $output_ports_start"





