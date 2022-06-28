#!/bin/bash
# run the server

parentDir="$(pwd)"

backupsDir="${parentDir}/serverBackups"
logsDir="${parentDir}/serverLogs"
tmpDir="${parentDir}/serverTmp"
config_file="${parentDir}/config.cfg"

if [[ $1 = --config ]]; then
  shift
  config_file="$1"
  shift
fi
if [[ ! -f $config_file ]] || [[ ! -r $config_file ]] || [[ ! -x $config_file ]]; then
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
myecho() {
  echo "$1"
  echo "$1" >> "${logsDir}/serverScreensLog.log"
}
sleepTime=0
if [[ $1 = --sleep ]]; then
  shift
  pattern='^([0-9]+)$'
  if [[ $1 =~ $pattern ]]; then
    sleepTime="${BASH_REMATCH[1]}"
    shift
  else
    myecho "invalid sleep time:$1"
    exit 1
  fi
fi
sleep "${sleepTime}"
wait_backup=false
if [[ $1 = --wait-backup ]]; then
  shift
  wait_backup="$1"
  shift
fi
wait_update=false
if [[ $1 = --wait-update ]]; then
  shift
  wait_update="$1"
  shift
fi
launchCmd="startCmd"
if [[ $1 = --cmd ]]; then
  shift
  launchCmd="$1"
  shift
fi
if [[ $# -ne 0 ]]; then
  myecho "unsupported args $@"
  exit 1
fi
i=0
if screen -ls "${backupScreenName}" | grep -q "\.${backupScreenName}\s"; then
  if [[ $wait_backup = false ]]; then
    myecho "server backup running!"
    exit 1
  else
    myecho "waiting for backup to end before starting server"
    server_stopped=false
    while [[ $i -lt $startTimeout ]] && [[ $server_stopped = false ]]; do
      if [[ $i -ne 0 ]] && [[ $i = *0 ]]; then
        echo "backup server still running after ${i}s"
      fi
      sleep 1
      i=$((i+1))
      if screen -ls "${backupScreenName}" | grep -q "\.${backupScreenName}\s"; then
        server_stopped=false
      else
        server_stopped=true
      fi
    done
    if screen -ls "${backupScreenName}" | grep -q "\.${backupScreenName}\s"; then
      myecho "start : server backup timeout"
      exit 1
    fi
  fi
fi
if screen -ls "${updateScreenName}" | grep -q "\.${updateScreenName}\s"; then
  if [[ "${wait_update}" = false ]]; then
    myecho "server update running!"
    exit 1
  else
    myecho "waiting for update to end before starting server"
    server_stopped=false
    while [[ $i -lt $startTimeout ]] && [[ $server_stopped = false ]]; do
      if [[ $i -ne 0 ]] && [[ $i = *0 ]]; then
        echo "update server still running after ${i}s"
      fi
      sleep 1
      i=$((i+1))
      if screen -ls "${updateScreenName}" | grep -q "\.${updateScreenName}\s"; then
        server_stopped=false
      else
        server_stopped=true
      fi
    done
    if screen -ls "${updateScreenName}" | grep -q "\.${updateScreenName}\s"; then
      myecho "start : server update timeout"
      exit 1
    fi
  fi
fi

myecho "server ${screenName} ${launchCmd} started at $(date) from config ${config_file}"
$launchCmd
stop_status="$?"
cd "${parentDir}"
myecho "server ${screenName} ${launchCmd} stopped with status ${stop_status} at $(date)"

exit 0
