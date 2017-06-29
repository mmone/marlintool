# marlintool

This script sets up the build environment collects dependencies and provides commands for building and uploading Marlin from the commandline. It uses the official Arduino toolchain. Everything is standalone, nothing is installed.

The script is setup by default to build the Marlin fork [“Skynet3D”](https://github.com/SkyNet3D/Marlin) for the Anet A8 Prusa clone on a Raspberry Pi.

Several parameters at the beginning of the script allow to configure it for different targets.

- If you would like to build stock Marlin, change the “marlinRepositoryUrl” parameter respectively.

- If you dont need additional hardware/board definitions because you can use the ones that come with the toolchain set the parameter “hardwareDefintionDirectory” to an empty string. This prevents the script from trying to copy the board definition that is needed for the A8.

- If you need additional libraries for your build add them to the "getDependencies" function.

- The build platform architecture is autodetected. At the moment Linux 32 Bit, 64 Bit and ARM are supported.

Reminder: If you are running octopi on you Raspberry you need to disconnect it from your printer before uploading, otherwise the serial port is blocked.



Available commandline parameters
=======================
### -s --setup

	Download and configure the toolchain and the necessary libraries for building Marlin.

### -m --marlin

	Download Marlin sources.

### -f  --fetch
	Update an existing Marlin clone.

### -v --verify

	Build without uploading.

### -u --upload

	Build and upload Marlin. If you are running octopi on you Raspberry
	you need to disconnect it before uploading otherwise the serial port is blocked.

### -b --backupConfig [name]

	Backup the Marlin configuration to the named backup.


### -r --restoreConfig [name]

	Restore the given configuration into the Marlin directory.

### -c --clean

	Cleanup everything. Remove Marlin sources and Arduino toolchain.

### -p --port [port]

	Set the serialport for uploading the firmware. Overrides the default set in the script.

### -h --help

	Show help.
