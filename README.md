# marlintool
This is a convenience shell script for setting up a standalone Marlin build environment on Raspberry Pi and Linux in general.



If you are already running [octoprint](https://octopi.octoprint.org/) as a printserver on a Raspberry Pi it is very convenient to also build Marlin on it via ssh. This script sets up the necessary build environment and provides commands for building and uploading from the commandline. It uses the official Arduino toolchain for ARM. Everything is standalone, nothing is installed.

It should also work on Linux in general. If you don’t build on ARM you will need to change the architecture though. Check the parameters at the beginning of the script for that.

The script is setup by default to build the Marlin fork [“Skynet3D”](https://github.com/SkyNet3D/Marlin) for the Anet A8 Prusa clone. If you want to build stock Marlin, change the “marlinRepositoryUrl” parameter respectively. You should also set the parameter “hardwareDefintionDirectory” to an empty string, this prevents the script from trying to copy the board definition that is needed for the A8.

If you are running octopi on you Raspberry you need to disconnect it from your printer before uploading, otherwise the serial port is blocked.




Commandline parameters
=======================
### -s –setup

Download and configure the toolchain and the necessary libraries for building Marlin.

### -m –marlin

	Download Marlin sources.

### -v –verify

	Build without uploading.

### -u –upload

	Build and upload Marlin. If you are running octopi on you Raspberry you need to disconnect it before uploading otherwise the serial port is blocked.

### -b –backupConfig [file]

	Backup the Marlin configuration to the given file.

### -r –restoreConfig [file]

	Put the given configuration into the Marlin directory. Rename to Configuration.h implicitly.”

### -c  –clean

	Cleanup everything. Remove Marlin sources and Arduino toolchain\n\n”

### -p –port [port]

	Set the serialport for uploading the firmware. Overrides the default set in the script.

### -h –help

	Show help.
