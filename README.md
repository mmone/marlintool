# marlintool

This script sets up the build environment, collects dependencies and provides commands for building and uploading Marlin from the commandline. It uses the official Arduino toolchain. Everything is standalone nothing is installed outside the marlintool directory.

### Build configuration

**Before first use: Rename the [marlintool.params.example](marlintool.params.example) file to "marlintool.params"**

In its default configuration the script is setup to build the official [Marlin firmware](https://github.com/MarlinFirmware/Marlin) but can be easily reconfigured to build any Marlin fork/variant.

Several additional in the "*marlintool.params*" file allow to adapt the script to your needs.

| parameter	                  | description  |
| --------------------------- | ------------ |
| **marlinRepositoryUrl**     | The marlin git repository. |
| **marlinRepositoryBranch**  | The branch of the configured repo to use. |
| **marlinDependencies**      | A list of dependencies to download in the format:<br> [name],[repo url],\[library directory](optional).<br>A library directory should only be specified if the library is not in the root of the repository. |
| **hardwareDefinitionRepo**  | If you build for the Anet board this downloads the necessary hardware definition for the Arduino build environment. If you dont need this set it to an empty string. |
| **boardString**             | The Anet board identifier. |
| **arduinoToolchainVersion** | The Arduino toolchain version to use. The build platform and architecture are auto detected. At the moment Linux 32 Bit, 64 Bit, ARM and OS X are supported. |
| **port**                    | The serialport to use for uploading. |
| **arduinoDir**              | Where to put the Arduino toolchain. |
| **marlinDir**               | Where to checkout Marlin sources.
| **buildDir**                | The build directory. |


*Reminder: If you are running octopi on you Raspberry you need to disconnect it from your printer before uploading, otherwise the serial port is blocked.*

*Note: On OS X due to how the Arduino toolchain is packaged the Arduino splash screen will be displayed even when the toolchain is used from the commandline. This will cause the terminal window you launch marlintool from to lose focus. It also means that a build cannot be launched from a remote ssh session.*

### Building for Anet Hardware

If you are building the firmware for the Anet A6/A8 you can find suitable example configurations in the Marlin sources at: [github.com/MarlinFirmware/Marlin/tree/1.1.x/Marlin/example_configurations/Anet](https://github.com/MarlinFirmware/Marlin/tree/1.1.x/Marlin/example_configurations/Anet). Just replace the "Configuration.h" and "Configuration_adv.h" in the marlin directory with the files your find there for a good starting point of your configuration.


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
