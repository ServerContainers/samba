#!/bin/sh

export IFS=$'\n'

cat <<EOF
################################################################################

Welcome to the ghcr.io/servercontainers/samba

################################################################################

You'll find this container sourcecode here:

    https://github.com/ServerContainers/samba

The container repository will be updated regularly.

################################################################################


EOF

# clean pids
rm -rf /var/run/* 2>/dev/null >/dev/null
mkdir /run/samba /var/run/samba

INITALIZED="/.initialized"

if [ ! -f "$INITALIZED" ]; then
  echo ">> CONTAINER: starting initialisation"

  cp /container/config/samba/smb.conf /etc/samba/smb.conf
  cp /container/config/avahi/samba.service /etc/avahi/services/samba.service

  ##
  # FRUIT DISABLE
  ##
  if [ ! -z ${DISABLE_FRUIT_DEFAULTS+x} ]
  then
    echo ">> SPECIAL MODE: disable fruit configuration / auto timemachine support - use only for special configurations"
    if env | grep "fruit:time machine" 2>/dev/null > /dev/null; then
        set -e
        echo ">> SPECIAL MODE ERROR: you disabled fruit but configured 'fruit:time machine' - not allowed - exit error"
        exit 1
    fi
    echo ">> SPECIAL MODE: deleting all lines in smb.conf with 'fruit::', 'vfs objects', 'ea support'"
    sed -i -E '/fruit::|vfs objects|ea support/d' /etc/samba/smb.conf
    echo ">> SPECIAL MODE: you can use env variables to have your custom global config - they will be added after this deletion job"
  fi



  ##
  # MAIN CONFIGURATION
  ##
  if [ ! -z ${SAMBA_CONF_SERVER_ROLE+x} ]
  then
    echo ">> SAMBA CONFIG: \$SAMBA_CONF_SERVER_ROLE set, using '$SAMBA_CONF_SERVER_ROLE'"
    sed -i 's$standalone server$'"$SAMBA_CONF_SERVER_ROLE"'$g' /etc/samba/smb.conf
  fi

  if [ -z ${SAMBA_CONF_LOG_LEVEL+x} ]
  then
    SAMBA_CONF_LOG_LEVEL="1"
    echo ">> SAMBA CONFIG: no \$SAMBA_CONF_LOG_LEVEL set, using '$SAMBA_CONF_LOG_LEVEL'"
  fi
  echo '   log level = '"$SAMBA_CONF_LOG_LEVEL" >> /etc/samba/smb.conf

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

  if [ ! -z ${NETBIOS_DISABLE+x} ]
  then
    echo ">> SAMBA CONFIG: \$NETBIOS_DISABLE is set - disabling nmbd"
    echo '   disable netbios = yes' >> /etc/samba/smb.conf
  fi

  ##
  # GLOBAL CONFIGURATION
  ##
  echo "$SAMBA_GLOBAL_STANZA" | sed 's/;/\n   /g' | grep . >> /etc/samba/smb.conf

  for I_CONF in $(env | grep '^SAMBA_GLOBAL_CONFIG_')
  do
    CONF_KEY_VALUE=$(echo "$I_CONF" | sed 's/^SAMBA_GLOBAL_CONFIG_//g' | sed 's/=.*//g' | sed 's/_SPACE_/ /g' | sed 's/_COLON_/:/g')
    CONF_CONF_VALUE=$(echo "$I_CONF" | sed 's/^[^=]*=//g')
    echo ">> global config - adding: '$CONF_KEY_VALUE' = '$CONF_CONF_VALUE' to /etc/samba/smb.conf"
    echo '   '"$CONF_KEY_VALUE"' = '"$CONF_CONF_VALUE"  >> /etc/samba/smb.conf
  done

  # FAIL FAST START
  [ ! -z ${FAIL_FAST+x} ] && set -e

  ##
  # Create GROUPS
  ##
  for I_CONF in $(env | grep '^GROUP_')
  do
    GROUP_NAME=$(echo "$I_CONF" | sed 's/^GROUP_//g' | sed 's/=.*//g')
    GROUP_ID=$(echo "$I_CONF" | sed 's/^[^=]*=//g')
    echo ">> GROUP: adding group $GROUP_NAME with GID: $GROUP_ID"
    addgroup -g "$GROUP_ID" "$GROUP_NAME"
  done

  ##
  # Create USER ACCOUNTS
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
  done

  ##
  # Add USER ACCOUNTS to GROUPS
  ##
  for I_ACCOUNT in $(env | grep '^ACCOUNT_')
  do
    ACCOUNT_NAME=$(echo "$I_ACCOUNT" | cut -d'=' -f1 | sed 's/ACCOUNT_//g' | tr '[:upper:]' '[:lower:]')

    # add user to groups...
    ACCOUNT_GROUPS=$(env | grep '^GROUPS_'"$ACCOUNT_NAME" | sed 's/^[^=]*=//g')
    for GRP in $(echo "$ACCOUNT_GROUPS" | tr ',' '\n' | grep .); do
      echo ">> ACCOUNT: adding account: $ACCOUNT_NAME to group: $GRP"
      addgroup "$ACCOUNT_NAME" "$GRP"
    done

    unset $(echo "$I_ACCOUNT" | cut -d'=' -f1)
  done

  [ ! -z ${FAIL_FAST+x} ] && set +e
  # FAIL FAST END


  echo '' >> /etc/samba/smb.conf

  ##
  # AVAHI basic / general configuration
  ##
  [ -z ${MODEL+x} ] && MODEL="TimeCapsule"
  sed -i 's/TimeCapsule/'"$MODEL"'/g' /etc/samba/smb.conf

  if ! grep '<txt-record>model=' /etc/avahi/services/samba.service 2> /dev/null >/dev/null;
  then
    # remove </service-group>
    sed -i '/<\/service-group>/d' /etc/avahi/services/samba.service

    echo "  >> AVAHI: zeroconf model: $MODEL"
    echo '
 <service>
  <type>_device-info._tcp</type>
  <port>0</port>
  <txt-record>model='"$MODEL"'</txt-record>
 </service>
