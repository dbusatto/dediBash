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
if screen -ls "${screenName}" | grep -q "\.${screenName}\s"; then
  ./myServer.sh stop
  sleep 1
  ./myServer.sh backup --wait-server --full-backup
  sleep 1
  ./myServer.sh update --wait-server --wait-backup
  sleep 1
  ./myServer.sh start --wait-server --wait-backup --wait-update
elif [ "${ifNeeded}" = false ]; then
  ./myServer.sh backup --full-backup
  sleep 1
  ./myServer.sh update --wait-backup
fi
exit 0
