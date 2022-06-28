#!/bin/bash

if [[ $0 != /* ]]; then
  dirtyServerScriptFile="$(pwd)/$0"
else
  dirtyServerScriptFile="$0"
fi
cd "$(dirname "$dirtyServerScriptFile")"

binDir="$(pwd)"

dirtyParentDir="${binDir}/.."
if [[ ! -d $dirtyParentDir ]] || [[ ! -r $dirtyParentDir ]]; then
  echo "directory ${dirtyParentDir} not found or has bad permissions (needs at least r--)"
  exit 1
fi
cd "$dirtyParentDir"

parentDir="$(pwd)"

backupsDir="${parentDir}/serverBackups"
logsDir="${parentDir}/serverLogs"
tmpDir="${parentDir}/serverTmp"
config_file="${parentDir}/config.cfg"

if [[ ! -e $logsDir ]]; then
  mkdir -p $logsDir
elif [[ ! -d $logsDir ]]; then
  echo "$logsDir is not a directory"
  exit 1
fi

if [[ ! -e $tmpDir ]]; then
  mkdir -p $tmpDir
elif [[ ! -d $tmpDir ]]; then
  echo "$tmpDir is not a directory"
  exit 1
fi
hardcopyFile="${tmpDir}/hardcopy"

usage() {
  echo "usage : $(basename $0) action [--config FILE] [--msg TEXT] [--sleep TIME] [--wait-server] [--wait-backup] [--wait-update] [--full-backup]
    action can be: help|start|stop|status|backup|update|say
    --config FILE the config file to use, config.cfg by default
    --msg TEXT message to say
    --sleep TIME perform action in TIME seconds, only supported by start|backup|update
    --wait-server wait for server to stop before action
    --wait-backup wait for backup to end before action, only supported by start|update
    --wait-update wait for update to end before action, only supported by start|backup
    --full-backup backup not limited to saves but apply to all server files instead, only supported by backup"
}
myecho() {
  echo "$1"
  echo "$1" >> "${logsDir}/serverLog.log"
  echo "$1" >> "${logsDir}/serverScreensLog.log"
}
if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi
action="$1"
shift
if [[ $1 = --config ]]; then
  shift
  config_file="$1"
  shift
fi
msg="emptyMsg"
if [[ $1 = --msg ]]; then
  shift
  msg="$1"
  shift
fi
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
wait_server=false
if [[ $1 = --wait-server ]]; then
  shift
  wait_server=true
fi
wait_backup=false
if [[ $1 = --wait-backup ]]; then
  shift
  wait_backup=true
fi
wait_update=false
if [[ $1 = --wait-update ]]; then
  shift
  wait_update=true
fi
full_backup=false
if [[ $1 = --full-backup ]]; then
  shift
  full_backup=true
fi
if [[ $# -ne 0 ]]; then
  usage
  exit 1
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
# cd "${parentDir}"

backupScreenName="${screenName}Backup"
updateScreenName="${screenName}Update"

server_running=false
if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
  server_running=true
  if [[ ${wait_server} = true ]]; then
    myecho "waiting for server to stop before performing action"
    i=0
    server_stopped=false
    while [[ $i -lt ${serverTimeout} ]] && [[ ${server_stopped} = false ]]; do
      if [[ $i -ne 0 ]] && [[ $i = *0 ]]; then
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
      myecho "server : server stop timeout"
      exit 1
    fi
  fi
fi
if [[ $action = help ]]; then
  # help
  usage
elif [[ $action = start ]]; then
  # start
  if ! screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
    myecho "server ${screenName} told to start in ${sleepTime}s at $(date)"
    screen -dmS "${screenName}" "${binDir}/scripts/runServer.sh" --config "${config_file}" --sleep "${sleepTime}" --wait-backup "${wait_backup}" --wait-update "${wait_update}" --cmd startCmd
  else
    echo "server ${screenName} already running!"
    exit 1
  fi
# elif [ "$action" = startIsland ]; then
#   # start
#   if ! screen -ls "${screenName}2" | grep -q "\.${screenName}2\s"; then
#     myecho "server ${screenName}2 told to start in ${sleepTime}s at $(date)"
#     screen -dmS "${screenName}2" "scripts/runServer.sh" --config "${config_file}" --sleep "${sleepTime}" --wait-backup "${wait_backup}" --wait-update "${wait_update}" --cmd startCmdIsland
#   else
#     echo "server ${screenName}2 already running!"
#     exit 1
#   fi
elif [[ $action = stop ]]; then
  # stop
  if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
    myecho "server ${screenName} told to stop at $(date)"
    stopCmd
  else
    echo "server ${screenName} not running!"
    exit 1
  fi
# elif [ "$action" = stopIsland ]; then
#   # stop2
#   if screen -ls "${screenName}2" | grep -q "\.${screenName}2\s"; then
#     myecho "server ${screenName}2 told to stop at $(date)"
#     stopCmdIsland
#   else
#     echo "server ${screenName}2 not running!"
#     exit 1
#   fi
elif [[ $action = say ]]; then
  # say
  if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
    myecho "server ${screenName} told to say ${msg} at $(date)"
    sayCmd "${msg}"
  else
    echo "server ${screenName} not running, skipping say cmd"
    exit 0
  fi
elif [[ $action = status ]]; then
  # status
  if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
    echo -n "server ${screenName} running:"
    if [[ -f "${hardcopy}.0" ]]; then
      rm "${hardcopy}.0"
    elif [[ -e "${hardcopy}.0" ]]
      echo "${hardcopy}.0 is not a file"
      exit 1
    fi
    screen -r "${screenName}" -p 0 -X "${hardcopy}"
    sleep 1 # 0.1
    if [[ -f "${hardcopy}.0" ]]; then
      mv -f "${hardcopy}.0" "${logsDir}/lastStatus.log"
      echo "($(tac "${logsDir}/lastStatus.log" |egrep -m 1 .))"
      #echo "$(head -n 6 lastStatus.log)"
    else
      echo "screen no hardcopy found: ${hardcopy}.0 from $(pwd)"
      exit 1
    fi
  else
    echo "server ${screenName} not running"
  fi
  if screen -ls "${backupScreenName}" | grep -q "\.${backupScreenName}\s"; then
    echo -n "server ${backupScreenName} running:"
    if [[ -f "${hardcopy}.0" ]]; then
      rm "${hardcopy}.0"
    fi
    screen -r "${backupScreenName}" -p 0 -X "${hardcopy}"
    sleep 1 # 0.1
    if [[ -f "${hardcopy}.0" ]]; then
      mv -f "${hardcopy}.0" "${logsDir}/lastStatusBackup.log"
      echo "($(tac "${logsDir}/lastStatusBackup.log" |egrep -m 1 .))"
      #echo "$(head -n 6 lastStatusBackup.log)"
    else
      echo "screen backup no hardcopy found: ${hardcopy}.0 from $(pwd)"
      exit 1
    fi
  fi
  if screen -ls "${updateScreenName}" | grep -q "\.${updateScreenName}\s"; then
    echo -n "server ${updateScreenName} running:"
    if [[ -f "${hardcopy}.0" ]]; then
      rm "${hardcopy}.0"
    fi
    screen -r "${updateScreenName}" -p 0 -X "${hardcopy}"
    sleep 1 # 0.1
    if [[ -f "${hardcopy}.0" ]]; then
      mv -f "${hardcopy}.0" "${logsDir}/lastStatusUpdate.log"
      echo "($(tac "${logsDir}/lastStatusUpdate.log" |egrep -m 1 .))"
      #echo "$(head -n 6 lastStatusUpdate.log)"
    else
      echo "screen update no hardcopy found: ${hardcopy}.0 from $(pwd)"
      exit 1
    fi
  fi
elif [[ $action = backup ]]; then
  # backup
  if [[ ${server_running} = false ]] || [[ ${wait_server} = true ]]; then
    if ! screen -ls "${backupScreenName}" | grep -q "\.${backupScreenName}\s"; then
      myecho "server ${screenName} told to do a backup in ${sleepTime}s at $(date)"
      screen -d -m -S "${backupScreenName}" "${binDir}/scripts/doSafeBackup.sh" --config "${config_file}" --sleep "${sleepTime}" --wait-update "${wait_update}" --full-backup "${full_backup}"
    else
      echo "backup script already running!"
      exit 1
    fi
  else
    echo "server ${screenName} currently running"
    exit 1
  fi
elif [[ $action = update ]]; then
  # update
  if [[ ${server_running} = false ]] || [[ ${wait_server} = true ]]; then
    if ! screen -ls "${updateScreenName}" | grep -q "\.${updateScreenName}\s"; then
      myecho "server ${screenName} told to update in ${sleepTime}s at $(date)"
      screen -d -m -S "${updateScreenName}" "${binDir}/scripts/doSafeUpdate.sh" --config "${config_file}" --sleep "${sleepTime}" --wait-backup "${wait_backup}"
    else
      echo "update script already running!"
      exit 1
    fi
  else
    echo "server ${screenName} currently running"
    exit 1
  fi
else
  usage
  exit 1
fi

exit 0