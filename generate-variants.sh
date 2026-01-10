#!/bin/sh -x

tar cf variants.tar --exclude-ignore=.dockerignore .

mkdir -p variants/smbd-only variants/smbd-avahi variants/smbd-wsdd2


# create smbd-only variant
cd variants/smbd-only
tar xf ../../variants.tar
cat Dockerfile | grep -v avahi | grep -v wsdd2 > Dockerfile.new
echo "ENV WSDD2_DISABLE=disabled" >> Dockerfile.new
echo "ENV AVAHI_DISABLE=disabled" >> Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/avahi
rm -rf config/runit/avahi
rm -rf config/runit/wsdd2

sed -i '/avahi/d' ./scripts/docker-healthcheck.sh
sed -i '/WSD/d' ./scripts/docker-healthcheck.sh

sed -i 's/:$TAG" --push/:smbd-only-$TAG" --push/g' build.sh
sed -i 's/:[l]atest/:smbd-only-latest/g' build.sh

# build variant if invocation mentions build
echo "$@" | grep "build-image" && ./build.sh "variant" "$@"

cd ../../

# create smbd-avahi variant
cd variants/smbd-avahi
tar xf ../../variants.tar
cat Dockerfile | grep -v wsdd2 > Dockerfile.new
echo "ENV WSDD2_DISABLE=disabled" >> Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/runit/wsdd2

sed -i '/WSD/d' ./scripts/docker-healthcheck.sh

sed -i 's/:$TAG" --push/:smbd-avahi-$TAG" --push/g' build.sh
sed -i 's/:[l]atest/:smbd-avahi-latest/g' build.sh

# build variant if invocation mentions build
echo "$@" | grep "build-image" && ./build.sh "variant" "$@"

cd ../../


# create smbd-wsdd2 variant
cd variants/smbd-wsdd2
tar xf ../../variants.tar
cat Dockerfile | grep -v avahi > Dockerfile.new
echo "ENV AVAHI_DISABLE=disabled" >> Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/avahi
rm -rf config/runit/avahi

sed -i '/avahi/d' ./scripts/docker-healthcheck.sh

sed -i 's/:$TAG" --push/:smbd-wsdd2-$TAG" --push/g' build.sh
sed -i 's/:[l]atest/:smbd-wsdd2-latest/g' build.sh

# build variant if invocation mentions build
echo "$@" | grep "build-image" && ./build.sh "variant" "$@"

cd ../../
