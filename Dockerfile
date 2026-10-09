FROM alpine AS wsdd2-builder

# upstream Netgear/wsdd2 repo was deleted - use the Debian snapshot orig tarball (immutable archive)
# NOTE: keep 'wsdd2' in every line of this stage - generate-variants.sh strips it via 'grep -v wsdd2'
RUN apk add --no-cache make gcc libc-dev linux-headers && wget -O wsdd2.tar.xz https://snapshot.debian.org/file/28506e4e22bf56ca81edfd348a5fb45d0df02ebf \
 && tar -xJf wsdd2.tar.xz && cd wsdd2-1.8.7 && sed -i 's/-O0/-O0 -Wno-int-conversion/g' Makefile && make

FROM alpine
# alpine:3.14

COPY --from=wsdd2-builder /wsdd2-1.8.7/wsdd2 /usr/sbin

ENV PATH="/container/scripts:${PATH}"

RUN apk add --no-cache runit \
                       tzdata \
                       avahi \
                       samba \
 \
 && sed -i 's/#enable-dbus=.*/enable-dbus=no/g' /etc/avahi/avahi-daemon.conf \
 && rm -vf /etc/avahi/services/* \
 \
 && mkdir -p /external/avahi \
 && touch /external/avahi/not-mounted \
 && echo done

###########################
# DYNAMIC VOLUMES STUFF
###########################
RUN mkdir -p /dynamic-volumes
#RUN apk add --no-cache webhook moreutils yq
RUN apk add --no-cache webhook moreutils py3-pip
RUN pip install crudini --break-system-packages
###########################

VOLUME ["/shares"]

# udp port 137: Netbios Name Service
# udp port 138: Netbios Datagram Service
# tcp port 139: SMB for Windows NT or older
# tcp port 445: SMB for Windows 2000 or newer
# tcp port 9000: Webhook

EXPOSE 137/udp 138/udp 139 445 9000

COPY . /container/

HEALTHCHECK CMD ["/container/scripts/docker-healthcheck.sh"]
ENTRYPOINT ["/container/scripts/entrypoint.sh"]

CMD [ "runsvdir","-P", "/container/config/runit" ]
