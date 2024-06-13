#!/bin/sh -x

tar cf variants.tar --exclude .git/ --exclude variants.tar .

mkdir -p variants/smbd-only variants/smbd-avahi variants/smbd-wsdd2


cd variants/smbd-only
tar xf ../../variants.tar
cat Dockerfile | grep -v avahi | grep -v wsdd2 > Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/runit/avahi
rm -rf config/runit/wsdd2

sed -i.bak '/avahi/d' ./scripts/docker-healthcheck.sh && rm ./scripts/docker-healthcheck.sh.sh.bak
sed -i.bak '/WSD/d' ./scripts/docker-healthcheck.sh && rm ./scripts/docker-healthcheck.sh.sh.bak

sed -i.bak 's/:$TAG" --push/:smbd-only-$TAG" --push/g' build.sh && rm build.sh.bak
sed -i.bak 's/:[l]atest/:smbd-only-latest/g' build.sh && rm build.sh.bak

cd ../../


cd variants/smbd-avahi
tar xf ../../variants.tar
cat Dockerfile | grep -v wsdd2 > Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/runit/wsdd2

sed -i.bak '/WSD/d' ./scripts/docker-healthcheck.sh && rm ./scripts/docker-healthcheck.sh.sh.bak

sed -i.bak 's/:$TAG" --push/:smbd-avahi-$TAG" --push/g' build.sh && rm build.sh.bak
sed -i.bak 's/:[l]atest/:smbd-avahi-latest/g' build.sh && rm build.sh.bak

cd ../../


cd variants/smbd-wsdd2
tar xf ../../variants.tar
cat Dockerfile | grep -v avahi > Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/runit/avahi

sed -i.bak '/avahi/d' ./scripts/docker-healthcheck.sh && rm ./scripts/docker-healthcheck.sh.sh.bak

sed -i.bak 's/:$TAG" --push/:smbd-wsdd2-$TAG" --push/g' build.sh && rm build.sh.bak
sed -i.bak 's/:[l]atest/:smbd-wsdd2-latest/g' build.sh && rm build.sh.bak

cd ../../
