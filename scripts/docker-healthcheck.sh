#!/bin/bash
if [ ! -f "/external/avahi/not-mounted" ]; then
  [[ $(ps aux | grep '[0-9] [s]mbd \|[r]unsvdir' | wc -l) -ge '2' ]]
  exit $?
else
  [[ $(ps aux | grep '[0-9] [s]mbd \|[a]vahi-daemon\|[r]unsvdir' | wc -l) -ge '3' ]]
  exit $?
fi
