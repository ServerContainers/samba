#!/bin/sh -x
[ -z "$DOCKER_REGISTRY" ] && echo "error please specify docker-registry DOCKER_REGISTRY" && exit 1
IMG="$DOCKER_REGISTRY/samba"

PLATFORM="linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6"

rm -rf variants.tar variants/ 2>/dev/null >/dev/null

TAG=$(./get-version.sh)

if echo "$@" | grep -v "force" 2>/dev/null >/dev/null; then
  # if there was a commit within the last hour, rebuild the container - even if it's already build
  ONE_HOUR_IN_SECONDS=3600
  EPOCH_SINCE_LAST_PUSH=$(git log -1 --format=%cd --date=iso | xargs -I {} date -d "{}" +%s || git log -1 --format=%cd --date=iso | xargs -I {} date -jf '%Y-%m-%d %H:%M:%S %z' "{}" +%s)
  SECONDS_SINCE_LAST_PUSH=$(expr $(date +%s) - $EPOCH_SINCE_LAST_PUSH)
  if [ "$SECONDS_SINCE_LAST_PUSH" -gt "$ONE_HOUR_IN_SECONDS" ]; then
    echo "check if image was already build and pushed - skip check on release version"
    echo "$@" | grep -v "release" && docker pull "$IMG:$TAG" 2>/dev/null >/dev/null && echo "image already build" && exit 1
  else
    echo "commit within the last hour, we skip the version check and try to overwrite current build"
  fi
fi

docker buildx build -q --pull --no-cache --platform "$PLATFORM" -t "$IMG:$TAG" --push .

echo "$@" | grep "release" 2>/dev/null >/dev/null && echo ">> releasing new latest" && docker buildx build -q --pull --platform "$PLATFORM" -t "$IMG:latest" --push .

# make sure to exit if this is only version check
echo "$@" | grep "version-check" && exit 0

# make sure this is only executed in main script
echo "$@" | grep "variant" && exit 0

./generate-variants.sh "build-image"