</service-group>' >> /etc/avahi/services/samba.service
  fi

  ##
  # Samba Volume Config ENVs
  ##
  for I_CONF in $(env | grep '^SAMBA_VOLUME_CONFIG_' | cut -d= -f1)
  do
    # https://www.unix.com/linux/132018-how-get-indirect-variable-value.html
    eval CONF_VAR=\$$I_CONF
    CONF_CONF_VALUE="$CONF_VAR"

    VOL_NAME=$(echo "$CONF_CONF_VALUE" | head -n1 | sed 's/.*\[\(.*\)\].*/\1/g')
    VOL_PATH=$(echo "$CONF_CONF_VALUE" | tr ';' '\n' | grep path | sed 's/.*= *//g')

    echo ">> VOLUME: adding volume: $VOL_NAME (path=$VOL_PATH)"

    # if time machine volume
    if echo "$CONF_CONF_VALUE" | sed 's/;/\n/g' | grep 'fruit:time machine' | grep yes 2>/dev/null >/dev/null;
    then
        # remove </service-group> only if this is the first time a timemachine volume was added
        grep '<txt-record>dk' /etc/avahi/services/samba.service 2> /dev/null >/dev/null || sed -i '/<\/service-group>/d' /etc/avahi/services/samba.service

        echo "  >> TIMEMACHINE: adding volume to zeroconf: $VOL_NAME"

        if ! echo "$VOL_PATH" | grep '%U$' 2>/dev/null >/dev/null; then
          echo "  >> TIMEMACHINE: fix permissions (only last one wins.. for multiple users I recommend using multi user mode - see README.md)"
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
        echo "  >> TIMEMACHINE: adding samba timemachine specifics to volume config: $VOL_NAME ($VOL_PATH)"
        echo ' durable handles = yes
 kernel oplocks = no
 kernel share modes = no
 posix locking = no
 inherit acls = yes
' >> /etc/samba/smb.conf
    fi

    if echo "$VOL_PATH" | grep '%U$' 2>/dev/null >/dev/null; 
    then
      VOL_PATH_BASE=$(echo "$VOL_PATH" | sed 's,/%U$,,g')
      echo "  >> multiuser volume - $VOL_PATH"
      echo ' root preexec = /container/scripts/samba_create_user_dir.sh '"$VOL_PATH_BASE"' %U' >> /etc/samba/smb.conf
    fi

    echo "" >> /etc/samba/smb.conf

  done

  [ ! -z ${AVAHI_NAME+x} ] && echo ">> ZEROCONF: custom avahi samba.service name: $AVAHI_NAME" && sed -i 's/%h/'"$AVAHI_NAME"'/g' /etc/avahi/services/samba.service
  [ ! -z ${AVAHI_NAME+x} ] && echo ">> ZEROCONF: custom avahi avahi-daemon.conf host-name: $AVAHI_NAME" && sed -i "s/#host-name=foo/host-name=${AVAHI_NAME}/" /etc/avahi/avahi-daemon.conf

  echo ">> ZEROCONF: samba.service file"
  echo "############################### START ####################################"
  cat /etc/avahi/services/samba.service
  echo "################################ END #####################################"

  [ ! -z ${WSDD2_PARAMETERS+x} ] && echo ">> WSDD2: custom parameters for wsdd2 daemon: wsdd2 $WSDD2_PARAMETERS" && sed -i 's/wsdd2/wsdd2 '"$WSDD2_PARAMETERS"'/g' /container/config/runit/wsdd2/run

  [ ! -z ${WSDD2_DISABLE+x} ] && echo ">> WSDD2 - DISABLED" && rm -rf /container/config/runit/wsdd2

  [ ! -z ${AVAHI_DISABLE+x} ] && echo ">> AVAHI - DISABLED" && rm -rf /container/config/runit/avahi

  [ ! -z ${NETBIOS_DISABLE+x} ] && echo ">> NETBIOS - DISABLED" && rm -rf /container/config/runit/nmbd

  if [ -z ${AVAHI_DISABLE+x} ] && [ ! -f "/external/avahi/not-mounted" ]
  then
    echo ">> EXTERNAL AVAHI: found external avahi, now maintaining avahi service file 'samba.service'"
    echo ">> EXTERNAL AVAHI: internal avahi gets disabled"
    rm -rf /container/config/runit/avahi
    cp /etc/avahi/services/samba.service /external/avahi/samba.service
    chmod a+rw /external/avahi/samba.service
    echo ">> EXTERNAL AVAHI: list of services"
    ls -l /external/avahi/*.service
  fi
  
  echo ""
  echo ">> SAMBA: check smb.conf file using 'testparm -s'"
  echo "############################### START ####################################"
  testparm -s
  echo "############################### END ####################################"
  echo ""

  echo ""
  echo ">> SAMBA: print whole smb.conf"
  echo "############################### START ####################################"
  cat /etc/samba/smb.conf
  echo "############################### END ####################################"
  echo ""

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
