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
- Processed the clock constraints to openMSP430.sdc file following the SDC format
- Processed the input port constraints to openMSP430.sdc file following the SDC format

DAY FIVE
- Final output is displayed here
![final_output](https://github.com/anvithashirva/TCL-Workshop/assets/130870681/db8d754b-3f9c-459e-b9a1-bbacefd43ae7)
