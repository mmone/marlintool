# marlintool

This script sets up the build environment, collects dependencies and provides commands for building and uploading Marlin from the commandline. It uses the official Arduino toolchain. Everything is standalone nothing is installed outside the marlintool directory.

The script is setup by default to build the 1.1.x branch of the official Marlin [“Marlin”](https://github.com/MarlinFirmware/Marlin) but can be easily reconfigured to build any Marlin variant.
Just change the "marlinRepositoryUrl" and "marlinRepositoryBranch" parameters at the beginning of the script to the respective github repository.

After downloading Marlin the example configuration files for the Anet A8 are copied in the marlin directory. Just change the "printer" parameter at the beginning of the script to have the appropriate example configuration files for your printer copied instead.


Several parameters at the beginning of the script allow to adapt the script further to your needs.

- If you do not need additional hardware/board definitions because you use the ones that come with the toolchain set the parameter “hardwareDefinitionRepo” to an empty string. This prevents the script from fetching the board definition that is needed for the A8 from github.

- If you need additional libraries for your build add them to the "getDependencies" function.

- The build platform architecture is auto detected. At the moment Linux 32 Bit, 64 Bit and ARM are supported.

Reminder: If you are running octopi on you Raspberry you need to disconnect it from your printer before uploading, otherwise the serial port is blocked.



Available commandline parameters
=======================
### -s --setup

	Download and configure the toolchain and the necessary libraries for building Marlin.
	Also fetches the Anet board hardware definition from github if specified.

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
