#!/bin/bash

startDir="$(pwd)"

if [[ $0 != /* ]]; then
  dirtyServerScriptFile="$(pwd)/$0"
else
  dirtyServerScriptFile="$0"
fi
cd "$(dirname "$dirtyServerScriptFile")"

binDir="$(pwd)"

dirtyParentDir="${binDir}/.."
if [[ ! -d $dirtyParentDir ]]; then
  echo "directory ${dirtyParentDir} not found"
  exit 1
fi
cd "$dirtyParentDir"

parentDir="$(pwd)"
scriptsDir="${binDir}/utils"
backupsDir="${parentDir}/serverBackups"
logsDir="${parentDir}/serverLogs"
tmpDir="${parentDir}/serverTmp"
configFileDirty="${parentDir}/config.cfg"

cd "${binDir}"

if [[ ! -e $logsDir ]]; then
  mkdir -p "$logsDir"
elif [[ ! -d $logsDir ]]; then
  echo "$logsDir is not a directory"
  exit 1
fi

if [[ ! -e $tmpDir ]]; then
  mkdir -p "$tmpDir"
elif [[ ! -d $tmpDir ]]; then
  echo "$tmpDir is not a directory"
  exit 1
fi
hardcopyFile="${binDir}/hardcopy"
if [[ -e $hardcopyFile && ! -f $hardcopyFile ]]; then
  echo "${hardcopyFile} is not a file"
  exit 1
fi
if [[ ! -e $backupsDir ]]; then
  mkdir -p "$backupsDir"
elif [[ ! -d $backupsDir ]]; then
  echo "$backupsDir is not a directory"
  exit 1
fi
