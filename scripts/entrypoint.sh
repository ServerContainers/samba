#!/bin/bash

export IFS=$'\n'

cat <<EOF
################################################################################

Welcome to the servercontainers/samba

################################################################################

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

    ACCOUNT_UID=$(env | grep '^UID_'"$ACCOUNT_NAME" | sed 's/^[^=]*=//g')

    if [ "$ACCOUNT_UID" -gt 0 ] 2>/dev/null
    then
      echo ">> ACCOUNT: adding account: $ACCOUNT_NAME with UID: $ACCOUNT_UID"
      adduser -D -H -u "$ACCOUNT_UID" -s /bin/false "$ACCOUNT_NAME"
    else
      echo ">> ACCOUNT: adding account: $ACCOUNT_NAME"
      adduser -D -H -s /bin/false "$ACCOUNT_NAME"
    fi
    smbpasswd -a -n "$ACCOUNT_NAME"

    if echo "$ACCOUNT_PASSWORD" | grep ':$' | grep '^'"$ACCOUNT_NAME"':[0-9]*:'  >/dev/null 2>/dev/null
    then
      echo ">> ACCOUNT: found SMB Password HASH instead of plain-text password"
      CLEAN_HASH=$(echo "$ACCOUNT_PASSWORD" | sed 's/^.*:[0-9]*://g')
      sed -i 's/\('"$ACCOUNT_NAME"':[0-9]*:\).*/\1'"$CLEAN_HASH"'/g' /var/lib/samba/private/smbpasswd
    else
      echo -e "$ACCOUNT_PASSWORD\n$ACCOUNT_PASSWORD" | passwd "$ACCOUNT_NAME"
      echo -e "$ACCOUNT_PASSWORD\n$ACCOUNT_PASSWORD" | smbpasswd "$ACCOUNT_NAME"
    fi
    
    smbpasswd -e "$ACCOUNT_NAME"

    unset $(echo "$I_ACCOUNT" | cut -d'=' -f1)
  done

  echo '' >> /etc/samba/smb.conf

  ##
  # Samba Volume Config ENVs
  ##
  for I_CONF in $(env | grep '^SAMBA_VOLUME_CONFIG_')
  do
    CONF_CONF_VALUE=$(echo "$I_CONF" | sed 's/^[^=]*=//g')

    # if time machine volume
    if echo "$CONF_CONF_VALUE" | sed 's/;/\n/g' | grep 'fruit:time machine' | grep yes 2>/dev/null >/dev/null;
    then
        # remove </service-group> only if this is the first time a timemachine volume was added
        grep '<txt-record>dk' /etc/avahi/services/samba.service 2> /dev/null >/dev/null || sed -i '/<\/service-group>/d' /etc/avahi/services/samba.service

        VOL_NAME=$(echo "$CONF_CONF_VALUE" | sed 's/.*\[\(.*\)\].*/\1/g')
        VOL_PATH=$(echo "$CONF_CONF_VALUE" | tr ';' '\n' | grep path | sed 's/.*= *//g')
        echo ">> TIMEMACHINE: adding volume to zeroconf: $VOL_NAME"

        [ -z ${MODEL+x} ] && MODEL="TimeCapsule"
        sed -i 's/TimeCapsule/'"$MODEL"'/g' /etc/samba/smb.conf

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

        if ! echo "$VOL_PATH" | grep '%U' 2>/dev/null >/dev/null; then
          echo ">> TIMEMACHINE: fix permissions (only last one wins.. for multiple users I recommend using multi user mode - see README.md)"
          VALID_USERS=$(echo "$CONF_CONF_VALUE" | tr ';' '\n' | grep 'valid users' | sed 's/.*= *//g')
          for user in $VALID_USERS; do
            echo "  user: $user"
            chown $user.$user -R "$VOL_PATH"
          done
          chmod 700 -R "$VOL_PATH"
        fi

        [ ! -z ${NUMBER+x} ] && NUMBER=$(expr $NUMBER + 1)
        [ -z ${NUMBER+x} ] && NUMBER=0

        if ! grep '<txt-record>dk' /etc/avahi/services/samba.service 2> /dev/null >/dev/null;
        then
          # for first time add complete service
          echo '
 <service>
  <type>_adisk._tcp</type>
  <txt-record>sys=waMa=0,adVF=0x100</txt-record>
  <txt-record>dk'"$NUMBER"'=adVN='"$VOL_NAME"',adVF=0x82</txt-record>
 </service>
</service-group>' >> /etc/avahi/services/samba.service
        else
          # from the second one only append new txt-record
          REPLACE_ME=$(grep '<txt-record>dk' /etc/avahi/services/samba.service | tail -n 1)
          sed -i 's;'"$REPLACE_ME"';'"$REPLACE_ME"'\n  <txt-record>dk'"$NUMBER"'=adVN='"$VOL_NAME"',adVF=0x82</txt-record>;g' /etc/avahi/services/samba.service
        fi
    fi

    echo "$CONF_CONF_VALUE" | sed 's/;/\n/g' >> /etc/samba/smb.conf
    if echo "$CONF_CONF_VALUE" | sed 's/;/\n/g' | grep 'fruit:time machine' | grep yes 2>/dev/null >/dev/null;
    then
        echo ">> TIMEMACHINE: updating volume config: $VOL_NAME ($VOL_PATH)"
        echo ' fruit:metadata = stream
 durable handles = yes
 kernel oplocks = no
 kernel share modes = no
 posix locking = no
 vfs objects = catia fruit streams_xattr
 ea support = yes
 inherit acls = yes
' >> /etc/samba/smb.conf
     
        if echo "$VOL_PATH" | grep '%U' 2>/dev/null >/dev/null; 
        then
          VOL_PATH_BASE=$(echo "$VOL_PATH" | sed 's,/%U$,,g')
          echo ">> TIMEMACHINE: multiuser config found! - $VOL_PATH"
          echo 'root preexec = /container/scripts/samba_create_timemachine_user_dir.sh '"$VOL_PATH_BASE"' %U' >> /etc/samba/smb.conf
        fi

    fi

    echo "" >> /etc/samba/smb.conf

  done

  [ ! -z ${AVAHI_NAME+x} ] && echo ">> ZEROCONF: custom avahi samba.service name: $AVAHI_NAME" && sed -i 's/%h/'"$AVAHI_NAME"'/g' /etc/avahi/services/samba.service

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
