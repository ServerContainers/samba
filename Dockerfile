FROM alpine AS wsdd2-builder

# Temporary fix for Alpine 3.23
RUN apk upgrade --no-cache --no-scripts apk-tools

RUN apk add --no-cache make gcc libc-dev linux-headers && wget -O - https://github.com/Netgear/wsdd2/archive/refs/heads/master.tar.gz | tar zxvf - \
 && cd wsdd2-master && sed -i 's/-O0/-O0 -Wno-int-conversion/g' Makefile && make

FROM alpine
# alpine:3.14

COPY --from=wsdd2-builder /wsdd2-master/wsdd2 /usr/sbin

ENV PATH="/container/scripts:${PATH}"

# Temporary fix for Alpine 3.23
RUN apk upgrade --no-cache --no-scripts apk-tools

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

VOLUME ["/shares"]

EXPOSE 137/udp 139 445

COPY . /container/

HEALTHCHECK CMD ["/container/scripts/docker-healthcheck.sh"]
ENTRYPOINT ["/container/scripts/entrypoint.sh"]

CMD [ "runsvdir","-P", "/container/config/runit" ]
