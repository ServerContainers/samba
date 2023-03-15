#!/bin/sh -x

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

cd ../../


cd variants/smbd-avahi
tar xf ../../variants.tar
cat Dockerfile | grep -v wsdd2 > Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/runit/wsdd2

sed -i.bak 's/:[a]/:smbd-avahi-a/g' build.sh && rm build.sh.bak
sed -i.bak 's/:[l]atest/:smbd-avahi-latest/g' build.sh && rm build.sh.bak

cd ../../


cd variants/smbd-wsdd2
tar xf ../../variants.tar
cat Dockerfile | grep -v avahi > Dockerfile.new
mv Dockerfile.new Dockerfile
rm -rf config/avahi config/runit/avahi

sed -i.bak 's/:[a]/:smbd-wsdd2-a/g' build.sh && rm build.sh.bak
sed -i.bak 's/:[l]atest/:smbd-wsdd2-latest/g' build.sh && rm build.sh.bak

cd ../../