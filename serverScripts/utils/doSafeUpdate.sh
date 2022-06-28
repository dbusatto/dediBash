#!/bin/bash
# do a safe update of the server, all path relative to the dediBash folder
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
    myecho "waiting for backup to end before performing update"
    server_stopped=false
    while [[ $i -lt $updateTimeout && $server_stopped = false ]]; do
      if [[ $i -ne 0 && $i = *0 ]]; then
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
      myecho "update : server backup timeout"
      exit 1
    fi
  fi
fi
if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
  server_running=true
  server_stopped=false
  while [[ $i -lt $updateTimeout && $server_stopped = false ]]; do
    if [[ $i -ne 0 && $i = *0 ]]; then
      echo "server still running after ${i}s"
    fi
    sleep 1
    i=$((i+1))
    if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
      server_stopped=false
    else
      server_stopped=true
    fi
  done
  if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
    echo "update : server stop timeout"
    exit 1
  fi
else
  server_running=false
fi
myecho "update started at $(date)"
updateCmd
stop_status="$?"
cd "${position}"
myecho "update finished with status ${stop_status} at $(date)"
exit 0
