#!/bin/bash
export IMG=$(docker build -q --pull --no-cache -t 'get-version' .)
export SAMBA_VERSION=$(docker run --rm -t get-version apk list 2>/dev/null | grep '\[installed\]' | grep "samba-[0-9]" | cut -d " " -f1 | sed 's/samba-//g' | tr -d '\r')
export ALPINE_VERSION=$(docker run --rm -t get-version cat /etc/alpine-release | tail -n1 | tr -d '\r')

[ -z "$ALPINE_VERSION" ] && exit 1

echo "$1a$ALPINE_VERSION-s$SAMBA_VERSION"