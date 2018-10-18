#!/bin/bash

# by mmone with contribution by jhol, tssva
# on github at https://github.com/mmone/marlintool

set -e
set -u

# The default config file to look for
defaultParametersFile="marlintool.params"

cacheDir=$PWD/.cache

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

gitRepoName()
{
  basename "$1" ".${1##*.}"
}

getFile()
{
  local url=$1
  local file=$2
  local cacheFile=$cacheDir/$file

  if [ ! -f $cacheFile ]; then
    >&$l echo "  Downloading from $url..."

    local downloadTmpFile=$tmpDir/download
    if [ "$curl" != "" ]; then
      >&$o $curl -o "$downloadTmpFile" "$url"
    else
      >&$o $wget -O "$downloadTmpFile" "$url"
    fi

    mkdir -p $cacheDir
    mv $downloadTmpFile $cacheFile
  else
    >&$l echo "  Retrieving $(basename $file) from cache..."
  fi

  echo $cacheFile
}

getGitRepo()
{
  local url=$1
  local branch=$2

  local repoName=$(gitRepoName $url)
  local repoDir=$tmpDir/$repoName
  local cacheRepo=$cacheDir/$repoName

  if [ -d $cacheRepo ]; then
    >&$l echo "  Updating repository from $url..."
    (cd $cacheRepo; 2>&$o git fetch -p origin)
  else
    >&$l echo "  Cloning repository from $url..."
    >&$o git clone --bare $url $cacheRepo 2>&1
  fi

  >&$l echo "    Copying from cache..."
  if [ "$marlinRepositoryBranch" != "" ]; then
    >&$o git clone -b "$branch" --single-branch $cacheRepo $repoDir 2>&1
  else
    >&$o git clone $cacheRepo $repoDir 2>&1
  fi

  echo $repoDir
}

unpackArchive()
{
  local archive=$1
  local dir=$2

  case $archive in
    *.zip)
      >&$o unzip -q "$archive" -d "$dir"
      ;;
    *.tar.*)
      >&$o tar -xf "$archive" -C "$dir" --strip 1
      ;;
  esac
}

