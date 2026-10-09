#!/bin/sh

. "/container/scripts/ini-functions-crudini.include"

############################
# MAIN
############################

# variables

VOLUME_REGISTRY="/tmp/volumes.ini"
SAMBA_CONFIG="/etc/samba/smb.conf"

# create empty volume registry

echo "[global]" > "$VOLUME_REGISTRY"

# register static volumes, get from environment values

for VAR_NAME in $(env | grep '^SAMBA_VOLUME_CONFIG_' | cut -d= -f1); do
        eval "VAR_VALUE=\${$VAR_NAME}"
	S_NAME=$(echo "$VAR_VALUE" | sed 's/^[[:space:]]*\[\(.*\)\].*/\1/')
	# check if valid name
	if echo "$S_NAME" | grep -E "global|home|printers" > /dev/null; then
		# reserved section name
		continue
	else
		echo ">> DYNAMIC-VOLUMES: Register static directory [$S_NAME]"
		ini_set_key "$VOLUME_REGISTRY" "$S_NAME" "type" "static"
	fi
done
