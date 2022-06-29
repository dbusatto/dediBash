#!/bin/bash

. "$(dirname "$0")/utils/initVars.sh"
cd "${binDir}"

myecho() {
  echo "$1"
  echo "$1" >> "${logsDir}/serverScreensLog.log"
}

if [[ $1 = --config ]]; then
  shift
  configFileDirty="$1"
  shift
fi

. "${binDir}/utils/initConfig.sh"
cd "${binDir}"

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
  "${binDir}/dediBash.sh" stop --config "${configFile}"
  sleep 1
  "${binDir}/dediBash.sh" backup --config "${configFile}" --wait-server "${backupOpts}"
  sleep 1
  "${binDir}/dediBash.sh" start --config "${configFile}" --wait-server --wait-backup
elif [ "${ifNeeded}" = false ]; then
  echo "${binDir}/dediBash.sh backup --config ${configFile} ${backupOpts}"
  "${binDir}/dediBash.sh" backup --config "${configFile}" ${backupOpts}
fi
exit 0
