#!/bin/bash
VERSION=1

echo "starting server version ${VERSION} from $(pwd)"

user_input="none"
while [ ! "$user_input" = "stop" ]; do
  sleep 1
  read user_input
  echo "$user_input"
  if [[ $user_input = save ]]; then
    save_content="save content $RANDOM"
    echo "saving: ${save_content}"
    echo "${save_content}" > save_file.txt
  elif [[ $user_input = load ]]; then
    save_content="$(cat save_file.txt)"
    echo "loaded: ${save_content}"
  fi
done

sleep 1
echo "stopping server"
exit 0
