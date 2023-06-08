


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