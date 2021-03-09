#!/bin/bash
if [ ! -f "/external/avahi/not-mounted" ]; then
  [[ $(ps aux | grep '[s]mbd -d\|[r]unsvdir' | wc -l) -ge '2' ]]
  exit $?
else
  [[ $(ps aux | grep '[s]mbd -d\|[a]vahi-daemon\|[r]unsvdir' | wc -l) -ge '3' ]]
  exit $?
fi
