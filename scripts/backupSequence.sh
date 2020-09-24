#!/bin/bash
if [[ ! "$0" == /* ]]; then
  dirtyServerLoc="$(pwd)/$0"
else
  dirtyServerLoc="$0"
fi
cd "$(dirname ${dirtyServerLoc})"
cd ..
if [ ! -f config.cfg ] || [ ! -r config.cfg ]; then
  echo "bad directory: $(pwd)"
  exit 1
fi
position="$(pwd)"
. config.cfg
ifNeeded=false
if [ "$1" = --if-needed ]; then
  shift
  ifNeeded=true
fi
backupOpts=""
if [ "$1" = --full-backup ]; then
  shift
  backupOpts="--full-backup"
fi
if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
  ./myServer.sh stop
  sleep 1
  ./myServer.sh backup --wait-server ${backupOpts}
  sleep 1
  ./myServer.sh start --wait-server --wait-backup
elif [ "${ifNeeded}" = false ]; then
  ./myServer.sh backup ${backupOpts}
fi
exit 0

