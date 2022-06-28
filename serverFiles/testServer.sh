#!/bin/bash
echo "starting server from $(pwd)"

user_input="none"
while [ ! "$user_input" = "stop" ]; do
  sleep 1
  read user_input
  echo "$user_input"
done

sleep 1
echo "stopping server"
exit 0
