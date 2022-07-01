#!/usr/bin/expect
set timeout 20

spawn telnet localhost 8081

expect "Please enter password:"
send "cranszamok\r"
expect "Press \'help\' to get a list of all commands. Press \'exit\' to end session."
send "shutdown\r"
interact
