#!/bin/sh -x

IMG="servercontainers/samba"

PLATFORM="linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6"

rm -rf variants.tar variants/ 2>/dev/null >/dev/null

if [ -z ${SAMBA_VERSION+x} ] || [ -z ${SAMBA_VERSION+x} ]; then
  docker-compose build -q --pull --no-cache
  export SAMBA_VERSION=$(docker run --rm -ti "$IMG" smbd -V | tail -n1 | cut -d' ' -f2 | tr -d '\r')
  export ALPINE_VERSION=$(docker run --rm -ti "$IMG" cat /etc/alpine-release | tail -n1 | tr -d '\r')
fi

docker buildx build -q --pull --no-cache --platform "$PLATFORM" -t "$IMG:a$ALPINE_VERSION-s$SAMBA_VERSION" --push .

echo "$@" | grep "release" 2>/dev/null >/dev/null && echo ">> releasing new latest" && docker buildx build -q --pull --platform "$PLATFORM" -t "$IMG:latest" --push .

# make sure this is only executed in main script
echo "$@" | grep "variant" && exit 0 


tar cf variants.tar --exclude .git/ --exclude variants.tar .

mkdir -p variants/smbd-only variants/smbd-avahi variants/smbd-wsdd2


cd variants/smbd-only
tar xf ../../variants.tar
cat Dockerfile | grep -v avahi | grep -v wsdd2 > Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/avahi config/runit/avahi
rm -rf config/runit/wsdd2

sed -i.bak 's/:[a]/:smbd-only-a/g' build.sh && rm build.sh.bak
sed -i.bak 's/:[l]atest/:smbd-only-latest/g' build.sh && rm build.sh.bak

./build.sh "variant" "$@"

cd ../../


cd variants/smbd-avahi
tar xf ../../variants.tar
cat Dockerfile | grep -v wsdd2 > Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/runit/wsdd2

sed -i.bak 's/:[a]/:smbd-avahi-a/g' build.sh && rm build.sh.bak
sed -i.bak 's/:[l]atest/:smbd-avahi-latest/g' build.sh && rm build.sh.bak

./build.sh "variant" "$@"

cd ../../


cd variants/smbd-wsdd2
tar xf ../../variants.tar
cat Dockerfile | grep -v avahi > Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/avahi config/runit/avahi

sed -i.bak 's/:[a]/:smbd-wsdd2-a/g' build.sh && rm build.sh.bak
sed -i.bak 's/:[l]atest/:smbd-wsdd2-latest/g' build.sh && rm build.sh.bak

./build.sh "variant" "$@"

cd ../../