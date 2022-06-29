#!/bin/bash

. "$(dirname "$0")/utils/initVars.sh"
cd "${binDir}"

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
if [[ -z $screenName ]]; then
  echo "bad config load, no screenName found"
  exit 1
fi
backupScreenName="${screenName}Backup"
updateScreenName="${screenName}Update"

bytesToHuman() {
  b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,E,P,Y,Z}B)
  while ((b > 1024)); do
    d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
    b=$((b / 1024))
    let s++
  done
  echo "$b$d ${S[$s]}"
}

bytesToHuman2() {
    echo "$1"
}

if [[ ! -d $backupsDir ]]; then
  echo "no backups folder"
  exit 1
fi
echo "#!/bin/bash" > "${backupsDir}/clean_backups.sh"
echo "" >> "${backupsDir}/clean_backups.sh"
for target in $(ls "${backupsDir}"); do
  if [ -d "${backupsDir}/${target}" ]; then
  echo "backups of ${target}:"
  patternEntry="${target}_([0-9]+)-([0-9]+)-([0-9]+)-([0-9]+)h([0-9]+)"
  enum=0
  tSize=0
  if [[ ! -d "${backupsDir}/${target}" || ! -r "${backupsDir}/${target}" || ! -w "${backupsDir}/${target}" ]]; then
    echo "bad target:${target}"
    exit 1
  fi
  minBackups=10
  maxBackups=100
  maxBackupsSize=53687091200
  if [ -f "${backupsDir}/${target}/config_backups.cfg" ]; then
    echo -n "using config file:"
    . "${backupsDir}/${target}/config_backups.cfg"
    patternInt="[^0-9]"
    if [[ $minBackups =~ $patternInt || $maxBackups =~ $patternInt || $maxBackupsSize =~ $patternInt ||$maxBackups -lt $minBackups ]]; then
      echo "bad config: ${target}"
      exit 1
    fi
  else
    echo -n "no config found, using default:"
  fi
  maxBackupsSizeHR=$(bytesToHuman ${maxBackupsSize})
  echo "minBackups=$minBackups, maxBackups=$maxBackups, maxBackupsSize=$maxBackupsSizeHR"
  for entry in $(ls -r "${backupsDir}/${target}"); do
    if [[ $entry =~ $patternEntry ]]; then
        eYear="${BASH_REMATCH[1]}"
        eMonth="${BASH_REMATCH[2]}"
        eDay="${BASH_REMATCH[3]}"
        eHour="${BASH_REMATCH[4]}"
        eMinute="${BASH_REMATCH[5]}"
        #eSize="$(du -hs "backups/${target}/${entry}")"
        enum=$((enum+1))
        eSize=$(du "${backupsDir}/${target}/${entry}" -sb | cut -f 1)
        tSize=$((tSize+$eSize))
        eSizeHR=$(bytesToHuman ${eSize})
        tSizeHR=$(bytesToHuman ${tSize})
        if [[ ( $enum -le $minBackups || $tSize -le $maxBackupsSize ) && $enum -le $maxBackups ]] ; then
          eDel=false
        else
          eDel=true
        fi
        if [[ -d "${backupsDir}/${target}/${entry}" ]]; then
            if [[ $eDel = false ]]; then
              echo "directory ${enum} | ${eSizeHR}: date ${eDay}/${eMonth}/${eYear} ${eHour}h${eMinute}, total ${tSizeHR}"
            else
              echo "directory ${enum} | ${eSizeHR}: date ${eDay}/${eMonth}/${eYear} ${eHour}h${eMinute}, total ${tSizeHR} (to delete)"
              echo "rm -r \"${backupsDir}/${target}/${entry}\"" >> "${backupsDir}/clean_backups.sh"
            fi
        elif [ -f "${backupsDir}/${target}/${entry}" ]; then
            if [ ${eDel} = false ]; then
              echo "file ${enum} | ${eSizeHR}: date ${eDay}/${eMonth}/${eYear} ${eHour}h${eMinute}, total ${tSizeHR}"
            else
              echo "file ${enum} | ${eSizeHR}: date ${eDay}/${eMonth}/${eYear} ${eHour}h${eMinute}, total ${tSizeHR} (to delete)"
              echo "rm \"${backupsDir}/${target}/${entry}\"" >> "${backupsDir}/clean_backups.sh"
            fi
        else
          echo "entry error:${entry}"
          exit 1
        fi
    elif [ ! ${entry} = config_backups.cfg ]; then
      echo "ignoring entry backups/${target}/${entry}"
    fi
  done
  elif [ ! ${target} = clean_backups.sh ] && [ ! ${target} = config_backups.cfg ]; then
    echo "ignoring file backups/${target}"
  fi
done
chmod +x "${backupsDir}/clean_backups.sh"
echo "=== execute ${backupsDir}/clean_backups.sh to clean backups. Will perform: ==="
echo "$(cat "${backupsDir}/clean_backups.sh")"

exit 0
