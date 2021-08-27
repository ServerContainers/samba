FROM alpine AS builder

RUN apk add --no-cache make \
                       gcc \
                       libc-dev \
                       linux-headers \
 && wget -O - https://github.com/Netgear/wsdd2/archive/refs/heads/master.tar.gz | tar zxvf - \
 && cd wsdd2-master \
 && make

FROM alpine
# alpine:3.12

COPY --from=builder /wsdd2-master/wsdd2 /usr/sbin

ENV PATH="/container/scripts:${PATH}"

RUN apk add --no-cache runit \
                       bash \
                       avahi \
                       samba \
 \
 && touch /var/lib/samba/registry.tdb /var/lib/samba/account_policy.tdb \
 \
 && sed -i 's/#enable-dbus=.*/enable-dbus=no/g' /etc/avahi/avahi-daemon.conf \
 && rm -vf /etc/avahi/services/* \
 \
 && mkdir -p /external/avahi \
 && touch /external/avahi/not-mounted

VOLUME ["/shares"]

EXPOSE 139 445

COPY . /container/

HEALTHCHECK CMD ["/container/scripts/docker-healthcheck.sh"]
ENTRYPOINT ["/container/scripts/entrypoint.sh"]

CMD [ "runsvdir","-P", "/container/config/runit" ]
