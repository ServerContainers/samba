#!/bin/bash

chown nobody:nogroup "$1"
chmod 777 "$1"

if [ ! -e "$1/$2" ]; then
  mkdir "$1/$2"
  chown $2:$2 "$1/$2"
  chmod -R 700 "$1/$2"
fi
exit 0
