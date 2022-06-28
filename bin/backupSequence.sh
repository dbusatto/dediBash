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

ifNeeded=false
if [[ $1 = --if-needed ]]; then
  shift
  ifNeeded=true
fi
backupOpts=""
if [[ $1 = --full-backup ]]; then
  shift
  backupOpts="--full-backup"
fi
if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
  "${binDir}/dediBash.sh" stop --config "${config_file}"
  sleep 1
  "${binDir}/dediBash.sh" backup --config "${config_file}" --wait-server "${backupOpts}"
  sleep 1
  "${binDir}/dediBash.sh" start --config "${config_file}" --wait-server --wait-backup
elif [ "${ifNeeded}" = false ]; then
  "${binDir}/dediBash.sh" backup --config "${config_file}" "${backupOpts}"
fi
exit 0
