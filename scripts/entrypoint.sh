#!/bin/bash

export IFS=$'\n'

cat <<EOF
################################################################################

Welcome to the servercontainers/samba

################################################################################


 <service>
   <type>_device-info._tcp</type>
   <port>0</port>
   <txt-record>model=RackMac</txt-record>
 </service>
 <service>
   <type>_adisk._tcp</type>
   <txt-record>sys=waMa=0,adVF=0x100</txt-record>
   <txt-record>dk0=adVN=TimeMachine,adVF=0x82</txt-record>
 </service>

EOF

INITALIZED="/.initialized"

if [ ! -f "$INITALIZED" ]; then
  echo ">> CONTAINER: starting initialisation"

  cp /container/config/samba/smb.conf /etc/samba/smb.conf
  cp /container/config/avahi/samba.service /etc/avahi/services/samba.service
  
  ##
  # MAIN CONFIGURATION
  ##
  if [ -z ${SAMBA_CONF_WORKGROUP+x} ]
  then
    SAMBA_CONF_WORKGROUP="WORKGROUP"
    echo ">> SAMBA CONFIG: no \$SAMBA_CONF_WORKGROUP set, using '$SAMBA_CONF_WORKGROUP'"
  fi
  echo '   workgroup = '"$SAMBA_CONF_WORKGROUP" >> /etc/samba/smb.conf

  if [ -z ${SAMBA_CONF_SERVER_STRING+x} ]
  then
    SAMBA_CONF_SERVER_STRING="Samba Server"
    echo ">> SAMBA CONFIG: no \$SAMBA_CONF_SERVER_STRING set, using '$SAMBA_CONF_SERVER_STRING'"
  fi
  echo '   server string = '"$SAMBA_CONF_SERVER_STRING" >> /etc/samba/smb.conf

  if [ -z ${SAMBA_CONF_MAP_TO_GUEST+x} ]
  then
    SAMBA_CONF_MAP_TO_GUEST="Bad User"
    echo ">> SAMBA CONFIG: no \$SAMBA_CONF_MAP_TO_GUEST set, using '$SAMBA_CONF_MAP_TO_GUEST'"
  fi
  echo '   map to guest = '"$SAMBA_CONF_MAP_TO_GUEST" >> /etc/samba/smb.conf

  ##
  # GLOBAL CONFIGURATION
  ##
  for I_CONF in $(env | grep '^SAMBA_GLOBAL_CONFIG_')
  do
    CONF_CONF_VALUE=$(echo "$I_CONF" | sed 's/^[^=]*=//g')
    echo ">> global config - adding: '$CONF_CONF_VALUE' to /etc/samba/smb.conf"
    echo '   '"$CONF_CONF_VALUE" >> /etc/samba/smb.conf
  done

  ##
  # USER ACCOUNTS
  ##
  for I_ACCOUNT in $(env | grep '^ACCOUNT_')
  do
    ACCOUNT_NAME=$(echo "$I_ACCOUNT" | cut -d'=' -f1 | sed 's/ACCOUNT_//g' | tr '[:upper:]' '[:lower:]')
    ACCOUNT_PASSWORD=$(echo "$I_ACCOUNT" | sed 's/^[^=]*=//g')

    echo ">> ACCOUNT: adding account: $ACCOUNT_NAME"
    adduser -H -s /bin/false "$ACCOUNT_NAME"
    echo -e "$ACCOUNT_PASSWORD\n$ACCOUNT_PASSWORD" | passwd "$ACCOUNT_NAME"
    echo "$ACCOUNT_PASSWORD\n$ACCOUNT_PASSWORD" | smbpasswd -a "$ACCOUNT_NAME"
    smbpasswd -e "$ACCOUNT_NAME"

    unset $(echo "$I_ACCOUNT" | cut -d'=' -f1)
  done

  ##
  # Samba Volume Config ENVs
  ##
  for I_CONF in $(env | grep '^SAMBA_VOLUME_CONFIG_')
  do
    CONF_CONF_VALUE=$(echo "$I_CONF" | sed 's/^[^=]*=//g')

    # if time machine volume
    if echo "$CONF_CONF_VALUE" | sed 's/;/\n/g' | grep 'fruit:time machine' | grep yes 2>/dev/null >/dev/null;
    then
        sed -i '/<\/service-group>/d' /etc/avahi/services/samba.service

        VOL_NAME=$(echo "$CONF_CONF_VALUE" | sed 's/.*\[\(.*\)\].*/\1/g')
        VOL_PATH=$(echo "$CONF_CONF_VALUE" | tr ';' '\n' | grep path | sed 's/.*= *//g')
        echo ">> TIMEMACHINE: adding volume to zeroconf: $VOL_NAME"
        if [ ! -f "$VOL_PATH/.samba-volume-uuid" ]
        then
          UUID=$(cat /proc/sys/kernel/random/uuid)
          echo "$UUID" > "$VOL_PATH/.samba-volume-uuid"
          echo ">> TIMEMACHINE: creating new random uuid: $UUID"
        fi
        UUID=$(cat "$VOL_PATH/.samba-volume-uuid")

        [ -z ${MODEL+x} ] && MODEL="TimeCapsule"

        if ! grep '<txt-record>model=' /etc/avahi/services/samba.service 2> /dev/null >/dev/null;
        then
          echo ">> TIMEMACHINE: zeroconf model: $MODEL"
          echo '
  <service>
   <type>_device-info._tcp</type>
   <port>0</port>
   <txt-record>model='"$MODEL"'</txt-record>
  </service>' >> /etc/avahi/services/samba.service
        fi

        NUMBER=$(env | grep 'fruit:time machine' | grep -n "$VOL_PATH" | grep "\[$VOL_NAME\]" | sed 's/^\([0-9]*\):.*/\1/g' | head -n1)

        echo '
  <service>
   <type>_adisk._tcp</type>
   <txt-record>sys=waMa=0,adVF=0x100,adVU='"$UUID"'</txt-record>
   <txt-record>dk'"$NUMBER"'=adVN='"$VOL_NAME"',adVF=0x82</txt-record>
  </service>
