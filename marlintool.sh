#!/bin/bash

# by mmone with contribution by jhol, tssva
# on github at https://github.com/mmone/marlintool

# Official Marlin repository
marlinRepositoryUrl="https://github.com/MarlinFirmware/Marlin"

# Repository branch to use
# Leave empty to clone the default branch
marlinRepositoryBranch=""

# Anet board hardware definition repository URL.
# Set to empty string if you don't need this.
hardwareDefinitionRepo="https://github.com/SkyNet3D/anet-board.git"

# Anet board identifier.
boardString="anet:avr:anet"

# Arduino Mega
# boardString="arduino:avr:mega:cpu=atmega2560"

arduinoToolchainVersion="1.8.5"

# Toolchain architecture
arch=$(uname -m)
case $arch in
  arm*) arduinoToolchainArchitecture="linuxarm" ;;
  i386|i486|i586|i686) arduinoToolchainArchitecture="linux32" ;;
  x86_64) arduinoToolchainArchitecture="linux64" ;;
  *)
    >&2 echo "Unsuppored platform architecture: $arch"
    exit 1
    ;;
esac

# Serialport for uploading
port="/dev/ttyUSB0"

# Where to put the arduino toolchain
arduinoDir="./arduino"

# Where to checkout Marlin sources
marlinDir="Marlin"

# Build directory
buildDir="./build"



scriptName=$0

## Checks that the tools listed in arguments are all installed.
checkTools()
{
  for cmd in "$@"; do
    type -p $cmd >/dev/null || [ -x /usr/bin/$cmd ] || [ -x /bin/$cmd ] || [ -x /sbin/$cmd ] || {
      >&2 echo "The following tools must be installed:"
      >&2 echo "  $@"
      >&2 echo "  Failed to find $cmd"
      >&2 echo
      exit 1
    }
  done
}

## Download the toolchain and unpack it
getArduinoToolchain()
{
   echo -e "\nDownloading Arduino environment ...\n"
   wget http://downloads-02.arduino.cc/arduino-"$arduinoToolchainVersion"-"$arduinoToolchainArchitecture".tar.xz
   mkdir "$arduinoDir"
   echo -e "\nUnpacking Arduino environment. This might take a while ...\n"
   tar -xf arduino-"$arduinoToolchainVersion"-"$arduinoToolchainArchitecture".tar.xz -C "$arduinoDir" --strip 1
   rm -R arduino-"$arduinoToolchainVersion"-"$arduinoToolchainArchitecture".tar.xz
}


## Get dependencies and move them in place
getDependencies()
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
getMarlin()
{
   echo -e "\nCloning Marlin \"$marlinRepositoryUrl\" ...\n"

   if [ "$marlinRepositoryBranch" != "" ]; then
     git clone -b "$marlinRepositoryBranch" --single-branch "$marlinRepositoryUrl" "$marlinDir"
   else
     git clone "$marlinRepositoryUrl" "$marlinDir"
   fi

   exit
}

## Update an existing Marlin clone
checkoutMarlin()
{
   date=`date +%Y-%m-%d-%H-%M-%S`

   # backup configuration
   backupMarlinConfiguration $date

   cd $marlinDir

   echo -e "\nFetching most recent Marlin from \"$marlinRepositoryUrl\" ...\n"

   git fetch
   git checkout
   git reset origin/`git rev-parse --abbrev-ref HEAD` --hard

   echo -e "\n"

   cd ..

   restoreMarlinConfiguration $date
   exit
}


## Get the toolchain and Marlin, install board definition
setupEnvironment()
{
   echo -e "\nSetting up build environment in \"$arduinoDir\" ...\n"
   getArduinoToolchain
   getDependencies
   getHardwareDefinition
   exit
}

## Fetch and install anet board hardware definition
getHardwareDefinition()
{
   if [ "$hardwareDefinitionRepo" != "" ]; then
   
   echo -e "\nCloning board hardware definition from \"$hardwareDefinitionRepo\" ... \n"
   git clone "$hardwareDefinitionRepo"

   echo -e "\nMoving board hardware definition into arduino directory ... \n"
   
   repoName=$(basename "$hardwareDefinitionRepo" ".${hardwareDefinitionRepo##*.}")
   
   mv -f $repoName/hardware/* "$arduinoDir"/hardware/
   rm -rf $repoName
   fi
}


## Backup Marlin configuration
## param #1 backup name
backupMarlinConfiguration()
{
   echo -e "\nSaving Marlin configuration\n"
   echo -e "  \"Configuration.h\""
   echo -e "  \"Configuration_adv.h\""
   echo -e "\nto \"./configuration/$1/\"\n"

   mkdir -p configuration/$1

   cp "$marlinDir"/Marlin/Configuration.h configuration/"$1"
   cp "$marlinDir"/Marlin/Configuration_adv.h configuration/"$1"
}

## Restore Marlin Configuration from backup
## param #1 backup name
restoreMarlinConfiguration()
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
verifyBuild()
{
   echo -e "\nVerifying build ...\n"

   "$arduinoDir"/arduino --verify --verbose --board "$boardString" "$marlinDir"/Marlin/Marlin.ino --pref build.path="$buildDir"
   exit
}


## Build Marlin and upload 
buildAndUpload()
{
   echo -e "\nBuilding and uploading Marlin build from \"$buildDir\" ...\n"

   "$arduinoDir"/arduino --upload --port "$port" --verbose --board "$boardString" "$marlinDir"/Marlin/Marlin.ino --pref build.path="$buildDir"
   exit
}


## Delete everything that was downloaded
cleanEverything()
{
   rm -Rf "$arduinoDir"
   rm -Rf "$marlinDir"
   rm -Rf "$buildDir"
}

## Print help
printDocu()
{
   echo "Usage:"
   echo " $scriptName ARGS"
   echo
   echo "Builds an installs Marlin 3D printer firmware."
   echo
   echo "Options:"
   echo
   echo " -s, --setup                 Download and configure the toolchain and the"
   echo "                             necessary libraries for building Marlin."
   echo " -m, --marlin                Download Marlin sources."
   echo " -f, --fetch                 Update an existing Marlin clone."
   echo " -v, --verify                Build without uploading."
   echo " -u, --upload                Build and upload Marlin."
   echo " -b, --backupConfig  [name]  Backup the Marlin configuration to the named backup."
   echo " -r, --restoreConfig [name]  Restore the given configuration into the Marlin directory."
   echo "                               Rename to Configuration.h implicitly."
   echo " -c, --clean                 Cleanup everything. Remove Marlin sources and Arduino toolchain"
   echo " -p, --port [port]           Set the serialport for uploading the firmware."
   echo "                               Overrides the default in the script."
   echo " -h, --help                  Show this doc."
   echo
   exit
}

checkTools git tar wget

if [ "$1" = "" ]; then printDocu; exit 1; fi

while [ "$1" != "" ]; do
    case $1 in
        -p | --port )           shift
                                port=$1
                                ;;
        -s | --setup )          setupEnvironment
                                ;;
        -m | --marlin )         getMarlin
                                ;;
        -f | --fetch )          checkoutMarlin
                                ;;
        -v | --verify )         verifyBuild
                                ;;
        -u | --upload )         buildAndUpload
                                ;;
        -b | --backupConfig )   shift
                                backupMarlinConfiguration $1 exit
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
