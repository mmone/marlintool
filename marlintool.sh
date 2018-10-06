#!/bin/bash

# by mmone with contribution by jhol, tssva
# on github at https://github.com/mmone/marlintool

set -e
set -u

# The default config file to look for
defaultParametersFile="marlintool.params"

scriptName=$0

## Checks that the tools listed in arguments are all installed.
checkTools()
{
  for cmd in "$@"; do
    command -v $cmd >/dev/null || {
      >&2 echo "The following tools must be installed:"
      >&2 echo "  $@"
      >&2 echo "  Failed to find $cmd"
      >&2 echo
      exit 1
    }
  done
}

checkCurlWget()
{
  if ! curl=$(command -v curl) && ! wget=$(command -v wget); then
    >&2 echo "Neither curl nor wget were found installed"
    >&2 echo
    exit 1
  fi
}

downloadFile()
{
  local url=$1
  local file=$2

  if [ "$curl" != "" ]; then
    $curl -o "$file" "$url"
  else
    $wget -O "$file" "$url"
  fi
}

## Download the toolchain and unpack it
getArduinoToolchain()
{
  >&$l echo -e "\nDownloading Arduino environment ...\n"

  downloadFile http://downloads-02.arduino.cc/"$arduinoToolchainArchive" $arduinoToolchainArchive
  mkdir -p "$arduinoDir/portable"
  >&$l echo -e "\nUnpacking Arduino environment. This might take a while ...\n"
  if [ "$os" == "Darwin" ]; then
    unzip -q "$arduinoToolchainArchive" -d "$arduinoDir"
  else
    tar -xf "$arduinoToolchainArchive" -C "$arduinoDir" --strip 1
  fi
  rm -R "$arduinoToolchainArchive"
}


## Get dependencies and move them in place
getDependencies()
{
  >&$l echo -e "\nDownloading libraries ...\n"

  for library in ${marlinDependencies[@]}; do
    IFS=',' read libName libUrl libDir <<< "$library"
    git clone "$libUrl" "$libName"
    rm -rf "$arduinoLibrariesDir"/"$libName"
    mv -f "$libName"/"$libDir" "$arduinoLibrariesDir"/"$libName"
    rm -rf "$libName"
  done
}

## Clone Marlin
getMarlin()
{
  >&$l echo -e "\nCloning Marlin \"$marlinRepositoryUrl\" ...\n"

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
  backupName=`date +%Y-%m-%d-%H-%M-%S`

  # backup configuration
  backupMarlinConfiguration

  cd $marlinDir

  >&$l echo -e "\nFetching most recent Marlin from \"$marlinRepositoryUrl\" ...\n"

  git fetch
  git checkout
  git reset origin/`git rev-parse --abbrev-ref HEAD` --hard

  >&$l echo -e "\n"

  cd ..

  restoreMarlinConfiguration
  exit
}


## Get the toolchain and Marlin, install board definition
setupEnvironment()
{
  >&$l echo -e "\nSetting up build environment in \"$arduinoDir\" ...\n"
  getArduinoToolchain
  getDependencies
  getHardwareDefinition
  exit
}

