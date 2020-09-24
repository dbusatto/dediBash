#!/bin/bash
if [[ ! "$0" == /* ]]; then
  dirtyServerLoc="$(pwd)/$0"
else
  dirtyServerLoc="$0"
fi
cd "$(dirname ${dirtyServerLoc})"
cd ..
serverLoc="$(pwd)"

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

if [ ! -d "backups" ]; then
  echo "no backups"
  exit 1
fi
echo "#!/bin/bash" > backups/clean.sh
echo "" >> backups/clean.sh
for target in $(ls backups); do
  if [ -d "backups/${target}" ]; then
  echo "backups of ${target}:"
  patternEntry="${target}_([0-9]+)-([0-9]+)-([0-9]+)-([0-9]+)h([0-9]+)"
  enum=0
  tSize=0
  if [ ! -d "backups/${target}" ] || [ ! -r "backups/${target}" ]  || [ ! -w "backups/${target}" ]; then
    echo "bad target:${target}"
    exit 1
  fi
  minBackups=10
  maxBackups=100
  maxBackupsSize=53687091200
  if [ -f "backups/${target}/config_backups.cfg" ]; then
    echo -n "using config file:"
    . "backups/${target}/config_backups.cfg"
    patternInt="[^0-9]"
    if [[ $minBackups =~ $patternInt ]] || [[ $maxBackups =~ $patternInt ]] || [[ $maxBackupsSize =~ $patternInt ]] || [ $maxBackups -lt $minBackups ]; then
      echo "bad config: ${target}"
      exit 1
    fi
  else
    echo -n "no config found, using default:"
  fi
  maxBackupsSizeHR=$(bytesToHuman ${maxBackupsSize})
  echo "minBackups=$minBackups, maxBackups=$maxBackups, maxBackupsSize=$maxBackupsSizeHR"
  for entry in $(ls -r "backups/${target}"); do
    if [[ $entry =~ $patternEntry ]]; then
        eYear="${BASH_REMATCH[1]}"
        eMonth="${BASH_REMATCH[2]}"
        eDay="${BASH_REMATCH[3]}"
        eHour="${BASH_REMATCH[4]}"
        eMinute="${BASH_REMATCH[5]}"
        #eSize="$(du -hs "backups/${target}/${entry}")"
        enum=$((enum+1))
        eSize=$(du "backups/${target}/${entry}" -sb | cut -f 1)
        tSize=$((tSize+$eSize))
        eSizeHR=$(bytesToHuman ${eSize})
        tSizeHR=$(bytesToHuman ${tSize})
        if ( [ ${enum} -le ${minBackups} ] || [ ${tSize} -le ${maxBackupsSize} ] ) && [ ${enum} -le ${maxBackups} ] ; then
          eDel=false
        else
          eDel=true
        fi
        if [ -d "backups/${target}/${entry}" ]; then
            if [ ${eDel} = false ]; then
              echo "directory ${enum} | ${eSizeHR}: date ${eDay}/${eMonth}/${eYear} ${eHour}h${eMinute}, total ${tSizeHR}"
            else
              echo "directory ${enum} | ${eSizeHR}: date ${eDay}/${eMonth}/${eYear} ${eHour}h${eMinute}, total ${tSizeHR} (to delete)"
              echo "rm -r \"backups/${target}/${entry}\"" >> backups/clean.sh
            fi
        elif [ -f "backups/${target}/${entry}" ]; then
            if [ ${eDel} = false ]; then
              echo "file ${enum} | ${eSizeHR}: date ${eDay}/${eMonth}/${eYear} ${eHour}h${eMinute}, total ${tSizeHR}"
            else
              echo "file ${enum} | ${eSizeHR}: date ${eDay}/${eMonth}/${eYear} ${eHour}h${eMinute}, total ${tSizeHR} (to delete)"
              echo "rm \"backups/${target}/${entry}\"" >> backups/clean.sh
            fi
        else
          echo "entry error:${entry}"
          exit 1
        fi
    elif [ ! ${entry} = config.cfg ]; then
      echo "ignoring entry backups/${target}/${entry}"
    fi
  done
  elif [ ! ${target} = clean.sh ] && [ ! ${target} = config.cfg ]; then
    echo "ignoring file backups/${target}"
  fi
done
chmod +x backups/clean.sh
echo "=== execute backups/clean.sh to clean backups. Will perform: ==="
echo "$(cat backups/clean.sh)"

exit 0
