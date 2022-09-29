FROM ubuntu:22.04

ENV PATH="/container/scripts:${PATH}"

RUN apt update && apt install runit avahi-daemon samba samba-common samba-client wsdd2 -y \
 && sed -i 's/#enable-dbus=.*/enable-dbus=no/g' /etc/avahi/avahi-daemon.conf \
 && rm -vf /etc/avahi/services/* \
 \
 && mkdir -p /external/avahi \
 && touch /external/avahi/not-mounted \
 && echo done

VOLUME ["/shares"]

EXPOSE 139 445

COPY . /container/

HEALTHCHECK --interval=60s --timeout=15s \
 CMD smbclient -L \\localhost -U % -m SMB3

ENTRYPOINT ["/container/scripts/entrypoint.sh"]

CMD [ "runsvdir","-P", "/container/config/runit" ]