## Fetch and install anet board hardware definition
getHardwareDefinition()
{
  if [ "$hardwareDefinitionRepo" != "" ]; then
    >&$l echo -e "\nCloning board hardware definition from \"$hardwareDefinitionRepo\" ... \n"
    git clone "$hardwareDefinitionRepo"

    >&$l echo -e "\nMoving board hardware definition into arduino directory ... \n"

    repoName=$(basename "$hardwareDefinitionRepo" ".${hardwareDefinitionRepo##*.}")

    mv -f $repoName/hardware/* "$arduinoHardwareDir"
    rm -rf $repoName
  fi
}


## Backup Marlin configuration
## param #1 backup name
backupMarlinConfiguration()
{
  >&$l echo -e "\nSaving Marlin configuration\n"
  >&$l echo -e "  \"Configuration.h\""
  >&$l echo -e "  \"Configuration_adv.h\""
  >&$l echo -e "\nto \"./configuration/$backupName/\"\n"

  mkdir -p configuration/$backupName

  cp "$marlinDir"/Marlin/Configuration.h configuration/"$backupName"
  cp "$marlinDir"/Marlin/Configuration_adv.h configuration/"$backupName"
}

## Restore Marlin Configuration from backup
## param #1 backup name
restoreMarlinConfiguration()
{
  if [ -d "configuration/$backupName" ]; then
    >&$l echo -e "Restoring Marlin configuration\n"
    >&$l echo -e "  \"Configuration.h\""
    >&$l echo -e "  \"Configuration_adv.h\""
    >&$l echo -e "\nfrom \"./configuration/$backupName/\"\n"

    cp configuration/"$backupName"/Configuration.h "$marlinDir"/Marlin/
    cp configuration/"$backupName"/Configuration_adv.h "$marlinDir"/Marlin/
  else
    >&2 echo -e "\nBackup configuration/$backupName not found!\n"
  fi
  exit
}

## Build Marlin
verifyBuild()
{
  >&$l echo -e "\nVerifying build ...\n"

  "$arduinoExecutable" --verify --verbose --board "$boardString" "$marlinDir"/Marlin/Marlin.ino --pref build.path="$buildDir"
  exit
}


## Build Marlin and upload 
buildAndUpload()
{
  >&$l echo -e "\nBuilding and uploading Marlin build from \"$buildDir\" ...\n"

  "$arduinoExecutable" --upload --port "$port" --verbose --board "$boardString" "$marlinDir"/Marlin/Marlin.ino --pref build.path="$buildDir"
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
printUsage()
{
  echo "Usage:"
  echo " $scriptName [-q] <command> [<args>]"
  echo
  echo "Builds an installs Marlin 3D printer firmware."
  echo
  echo "Options:"
  echo "   -q, --quiet              Don't print status messages."
  echo
  echo "Commands:"
  echo "   setup                    Download and configure the toolchain and the"
  echo "                            necessary libraries for building Marlin."
  echo "   get-marlin               Download Marlin sources."
  echo "   update-marlin            Update existing Marlin source."
  echo
  echo "   build                    Build Marlin without uploading."
  echo "   build-upload             Build Marlin and upload."
  echo "      -p, --port [port]     Set the device serial port."
  echo
  echo "   backup-config <name>     Backup the Marlin configuration to a named backup."
  echo "   restore-config <name>    Restore the Marlin given configuration."
  echo
  echo "   clean                    Remove Arduino tool-chain and Marlin sources."
  echo
  echo "   help                     Show help."
  echo
  exit
}

# Check for parameters file and source it if available

if [ -f $defaultParametersFile ]; then
  source "$defaultParametersFile"
else
  >&2 echo -e "\n ==================================================================="
  >&2 echo -e "\n  Can't find $defaultParametersFile!"
  >&2 echo -e "\n  Please rename the \"$defaultParametersFile.example\" file placed in the"
  >&2 echo -e "  same directory as this script to \"$defaultParametersFile\" and edit"
  >&2 echo -e "  if neccessary.\n"
  >&2 echo -e " ===================================================================\n\n"
  exit 1
fi

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

# Operating system specific values
os=$(uname -s)
if [ "$os" == "Darwin" ]; then
  tools="git unzip"
  arduinoToolchainArchive="arduino-$arduinoToolchainVersion-macosx.zip"
  arduinoExecutable="$arduinoDir/Arduino.app/Contents/MacOS/Arduino"
  arduinoHardwareDir="$arduinoDir/Arduino.app/Contents/Java/hardware"
  arduinoLibrariesDir="$arduinoDir/Arduino.app/Contents/Java/libraries"
else
  tools="git tar"
  arduinoToolchainArchive="arduino-$arduinoToolchainVersion-$arduinoToolchainArchitecture.tar.xz"
  arduinoExecutable="$arduinoDir/arduino"
  arduinoHardwareDir="$arduinoDir/hardware"
  arduinoLibrariesDir="$arduinoDir/libraries"
fi


checkTools "$tools"
checkCurlWget

if [ $# -lt 1 ]; then
  printUsage >&2
  exit 1
fi

parseBackupRestoreArgument() {
  if [ $# -eq 0 ]; then
    >&2 echo "No backup path given"
    >&2 echo
    exit 1
  else
    echo $1
  fi
}

quiet=
verb=''

while [ "x$verb" = "x" ]; do
  case $1 in
    setup) verb=setupEnvironment;;
    get-marlin) verb=getMarlin;;
    update-marlin) verb=checkoutMarlin;;
    build) verb=verifyBuild;;
    build-upload) verb=buildAndUpload;;
    backup-config)
      verb=backupMarlinConfiguration
      shift
      backupName=$(parseBackupRestoreArgument $@)
      ;;
    restore-config)
      verb=restoreMarlinConfiguration
      shift
      backupName=$(parseBackupRestoreArgument $@)
      ;;
    clean) verb=cleanEverything;;
    help|-h|--help) verb=printUsage;;
    -q|--quiet) quiet=y;;
    *)
      printUsage >&2
      exit 1
      ;;
  esac
  shift
done

case $verb in
  buildAndUpload)
    while [ $# -gt 0 ]; do
      case $1 in
        -p|--port)
          shift
          port=$1
          ;;
        -q|--quiet) quiet=y;;
        -v|--verbose) verbose=y;;
        *)
          printUsage >&2
          exit 1
      esac
      shift
    done
    ;;
  *)
    while [ $# -gt 0 ]; do
      case $1 in
        -q|--quiet) quiet=y;;
        -v|--verbose) verbose=y;;
        *)
          printUsage >&2
          exit 1
      esac
      shift
    done
    ;;
esac

[ "x$quiet" = "xy" ] && exec {l}>/dev/null || exec {l}>&1

$verb