## Download the toolchain and unpack it
getArduinoToolchain()
{
  >&$l echo -e "\nGetting Arduino environment..."

  local archive=$(getFile http://downloads-02.arduino.cc/"$arduinoToolchainArchive" $arduinoToolchainArchive)
  rm -rf "$arduinoDir"
  mkdir -p "$arduinoDir/portable"
  >&$l echo "  Unpacking (this might take a while)..."
  if [ "$os" == "Darwin" ]; then
    >&$o unzip -q "$archive" -d "$arduinoDir"
  else
    >&$o tar -xf "$archive" -C "$arduinoDir" --strip 1
  fi
}


## Get dependencies and move them in place
getDependencies()
{
  >&$l echo -e "\nGetting libraries..."

  for library in ${marlinDependencies[@]}; do
    local libName=
    local libUrl=
    local libDir=

    IFS=',' read libName libUrl libDir <<< "$library"
    local libRepo=$(getGitRepo "$libUrl" "")
    mv -f "$libRepo/$libDir" "$arduinoLibrariesDir/$libName"
    rm -rf "$libRepo"
  done
}

## Clone Marlin
getMarlin()
{
  >&$l echo -e "\nGetting Marlin..."
  local repoDir=$(getGitRepo "$marlinRepositoryUrl" "$marlinRepositoryBranch")
  rm -rf "$marlinDir"
  mv "$repoDir" "$marlinDir"
  exit
}

## Update an existing Marlin clone
updateMarlin()
{
  local cacheRepo=$cacheDir/Marlin

  backupName=`date +%Y-%m-%d-%H-%M-%S`
  backupMarlinConfiguration

  >&$l echo -e "\nFetching most recent Marlin from \"$marlinRepositoryUrl\" ...\n"

  (
    cd $cacheRepo
    2>&$o git fetch -p origin
  )
  (
    cd $marlinDir
    >&$o git fetch -p origin
    >&$o git checkout
    >&$o git reset origin/`git rev-parse --abbrev-ref HEAD` --hard
  )

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
    >&$l echo -e "\nGetting board hardware definition..."
    local repoPath=$(getGitRepo "$hardwareDefinitionRepo" "")

    >&$l echo "  Moving board hardware definition into arduino directory..."

    mv -f $repoPath/hardware/* "$arduinoHardwareDir"
    rm -rf $repoPath
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
build()
{
  >&$l echo -e "\nBuilding Marlin...\n"

  if >&$o "$arduinoExecutable" --verify --verbose --board "$boardString" "$marlinDir"/Marlin/Marlin.ino \
      --pref build.path="$buildDir" 2>&1 ; then
    >&$l echo "Build successful."
  else
    >&2 echo "Build failed."
    >&2 echo
    exit 1
  fi

  exit
}


## Build Marlin and upload 
buildAndUpload()
{
  >&$l echo -e "\nBuilding and uploading Marlin build from \"$buildDir\" ...\n"

  if >&$o "$arduinoExecutable" --upload --port "$port" --verbose --board "$boardString" \
      "$marlinDir"/Marlin/Marlin.ino --pref build.path="$buildDir" 2>&1 ; then
    >&$l echo "Build and upload successful."
  else
    >&2 echo "Build and upload failed."
    >&2 echo
    exit 1
  fi

  exit
}


## Delete everything that was downloaded
cleanEverything()
{
  rm -Rf "$arduinoDir"
  rm -Rf "$marlinDir"
  rm -Rf "$buildDir"
}

## Delete everything that was downloaded
cleanCache()
{
  rm -Rf "$cacheDir"
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
  echo "   -v, --verbose            Print the output of sub-processes."
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
  echo "   clean-cache              Clean up the download cache."
  echo
  echo "   help                     Show help."
  echo
  exit
}

onExit()
{
  rm -rf $tmpDir
}

# Check for parameters file and source it if available

if [ -f $defaultParametersFile ]; then
  source "$defaultParametersFile"
else
  echo -e "\n ==================================================================="
  echo -e "\n  Can't find $defaultParametersFile!"
  echo -e "\n  Please rename the \"$defaultParametersFile.example\" file placed in the"
  echo -e "  same directory as this script to \"$defaultParametersFile\" and edit"
  echo -e "  if neccessary.\n"
  echo -e " ===================================================================\n\n"
  exit 1
fi

# Temporary directory
tmpDir=$(mktemp -d "${TMPDIR:-/tmp}/marlintool.XXXXXX")
trap "onExit" EXIT

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
  arduinoToolchainArchive="arduino-$arduinoToolchainVersion-macosx.zip"
  arduinoExecutable="$arduinoDir/Arduino.app/Contents/MacOS/Arduino"
  arduinoHardwareDir="$arduinoDir/Arduino.app/Contents/Java/hardware"
  arduinoLibrariesDir="$arduinoDir/Arduino.app/Contents/Java/libraries"
else
  arduinoToolchainArchive="arduino-$arduinoToolchainVersion-$arduinoToolchainArchitecture.tar.xz"
  arduinoExecutable="$arduinoDir/arduino"
  arduinoHardwareDir="$arduinoDir/hardware"
  arduinoLibrariesDir="$arduinoDir/libraries"
fi


checkTools git tar unzip
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
verbose=
verb=''

while [ "x$verb" = "x" ]; do
  case $1 in
    setup) verb=setupEnvironment;;
    get-marlin) verb=getMarlin;;
    update-marlin) verb=updateMarlin;;
    build) verb=build;;
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
    clean-cache) verb=cleanCache;;
    help|-h|--help) verb=printUsage;;
    -q|--quiet) quiet=y;;
    -v|--verbose) verbose=y;;
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
[ "x$verbose" = "xy" ] && exec {o}>&1 || exec {o}>/dev/null

$verb
