#!/bin/bash

isdir=false
target="$1"
output="$2"
shift
shift

if [ ! -e "${target}" ]; then
  echo "Target not found:${target}"
  exit 1
fi
if [ -d "${target}" ] && [ -r "${target}" ]; then
  isdir=true
elif [ -f "${target}" ] && [ -r "${target}" ]; then
  isdir=false
else
  echo "Invalid target:${target}"
  exit 1
fi

backup_dir="backups/${output}"
backup_name="${backup_dir}/${output}_$(date +%F-%Hh%M)"
if [ -e "${backup_name}" ]; then
  echo "backup already exists: ${backup_name}"
  exit 1
fi

mkdir -p "${backup_dir}"
if [ ! -d "${backup_dir}" ] || [ ! -w "${backup_dir}" ]; then
  echo "Invalid backup directory:${target}"
  exit 1
fi
if [ "${isdir}" = true ]; then
  echo "Backing up directory \"${target}\" at \"${backup_name}\""
  cp -r "${target}" "${backup_name}"
else
  echo "Backing up file \"${target}\" at \"${backup_name}\""
  cp "${target}" "${backup_name}"
fi

exit 0
