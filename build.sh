#!/bin/sh

IMG="martijndierckx/samba"
PLATFORM="linux/amd64"

UBUNTU_VERSION=22.04

SAMBA_V_OUPUT=$(docker run --rm -ti ubuntu:22.04 /bin/bash -c "apt -qq update 2> /dev/null && apt show samba 2> /dev/null")
SAMBA_VERSION=$(echo "$SAMBA_V_OUPUT" | grep "Version: " | grep "[0-9]:[0-9\.]\+" -o | sed "s/[0-9]://g")

docker buildx build --push --platform "$PLATFORM" --tag "$IMG:$SAMBA_VERSION" --tag "$IMG:latest" .