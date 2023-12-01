#!/bin/sh
NUM_OF_SERVICES=2
[ -z ${AVAHI_DISABLE+x} ] && [ -f "/external/avahi/not-mounted" ] && NUM_OF_SERVICES=$(expr $NUM_OF_SERVICES + 1)
[ -z ${WSDD2_DISABLE+x} ] && NUM_OF_SERVICES=$(expr $NUM_OF_SERVICES + 1)
[ -z ${NETBIOS_DISABLE+x} ] && NUM_OF_SERVICES=$(expr $NUM_OF_SERVICES + 1)

[[ $(ps aux | grep '[0-9] [s]mbd \|/[w]sdd2\|[a]vahi-daemon: r\|[r]unsvdir\|[n]mbd ' | wc -l) -ge "$NUM_OF_SERVICES" ]]
exit $?