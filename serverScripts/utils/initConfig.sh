#!/bin/bash
# must run after initVars.sh and with a set myecho

cd "${startDir}"
if [[ $configFileDirty != /* ]]; then
  dirtyConfigFile="$(pwd)/${configFileDirty}"
else
  dirtyConfigFile="${configFileDirty}"
fi
cd "$(dirname "$dirtyConfigFile")"

configDir="$(pwd)"
configFile="${configDir}/$(basename "${configFileDirty}")"

cd "${binDir}"

if [[ ! -f $configFile || ! -r $configFile || ! -x $configFile ]]; then
  myecho "file ${configFile} not found from directory ${startDir} or has bad permissions (needs at least r-x)"
  exit 1
fi
. "${configFile}"
if [[ -z $screenName ]]; then
  myecho "bad config load, no screenName found"
  exit 1
fi

backupScreenName="${screenName}Backup"
updateScreenName="${screenName}Update"
