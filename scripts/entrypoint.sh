#!/bin/sh

cat <<EOF
################################################################################

Welcome to the servercontainers/samba

################################################################################

EOF

INITALIZED="/.initialized"

if [ ! -f "$INITALIZED" ]; then
  echo ">> CONTAINER: starting initialisation"

  if [ -z ${SAMBA_CONF_WORKGROUP+x} ]
  then
    SAMBA_CONF_WORKGROUP="WORKGROUP"
    echo ">> SAMBA CONFIG: no \$SAMBA_CONF_WORKGROUP set, using '$SAMBA_CONF_WORKGROUP'"
  fi

  if [ -z ${SAMBA_CONF_SERVER_STRING+x} ]
  then
    SAMBA_CONF_SERVER_STRING="file server"
    echo ">> SAMBA CONFIG: no \$SAMBA_CONF_SERVER_STRING set, using '$SAMBA_CONF_SERVER_STRING'"
  fi

  if [ -z ${SAMBA_CONF_MAP_TO_GUEST+x} ]
  then
    SAMBA_CONF_MAP_TO_GUEST="Bad User"
    echo ">> SAMBA CONFIG: no \$SAMBA_CONF_MAP_TO_GUEST set, using '$SAMBA_CONF_MAP_TO_GUEST'"
  fi

  ##
  # SAMBA Configuration
  ##
cat > /etc/smb.conf <<EOF
[global]
   workgroup = $SAMBA_CONF_WORKGROUP
   server string = $SAMBA_CONF_SERVER_STRING

   server role = standalone server

   dns proxy = no

   log file = /dev/stdout

   unix password sync = yes
   passwd program = /usr/bin/passwd %u
   passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
   pam password change = yes

   map to guest = $SAMBA_CONF_MAP_TO_GUEST

EOF

  ##
  # USER ACCOUNTS
  ##
  for I_ACCOUNT in "$(env | grep '^ACCOUNT_')"
  do
    ACCOUNT_NAME=$(echo "$I_ACCOUNT" | cut -d'=' -f1 | sed 's/ACCOUNT_//g' | tr '[:upper:]' '[:lower:]')
    ACCOUNT_PASSWORD=$(echo "$I_ACCOUNT" | sed 's/^[^=]*=//g')

    echo ">> ACCOUNT: adding account: $ACCOUNT_NAME"
    useradd -M -s /bin/false "$ACCOUNT_NAME"
    echo "$ACCOUNT_PASSWORD\n$ACCOUNT_PASSWORD" | passwd "$ACCOUNT_NAME"
    echo "$ACCOUNT_PASSWORD\n$ACCOUNT_PASSWORD" | smbpasswd -a "$ACCOUNT_NAME"
    smbpasswd -e "$ACCOUNT_NAME"

    unset $(echo "$I_ACCOUNT" | cut -d'=' -f1)
  done

  ##
  # Samba Vonlume Config ENVs
  ##
  for I_CONF in "$(env | grep '^SAMBA_VOLUME_CONFIG_')"
  do
    CONF_CONF_VALUE=$(echo "$I_CONF" | sed 's/^[^=]*=//g')

    echo "$CONF_CONF_VALUE" | sed 's/;/\n/g' >> /etc/smb.conf
    echo "" >> /etc/smb.conf
  done

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
