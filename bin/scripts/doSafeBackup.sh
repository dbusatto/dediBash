#!/bin/bash
# do a safe backup of the server, all path relative to dediBash folder
# should be called from the bin folder
binDir="$(pwd)"

dirtyParentDir="${binDir}/.."
if [[ ! -d $dirtyParentDir ]]; then
  echo "directory ${dirtyParentDir} not found"
  exit 1
fi
cd "$dirtyParentDir"

parentDir="$(pwd)"
scriptsDir="${binDir}/scripts"
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
  if [[ "$1" =~ $pattern ]]; then
    sleepTime="${BASH_REMATCH[1]}"
    shift
  else
    myecho "invalid sleep time:$1"
    exit 1
  fi
fi
sleep "${sleepTime}"
wait_update=false
if [[ $1 = --wait-update ]]; then
  shift
  wait_update="$1"
  shift
fi
full_backup=false
if [[ $1 = --full-backup ]]; then
  shift
  full_backup="$1"
  shift
fi

if [[ $# -ne 0 ]]; then
  myecho "unsupported args $@"
  exit 1
fi
i=0
if screen -ls "${updateScreenName}" | grep -q "\.${updateScreenName}\s"; then
  if [[ $wait_update = false ]]; then
    myecho "server update running!"
    exit 1
  else
    myecho "waiting for update to end before performing backup"
    server_stopped=false
    while [[ $i -lt $backupTimeout && $server_stopped = false ]]; do
      if [[ $i -ne 0 && $i = *0 ]]; then
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
      myecho "backup : server update timeout"
      exit 1
    fi
  fi
fi
if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
  server_running=true
  server_stopped=false
  while [[ $i -lt $backupTimeout && $server_stopped = false ]]; do
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
    echo "backup : server stop timeout"
    exit 1
  fi
else
  server_running=false
fi
if [[ $full_backup = false ]]; then
  myecho "backup of ${backupName} started at $(date)"
  "${scriptsDir}/doBackup.sh" --config "${config_file}" "${backupTarget}" "${backupName}"
  stop_status="$?"
else
  myecho "backup of ${fullBackupName} started at $(date)"
  "${scriptsDir}/doBackup.sh" --config "${config_file}" "${fullBackupTarget}" "${fullBackupName}"
  stop_status="$?"
fi
cd "${position}"
myecho "backup finished with status ${stop_status} at $(date)"
"${scriptsDir}/readBackups.sh" --config "${config_file}"
exit 0
