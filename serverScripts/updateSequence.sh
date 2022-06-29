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
if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
  "${binDir}/dediBash.sh" stop --config "${configFile}"
  sleep 1
  "${binDir}/dediBash.sh" backup --config "${configFile}" --wait-server --full-backup
  sleep 1
  "${binDir}/dediBash.sh" update --config "${configFile}" --wait-server --wait-backup
  sleep 1
  "${binDir}/dediBash.sh" start --config "${configFile}" --wait-server --wait-backup --wait-update
elif [ "${ifNeeded}" = false ]; then
  "${binDir}/dediBash.sh" backup --config "${configFile}" --full-backup
  sleep 1
  "${binDir}/dediBash.sh" update --config "${configFile}" --wait-backup
fi
exit 0
