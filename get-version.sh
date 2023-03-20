#!/bin/sh
if [ -z ${SAMBA_VERSION+x} ] || [ -z ${ALPINE_VERSION+x} ]; then
  IMG=$(docker-compose build --pull --no-cache | grep "exporting config" | tr ' ' '\n' | grep '^sha256:')
  export SAMBA_VERSION=$(docker run --rm -ti "$IMG" apk list 2>/dev/null | grep '\[installed\]' | grep "samba-[0-9]" | cut -d " " -f1 | sed 's/samba-//g' | tr -d '\r')
  export ALPINE_VERSION=$(docker run --rm -ti "$IMG" cat /etc/alpine-release | tail -n1 | tr -d '\r')
fi
echo "a$ALPINE_VERSION-s$SAMBA_VERSION"

