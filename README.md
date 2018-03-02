# marlintool

This script sets up the build environment, collects dependencies and provides commands for building and uploading Marlin from the commandline. It uses the official Arduino toolchain. Everything is standalone nothing is installed outside the marlintool directory.

The script is setup by default to build the Marlin firmware [“Marlin”](https://github.com/MarlinFirmware/Marlin) but can be easily reconfigured to build any Marlin variant.
Just change the "marlinRepositoryUrl" parameter at the beginning of the script to the respective github repository.

If you are building the firmware for the Anet A6/A8 you can find suitable example configurations in the Marlin sources at: [github.com/MarlinFirmware/Marlin/tree/1.1.x/Marlin/example_configurations/Anet](https://github.com/MarlinFirmware/Marlin/tree/1.1.x/Marlin/example_configurations/Anet). Just replace the "Configuration.h" and "Configuration_adv.h" in the marlin directory with the files your find there for a good starting point of your configuration.

The script also downloads the necessary hardware/board definitions for the Anet hardware. If you do not need those because you use the ones that come with the toolchain, set the parameter “hardwareDefinitionRepo” to an empty string. This prevents the script from fetching the board definitions from github.


Several parameters at the beginning of the script allow to adapt the script further to your needs.

- If you would like to use a specific branch of a repository set the parameter "marlinRepositoryBranch" to the name of the branch.

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
