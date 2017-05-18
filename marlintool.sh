#!/bin/bash

# Marlin fork optimized for the AnetA8 Prusa clone
marlinRepositoryUrl="https://github.com/SkyNet3D/Marlin"

# Original Marlin
# marlinRepositoryUrl="https://github.com/MarlinFirmware/Marlin"

# Anet board
boardString="anet:avr:anetv1"

# Arduino Mega
# boardString="arduino:avr:mega:cpu=atmega2560"

arduinoToolchainVersion="1.8.2"

# Toolchain architecture
arduinoToolchainArchitecture="linuxarm"
# 32bit
#arduinoToolchainArchitecture="linux32"
# 64bit
#arduinoToolchainArchitecture="linux64"

# Serialport for uploading
port="/dev/ttyUSB0"

# Where to put the arduino toolchain
arduinoDir="./arduino"

# Where to checkout Marlin sources
marlinDir="Marlin"

# Build directory
buildDir="./build"

# The path to additional hardware defnitions for the arduino tool chain
# eg. sanguino boards that live in "/arduino/hardware".
# Set to an empty string if you dont need this.
hardwareDefintionDirectory="./hardware/anet"


## Download the toolchain and unpack it
function getArduinoToolchain
{
   echo -e "\nDownloading Arduino environment ...\n"
   wget http://downloads-02.arduino.cc/arduino-"$arduinoToolchainVersion"-"$arduinoToolchainArchitecture".tar.xz
   mkdir "$arduinoDir"
   echo -e "\nUnpacking Arduino environment. This might take a while ... "
   tar -xf arduino-"$arduinoToolchainVersion"-"$arduinoToolchainArchitecture".tar.xz -C "$arduinoDir" --strip 1
   rm -R arduino-"$arduinoToolchainVersion"-"$arduinoToolchainArchitecture".tar.xz
}


## Get dependencies and move them in place
function getDependencies
{
   echo -e "\nDownloading libraries ...\n"

   git clone https://github.com/kiyoshigawa/LiquidCrystal_I2C.git
   rm -rf "$arduinoDir"/libraries/LiquidCrystal_I2C
   mv -f LiquidCrystal_I2C/LiquidCrystal_I2C "$arduinoDir"/libraries/LiquidCrystal_I2C
   rm -rf LiquidCrystal_I2C

   git clone https://github.com/lincomatic/LiquidTWI2.git
   rm -rf "$arduinoDir"/libraries/LiquidTWI2
   mv -f LiquidTWI2 "$arduinoDir"/libraries/LiquidTWI2
   rm -rf LiquidTWI2

   git clone https://github.com/olikraus/U8glib_Arduino.git
   mv -f U8glib_Arduino "$arduinoDir"/libraries/U8glib_Arduino
   rm -rf U8glib_Arduino
}

## Clone Marlin
function getMarlin
{
   echo -e "\nCloning Marlin \"$marlinRepositoryUrl\"...\n"

   git clone "$marlinRepositoryUrl" "$marlinDir" 
   exit
}

## Get the toolchain and Marlin, install board definition
function setupEnvironment
{
   echo -e "\nSetting up build environment in \"$arduinoDir\" ...\n"
   getArduinoToolchain
   getDependencies
   installHardwareDefinition
   exit
}

## Install board definition
function installHardwareDefinition
{
   if [ "$hardwareDefintionDirectory" != "" ]; then
   echo -e "\nInstalling board hardware definition ... \n"

   cp -R "$hardwareDefintionDirectory" "$arduinoDir"/hardware/
   fi
}

## Backup Marlin configuration
## param #1 backup name
function backupMarlinConfiguration
{
   echo -e "\nSaving Marlin configuration\n"
   echo -e "  \"Configuration.h\""
   echo -e "  \"Configuration_adv.h\""
   echo -e "\nto \"./configuration/$1/\"\n"
   
   mkdir -p configuration/$1
   
   cp "$marlinDir"/Marlin/Configuration.h configuration/"$1"
   cp "$marlinDir"/Marlin/Configuration_adv.h configuration/"$1"
   exit
}

## Restore Marlin Configuration from backup
## param #1 backup name
function restoreMarlinConfiguration
{
   if [ -d "configuration/$1" ]; then
      echo -e "Restoring Marlin configuration\n"
      echo -e "  \"Configuration.h\""
      echo -e "  \"Configuration_adv.h\""
      echo -e "\nfrom \"./configuration/$1/\"\n"   

      cp configuration/"$1"/Configuration.h "$marlinDir"/Marlin/
      cp configuration/"$1"/Configuration_adv.h "$marlinDir"/Marlin/
   else
      echo -e "\nBackup configuration/$1 not found!\n"
   fi
   exit
}

## Build Marlin
function verifyBuild
{
   echo -e "\nVerifying build...\n"

   ./arduino/arduino --verify --verbose --board "$boardString" "$marlinDir"/Marlin/Marlin.ino --pref build.path="$buildDir"
   exit
}


## Build Marlin and upload 
function buildAndUpload
{
   echo -e "\nBuilding and uploading Marlin build from \"$buildDir\" ...\n"

   ./arduino/arduino --upload --port "$port" --verbose --board "$boardString" "$marlinDir"/Marlin/Marlin.ino --pref build.path="$buildDir"
   exit
}


## Delete everything that was downloaded
function cleanEverything
{
   rm -Rf "$arduinoDir"
   rm -Rf "$marlinDir"
   rm -Rf "$buildDir"
}

## Print help
function printDocu
{
	echo -e "\n\n-------------------------------------------------------------------------"
   echo -e "    Comandline parameters:"
   echo -e "-----------------------------------------------------------------------------\n\n"
   echo -e "-s  --setup                 Download and configure the toolchain and the"
   echo -e "                            necessary libraries for building Marlin.\n\n"
   echo -e "-m  --marlin                Download Marlin sources.\n\n"
   echo -e "-v  --verify                Build without uploading.\n\n"
   echo -e "-u  --upload                Build and upload Marlin.\n\n"
   echo -e "-b  --backupConfig  [name]  Backup the Marlin configuration to the named backup.\n"
   echo -e "-r  --restoreConfig [name]  Restore the given configuration into the Marlin directory."
   echo -e "                            Rename to Configuration.h implicitly.\n\n"
   echo -e "-c  --clean                 Cleanup everything. Remove Marlin sources and Arduino toolchain\n\n"
   echo -e "-p  --port [port]           Set the serialport for uploading the firmware."
   echo -e "                            Overrides the default in the script.\n\n"
   echo -e "-h  --help                  Show this doc.\n\n\n"
	exit
}


while [ "$1" != "" ]; do
    case $1 in
        -p | --port )           shift
                                port=$1
                                ;;
        -s | --setup )          setupEnvironment
                                ;;
        -m | --marlin )         getMarlin
                                ;;
        -v | --verify )         verifyBuild
                                ;;
        -u | --upload )         buildAndUpload
                                ;;
        -b | --backupConfig )   shift
                                backupMarlinConfiguration $1
                                ;;
        -r | --restoreConfig )  shift
                                restoreMarlinConfiguration $1
                                ;;
        -c | --clean )          shift
                                cleanEverything 
                                ;;
        -h | --help )           printDocu
                                ;;
        * )                     printDocu
                                exit 1
    esac
    shift
done