</service-group>' >> /etc/avahi/services/samba.service
    fi

    echo "$CONF_CONF_VALUE" | sed 's/;/\n/g' >> /etc/samba/smb.conf
    if echo "$CONF_CONF_VALUE" | sed 's/;/\n/g' | grep 'fruit:time machine' | grep yes 2>/dev/null >/dev/null;
    then
        echo ">> TIMEMACHINE: updating volume config: $VOL_NAME ($VOL_PATH)"
        cat '
  durable handles = yes
  kernel oplocks = no
  kernel share modes = no
  posix locking = no
  vfs objects = catia fruit streams_xattr
  ea support = yes
  inherit acls = yes
' >> /etc/samba/smb.conf
    fi
    echo "" >> /etc/samba/smb.conf

  done

  echo ">> ZEROCONF: samba.service file"
  echo "############################### START ####################################"
  cat /etc/avahi/services/samba.service
  echo "################################ END #####################################"

  if [ ! -f "/external/avahi/not-mounted" ]
  then
    echo ">> EXTERNAL AVAHI: found external avahi, now maintaining avahi service file 'samba.service'"
    echo ">> EXTERNAL AVAHI: internal avahi gets disabled"
    rm -rf /container/config/runit/avahi
    cp /etc/avahi/services/samba.service /external/avahi/samba.service
    chmod a+rw /external/avahi/samba.service
    echo ">> EXTERNAL AVAHI: list of services"
    ls -l /external/avahi/*.service
  fi

  touch "$INITALIZED"
else
  echo ">> CONTAINER: already initialized - direct start of samba"
fi

##
# CMD
##
echo ">> CMD: exec docker CMD"
echo "$@"
exec "$@"
