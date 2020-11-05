#!/bin/bash
[[ $(ps aux | grep '[s]mbd -d\|[a]vahi-daemon\|[r]unsvdir' | wc -l) -ge '3' ]]
exit $?
