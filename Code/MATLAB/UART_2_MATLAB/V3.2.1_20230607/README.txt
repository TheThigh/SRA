



V3.2.1_20230607 - Release Notes

1. The warning for the human data has not been recorded issue now has been successfully added into the readSerialdata function of human, this time the tic and toc functions 
will not affect the efficiency of the procedure, but its function remains to be verified in the future. And in the next version, the controller will be added depending on 
the completeness of the dynamcis.



V3.2.0_20230607 - Release Notes

1. The communication between Arduino board and PC has been successfully set up. In last version (V3.1.2), though there was not ant official update note, the communication 
rate between the two was not so promising due to improper dealing with char or string input (it's none of business of functions in Arduino board). In this version, this 
problem has been solved.

2. Due to the expression of different types of controllers, the force or torque is determined by the state variables of both human and arm, the angles and angular velocities 
for both of them, and only angular accelerations for the human. Now in this version, all the state variables have been well prepared and filtered. Users can still choose 
to activate "perfect" or "authentic" mode for data plot.

3. For the compactness and brevity of the code, some of the repeated used sentences or lines of code were begun to be nested in specific functions. However, for some reasons, 
the data reading for Arduino board sometimes failed, so we need an indication in the command window in MATLAB to tell the users the data for human will not be recorded so 
that users can decide to terminate the procedure and start a new one or continue. In the original design, we will leave 20 s for the system to respond, but using tic and toc 
functions will aggravate the burden of CPU and post data processing, anyway, this function will be developed in the next version.

4. The name of the main function has been changed from "ESP2MATLAB" to "UART_2_MATLAB" because now the communication of MATLAB and Arduino has been finished.




V3.1.1_20230412 - Release Notes

1. To avoid the issue that when connecting the devices on the same PC (mac address), some of them are totally new to the PC, and some of devices were plugged out from
the PC compared to the previous experiment, so when being assigned with specific port, the vacant position reserved for devices used in previous experiment will be 
occupied and overwritten by the new ones, we established a new sub-struct under global variable *system*, which is called *system.devices.history*. This variable will 
store all the device connection information (the port number) for the same PC so that any changes subsequently will not disturb out settings.
However, there are still some ignorable issues that the Arduino board information will be displayed repeatedly in the history device connection list, it doesn't affect 
the utilization of the code, and it will be fixed in the next version.

2. Currently, there are only two IMUs mounted on the SRA body (more specifically, the end effector), in the future, there will be another two mounted on the middle of 
the SRA on each side respectively, any missing connection will affect the utilization of *configureCallback* function, temporarily this can be solved by using *try-catch* 
sentence, it will be fixed in the near future as well.

3. The extension cable (25 ft) will not affect the data sending and reading no matter for IMUs (or ESP32s) or Arduino board, and there are no port assigning issues for 
*USB Bus* either.