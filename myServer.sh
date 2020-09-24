#!/bin/bash
if [[ ! "$0" == /* ]]; then
  dirtyServerLoc="$(pwd)/$0"
else
  dirtyServerLoc="$0"
fi
cd "$(dirname ${dirtyServerLoc})"
serverLoc="$(pwd)"
pattern="(/home/[^/]+)/"
if [[ ${serverLoc} =~ $pattern ]]; then
  userLoc=${BASH_REMATCH[1]}
fi
if [ ! -f config.cfg ] || [ ! -r config.cfg ]; then
  echo "bad directory: ${serverLoc}"
  exit 1
fi
. config.cfg
backupScreenName="${screenName}Backup"
updateScreenName="${screenName}Update"
usage() {
  echo "usage : $(basename $0) action [--sleep TIME] [--wait-server] [--wait-backup] [--wait-update] [--full-backup]
    action can be: help|start|stop|status|backup|update
    --sleep TIME perform action in TIME seconds, only supported by start|backup|update
    --wait-server wait for server to stop before action
    --wait-backup wait for backup to end before action, only supported by start|update
    --wait-update wait for update to end before action, only supported by start|backup
    --full-backup backup not limited to saves but apply to all server files instead, only supported by backup"
}
myecho() {
  echo "$1"
  echo "$1" >> serverLog.log
  echo "$1" >> serverScreensLog.log
}
if [ "$#" -lt 1 ]; then
  usage
  exit 1
fi
action="$1"
shift
sleepTime=0
if [ "$1" = --sleep ]; then
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
wait_server=false
if [ "$1" = --wait-server ]; then
  shift
  wait_server=true
fi
wait_backup=false
if [ "$1" = --wait-backup ]; then
  shift
  wait_backup=true
fi
wait_update=false
if [ "$1" = --wait-update ]; then
  shift
  wait_update=true
fi
full_backup=false
if [ "$1" = --full-backup ]; then
  shift
  full_backup=true
fi
if [ "$#" -ne 0 ]; then
  usage
  exit 1
fi
server_running=false
if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
  server_running=true
  if [ "${wait_server}" = true ]; then
    myecho "waiting for server to stop before performing action"
    i=0
    server_stopped=false
    while [ "$i" -lt "${serverTimeout}" ] && [ "${server_stopped}" = false ]; do
      if [ "$i" -ne 0 ] && [[ "$i" == *0 ]]; then
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
if [ "$action" = help ]; then
  # help
  usage
elif [ "$action" = start ]; then
  # start
  if ! screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
    myecho "server ${screenName} told to start in ${sleepTime}s at $(date)"
    screen -dmS "${screenName}" "scripts/runServer.sh" --sleep "${sleepTime}" --wait-backup "${wait_backup}" --wait-update "${wait_update}"
  else
    echo "server ${screenName} already running!"
    exit 1
  fi
elif [ "$action" = stop ]; then
  # stop
  if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
    myecho "server ${screenName} told to stop at $(date)"
    stopCmd
  else
    echo "server ${screenName} not running!"
    exit 1
  fi
elif [ "$action" = status ]; then
  # status
  if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
    echo -n "server ${screenName} running:"
    if [ -f "hardcopy.0" ]; then
      rm "hardcopy.0"
    fi
    screen -r "${screenName}" -p 0 -X hardcopy
    sleep 0.1
    if [ -f "hardcopy.0" ]; then
      mv -f "hardcopy.0" lastStatus.log
      echo "($(tac lastStatus.log |egrep -m 1 .))"
      #echo "$(head -n 6 lastStatus.log)"
    else
      echo "screen no hardcopy found: ${serverLoc}, $(pwd)"
      exit 1
    fi
  else
    echo "server ${screenName} not running"
  fi
  if screen -ls "${backupScreenName}" | grep -q "\.${backupScreenName}\s"; then
  echo -n "server ${backupScreenName} running:"
    if [ -f "hardcopy.0" ]; then
      rm "hardcopy.0"
    fi
    screen -r "${backupScreenName}" -p 0 -X hardcopy
    sleep 0.1
    if [ -f "hardcopy.0" ]; then
      mv -f "hardcopy.0" lastStatusBackup.log
      echo "($(tac lastStatusBackup.log |egrep -m 1 .))"
      #echo "$(head -n 6 lastStatusBackup.log)"
    else
      echo "screen backup no hardcopy found: ${serverLoc}, $(pwd)"
      exit 1
    fi
  fi
  if screen -ls "${updateScreenName}" | grep -q "\.${updateScreenName}\s"; then
  echo -n "server ${updateScreenName} running:"
    if [ -f "hardcopy.0" ]; then
      rm "hardcopy.0"
    fi
    screen -r "${updateScreenName}" -p 0 -X hardcopy
    sleep 0.1
    if [ -f "hardcopy.0" ]; then
      mv -f "hardcopy.0" lastStatusUpdate.log
      echo "($(tac lastStatusUpdate.log |egrep -m 1 .))"
      #echo "$(head -n 6 lastStatusUpdate.log)"
    else
      echo "screen update no hardcopy found: ${serverLoc}, $(pwd)"
      exit 1
    fi
  fi
elif [ "$action" = backup ]; then
  # backup
  if [ "${server_running}" = false ] || [ "${wait_server}" = true ]; then
    if ! screen -ls "${backupScreenName}" | grep -q "\.${backupScreenName}\s"; then
      myecho "server ${screenName} told to do a backup in ${sleepTime}s at $(date)"
      screen -d -m -S "${backupScreenName}" "scripts/doSafeBackup.sh" --sleep "${sleepTime}" --wait-update "${wait_update}" --full-backup "${full_backup}"
    else
      echo "backup script already running!"
      exit 1
    fi
  else
    echo "server ${screenName} currently running"
    exit 1
  fi
elif [ "$action" = update ]; then
  # update
  if [ "${server_running}" = false ] || [ "${wait_server}" = true ]; then
    if ! screen -ls "${updateScreenName}" | grep -q "\.${updateScreenName}\s"; then
      myecho "server ${screenName} told to update in ${sleepTime}s at $(date)"
      screen -d -m -S "${updateScreenName}" "scripts/doSafeUpdate.sh" --sleep "${sleepTime}" --wait-backup "${wait_backup}"
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
