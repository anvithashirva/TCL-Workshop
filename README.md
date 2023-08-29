# TCL-Workshop
In this workshop, the design details provided in an excel sheet is processed using TCL scripts to obtain the timing details after synthesis.

![introduction](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/00b39247-84fc-4572-bb13-b0d98cc3e581)

DAY ONE
- Understand the problem statement.
- Create "vsdsynth" command to pass the "Comma Separated Variables (CSV)" input file to the TCL script.

![create_command](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/e9fda19a-3b6b-46e5-9f38-4d9e533a8d2e)

![create_command_o](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/a7ee52a5-267f-43d4-bd7f-197cb3864832)

DAY TWO
- Process design details in CSV file by storing the paths for verilog files, libraries and timing constraints in variables. These variables will be used to refer to these paths in the TCL script. 
- Variables are created by converting CSV file to matrix.

![variable_and_value](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/2f45df54-deea-47e2-a687-88878f7d09d0)

- Checking if the files and directories present in the CSV file exist.

![existance](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/d73e4afb-11be-4fa4-aaba-6db6eabe9f6e)

- Read the constraints present in CSV file and convert it into Synopsys Design Constraints (SDC) format.
  - Step 1: Convert the CSV file containting the timing constraints to a matrix
    
![constraints_csv](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/1c158f04-e8a1-45c0-affe-cc5e4324e8a8)

  - Step 2: Determine the number of rows and columns of the matrix.
  - Step 3: Search for clocks, input ports, and output ports, and determine their row number in the matrix.

![row_numbers](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/0a8dc705-cd97-4add-a5e1-b2cb3aaea5ac)

DAY THREE

  - Step 4: Processing of clock constraints by determining the column number of each clock constraint, loop through the clock ports and write the constraints in SDC format.
    
![clock_sdc](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/d69c8971-dd17-4624-9836-1644cda13743)

  - Step 5: Processing of input constraints by determining the column number of each input constraint, loop through all the input ports, identify input ports with single bit and multiple bits, and write the constraints in SDC format.

![input_constraints](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/70b36b09-1854-49ed-bb81-29dbfc9974ef)
  
  - Step 6: Processing of output constraints by determining the column number of each output constraint, loop through all the output ports, identify output ports with single bit and multiple bits, and write the constraints in SDC format.
    
![output_constraints](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/d6fbd9c5-5feb-4602-8ef3-cf1870b9583a)

Processed constraints are present in outdir_openMSP430/openMSP430.sdc file 

DAY FOUR
- Hierarchy Check
  - Before proceeding with synthesis, check if all the modules in the design are included in the top module in the hierarchical order by performing a hierarchy check.
  - Script to check hierarchy is present in outdir_openMSP430/openMSP430.hier.ys.
  - This script is run on Yosys tool. The outputs and errors are redirected to the log file in outdir_openMSP430/openMSP430.hierarchy_check.log.
    
![hier_check](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/3b795a63-a676-450b-b18f-798d3350fb87)
 
DAY FIVE
- Synthesis
  - Script for synthesis to be used by Yosys Tool is created. It is present in outdir_openMSP430/openMSP430.ys.
  - Synthesis is performed using Yosys Tool. The output of synthesis is present in outdir_openMSP430/openMSP430.synth.v. The errors are redirected to the log file in outdir_openMSP430/openMSP430.synthesis.log.
    
![synthe](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/97bb0ace-a9a9-41ad-8b60-e9c2c712d449)

- Output file from synthesis is edited to remove some redundant lines which could hinder the operation of the timimg tool - OpenTimer. The edited output file is present in outdir_openMSP430/openMSP430.final.synth.v.

- Introduction to Procs and using Procs to create openMSP430.conf file. This file contains details about the number of threads,  path for libraries, final synthesis output, spef file, timing details and other commands required to run OpenTimer.
  
- The proc read_sdc.proc is used to convert the timing constraints from SDC format to a format suitable for OpenTimer.
  - Clock port name, clock period, duty cycle, arrival time and slew are derived.
  - Arrival time and slew of the input ports are derived.
  - Required arrival time and load of output ports are derived.
  - Expanding the ports with multiple bits and applying the delay values to them.
  - These details are saved in outdir_openMSP430/openMSP430.timing
    
- Spef file is created in outdir_openMSP430/openMSP430.spef

- Timing results obtained from OpenTimer are present in outdir_openMSP430/openMSP430.results
  
FINAL OUTPUT

![final_output](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/db8d754b-3f9c-459e-b9a1-bbacefd43ae7)
