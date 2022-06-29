#!/bin/bash
# should be called from the bin folder
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
config_file="${parentDir}/config.cfg"

cd "${binDir}"

myecho() {
  echo "$1"
  echo "$1" >> "${logsDir}/serverScreensLog.log"
}

if [[ $1 = --config ]]; then
  shift
  config_file="$1"
  shift
fi
if [[ ! -f $config_file || ! -r $config_file || ! -x $config_file ]]; then
  myecho "file ${config_file} not found from directory ${parentDir} or has bad permissions (needs at least r-x)"
  exit 1
fi
. "${config_file}"
if [[ -n $screenName ]]; then
  myecho "bad config load, no screenName found"
  exit 1
fi
backupScreenName="${screenName}Backup"
updateScreenName="${screenName}Update"


cd "${parentDir}"

isdir=false
target="$1"
output="$2"
shift
shift

if [[ ! -e $target ]]; then
  myecho "Target not found:${target}"
  exit 1
fi
if [[ -d $target ]]; then
  isdir=true
elif [[ -f $target && -r $target ]]; then
  isdir=false
else
  myecho "Invalid target:${target}"
  exit 1
fi

backup_dir="${backupsDir}/${output}"
backup_name="${backup_dir}/${output}_$(date +%F-%Hh%M)"
if [[ -e $backup_name ]]; then
  myecho "backup already exists: ${backup_name}"
  exit 1
fi

mkdir -p "${backup_dir}"
if [[ ! -d $backup_dir || ! -w $backup_dir ]]; then
  myecho "Invalid backup directory:${target}"
  exit 1
fi
if [ "${isdir}" = true ]; then
  echo "Backing up directory \"${target}\" at \"${backup_name}\""
  cp -r "${target}" "${backup_name}"
else
  echo "Backing up file \"${target}\" at \"${backup_name}\""
  cp "${target}" "${backup_name}"
fi

exit 0
