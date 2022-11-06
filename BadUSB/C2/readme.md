Step 1 - Configurations

Switch the board into TF mode. Drop your payload file (executable or script) on the board. Specify the payload file name in the "filename" config file. Drop in any additional script file and specify the script file name in the "script" config file. Finally specify the CLI commands in the "command" config file.

Step 2 - Generate the HID payload

Run the hidpayload.py script to generate the HID payload file named "Payload". Optinally specify the "filename", "command" and "script" arguments to override the config file settings in the following format:

	hidpayload.py <payload filename> <command to execute> <script filename>

Put in dummy value to skip an argument. Config files will be used if no argument is specified.

Step 3 - Execute the HID payload

Switch the board to "ON". Press Button 1 on the board to execute.

Press Button 2 to reset the system.
