#!/bin/sh -x
[ -z "$DOCKER_REGISTRY" ] && echo "error please specify docker-registry DOCKER_REGISTRY" && exit 1
IMG="$DOCKER_REGISTRY/samba"

PLATFORM="linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6"

rm -rf variants.tar variants/ 2>/dev/null >/dev/null

TAG=$(./get-version.sh)

if echo "$@" | grep -v "force" 2>/dev/null >/dev/null; then
  echo "check if image was already build and pushed - skip check on release version"
  echo "$@" | grep -v "release" && docker pull "$IMG:$TAG" 2>/dev/null >/dev/null && echo "image already build" && exit 1
fi

docker buildx build -q --pull --no-cache --platform "$PLATFORM" -t "$IMG:$TAG" --push .

echo "$@" | grep "release" 2>/dev/null >/dev/null && echo ">> releasing new latest" && docker buildx build -q --pull --platform "$PLATFORM" -t "$IMG:latest" --push .

# make sure this is only executed in main script
echo "$@" | grep "variant" && exit 0 


tar cf variants.tar --exclude .git/ --exclude variants.tar .

mkdir -p variants/smbd-only variants/smbd-avahi variants/smbd-wsdd2


cd variants/smbd-only
tar xf ../../variants.tar
cat Dockerfile | grep -v avahi | grep -v wsdd2 > Dockerfile.new
echo "ENV WSDD2_DISABLE=true" >> Dockerfile.new
echo "ENV AVAHI_DISABLE=true" >> Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/avahi config/runit/avahi
rm -rf config/runit/wsdd2

sed -i.bak 's/:$TAG" --push/:smbd-only-$TAG" --push/g' build.sh && rm build.sh.bak
sed -i.bak 's/:[l]atest/:smbd-only-latest/g' build.sh && rm build.sh.bak

./build.sh "variant" "$@"

cd ../../


cd variants/smbd-avahi
tar xf ../../variants.tar
cat Dockerfile | grep -v wsdd2 > Dockerfile.new
echo "ENV WSDD2_DISABLE=true" >> Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/runit/wsdd2

sed -i.bak 's/:$TAG" --push/:smbd-avahi-$TAG" --push/g' build.sh && rm build.sh.bak
sed -i.bak 's/:[l]atest/:smbd-avahi-latest/g' build.sh && rm build.sh.bak

./build.sh "variant" "$@"

cd ../../


cd variants/smbd-wsdd2
tar xf ../../variants.tar
cat Dockerfile | grep -v avahi > Dockerfile.new
echo "ENV AVAHI_DISABLE=true" >> Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/avahi config/runit/avahi

sed -i.bak 's/:$TAG" --push/:smbd-wsdd2-$TAG" --push/g' build.sh && rm build.sh.bak
sed -i.bak 's/:[l]atest/:smbd-wsdd2-latest/g' build.sh && rm build.sh.bak

./build.sh "variant" "$@"

cd ../../
