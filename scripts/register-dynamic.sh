#!/bin/sh

. "/container/scripts/ini-functions-crudini.include"

register_action(){
	local SECTION="$1"
	local ACTION="$2"
	ini_set_key "$VOLUME_REGISTRY" "global" "$SECTION" "$ACTION"
	#
	if [ "$ACTION" = "add" ] || [ "$ACTION" = "del" ]; then
		ini_set_key "$VOLUME_REGISTRY" "global" "changed" "true"
	fi
}

register_isaction(){
	local SECTION="$1"
	local ACTION="$2"
	if ini_is_key "$VOLUME_REGISTRY" "global" "$SECTION" "$ACTION"; then
		return 0
	else
		return 1
	fi
}

register_ischanged(){
	if ini_is_key "$VOLUME_REGISTRY" "global" "changed" "true"; then
		return 0
	else
		return 1
	fi
}

register_directory(){
	local S_SOURCE="$1"
        local S_DIR=$(dirname "$S_SOURCE")
	local S_NAME=$(filename "$S_SOURCE")
	local S_TEMPLATE="$S_DIR/directory.template"
	local S_USR="nobody"
	local S_GRP="nogroup"
	local S_WRITABLE="no"
	local CURR_CSUM=$(cat "$S_TEMPLATE" 2> /dev/null | md5sum | cut -f 1 -d " ")
	# check if valid name
	if echo "$S_NAME" | grep -E "global|home|printers" > /dev/null; then
		# reserved section name
		return 1
	elif ini_is_key "$VOLUME_REGISTRY" "$S_NAME" "type" "static"; then
		# already registered as static
		return 1
	elif ini_is_key "$VOLUME_REGISTRY" "$S_NAME" "checksum" "$CURR_CSUM"; then
		# registered and same checksum, nothing changed
		register_action "$S_NAME" "none"
		return 0
	fi
	# get directory information
        local S_SOURCE_STAT=$(stat -L "$S_SOURCE" -c "%A %G %U")
	S_USR=$(echo "$S_SOURCE_STAT" | cut -f 2 -d " ")
	S_GRP=$(echo "$S_SOURCE_STAT" | cut -f 3 -d " ")
	if echo "$S_SOURCE_STAT" | grep -E "^........w." > /dev/null; then
		S_WRITABLE="yes"
	elif echo "$S_SOURCE_STAT" | grep -E "^.....w...." > /dev/null && [ "$S_GRP" = "$SAMBA_DYNAMIC_GROUP" ]; then
		S_WRITABLE="yes"
	elif [ "$S_USR" = "$SAMBA_DYNAMIC_USER" ]; then
		S_WRITABLE="yes"
	fi
	# remove existing
	ini_del_section "$SAMBA_CONFIG" "$S_NAME"
	# add to registry
	ini_set_key "$VOLUME_REGISTRY" "$S_NAME" "type" "dynamic"
	ini_set_key "$VOLUME_REGISTRY" "$S_NAME" "checksum" "$CURR_CSUM"
	# add to samba
	ini_set_key "$SAMBA_CONFIG" "$S_NAME" "path" "$S_SOURCE"
	ini_set_key "$SAMBA_CONFIG" "$S_NAME" "comment" "Share for $S_SOURCE in %L"
	ini_set_key "$SAMBA_CONFIG" "$S_NAME" "writeable" "$S_WRITABLE"
	# if template exists add its keys
       	echo ">> DYNAMIC-VOLUMES: Register directory [$S_NAME]"
	if [ ! -f "$S_TEMPLATE" ]; then
		: # no template found
	elif ! ini_valid "$S_TEMPLATE"; then
		# file not a valid INI file
        	echo "    ERROR: Template file $(basename $S_TEMPLATE) is malformed."
	else
		# copy default keys (no section)
		ini_copy_section "$S_TEMPLATE" "global" "$SAMBA_CONFIG" "$S_NAME" "path|comment|writeable|readable"
		# copy keys for name if found
		if ini_has_section "$S_TEMPLATE" "$S_NAME"; then
			ini_copy_section "$S_TEMPLATE" "$S_NAME" "$SAMBA_CONFIG" "$S_NAME" "path|comment|writeable|readable"
		fi
	fi
	# registered, update state
	register_action "$S_NAME" "add"
	# print section
	ini_print_section "$SAMBA_CONFIG" "$S_NAME" | while IFS= read -r LINE; do
		echo "    $LINE"
	done
	#
	return 0
}

register_file(){
	local S_SOURCE="$1"
        local S_DIR=$(dirname "$S_SOURCE")
	local S_NAME=$(filename "$S_SOURCE")
	local S_EXT=$(extname "$S_SOURCE")
	local S_USR="nobody"
	local S_GRP="nogroup"
	local S_WRITABLE="no"
	local CURR_CSUM=$(cat "$S_SOURCE" 2> /dev/null | md5sum | cut -f 1 -d " ")
	# check if valid INI file
	if ! ini_valid "$S_SOURCE"; then
                # file not a valid INI file
        	echo ">> DYNAMIC-VOLUMES: Register directories from $(basename $S_SOURCE)"
                echo "    ERROR: Share file $(basename $S_SOURCE) is malformed."
		return 1
	fi
	# read all sections in share file and add to samba
	ini_list_sections "$S_SOURCE" | while IFS= read -r S_SECTION; do
		local S_TYPE=$(ini_get_key "$VOLUME_REGISTRY" "$S_SECTION" "type")
		local S_PATH=$(ini_get_key "$S_SOURCE" "$S_SECTION" "path")
		local S_CSUM=$(ini_get_key "$VOLUME_REGISTRY" "$S_SECTION" "checksum")
		local S_FS=$(df -P "$S_PATH" 2> /dev/null | tail -n 1 | awk '{print $1}')
	        # check if valid name
	        if echo "$S_SECTION" | grep -E "global|home|printers" > /dev/null; then
	        	echo ">> DYNAMIC-VOLUMES: Register directory [$S_SECTION] from $(basename $S_SOURCE)"
	        	echo "    ERROR: [$S_SECTION] is a reserved name"
		elif ini_is_key "$VOLUME_REGISTRY" "$S_SECTION" "type" "static"; then
	        	echo ">> DYNAMIC-VOLUMES: Register directory [$S_SECTION] from $(basename $S_SOURCE)"
	        	echo "    ERROR: [$S_SECTION] already registered as static"
		elif ini_is_key "$VOLUME_REGISTRY" "$S_SECTION" "checksum" "$CURR_CSUM"; then
			# checksum same, no change, add to registered directories
			register_action "$S_SECTION" "none"
		elif echo "$S_FS" | grep -E "^\/$|^overlay$|^shm$" > /dev/null; then
	        	echo ">> DYNAMIC-VOLUMES: Register directory [$S_SECTION] from $(basename $S_SOURCE)"
	        	echo "    ERROR: [$S_SECTION] points to an internal container path"
		else
	        	echo ">> DYNAMIC-VOLUMES: Register directory [$S_SECTION] from $(basename $S_SOURCE)"
			# remove existing
			ini_del_section "$SAMBA_CONFIG" "$S_SECTION"
			# add to registry
	                ini_set_key "$VOLUME_REGISTRY" "$S_SECTION" "type" "dynamic"
	                ini_set_key "$VOLUME_REGISTRY" "$S_SECTION" "checksum" "$CURR_CSUM"
			# add to samba
			ini_copy_section "$S_SOURCE" "$S_SECTION" "$SAMBA_CONFIG" "$S_SECTION" ""
			# registered, update state
			register_action "$S_SECTION" "add"
			# print section
			ini_print_section "$SAMBA_CONFIG" "$S_SECTION" | while IFS= read -r LINE; do
				echo "    $LINE"
			done
		fi
	done
	return 0
}

############################
# MAIN
############################

# variables

VOLUME_DIR="/dynamic-volumes"
VOLUME_REGISTRY="/tmp/volumes.ini"
SAMBA_CONFIG="/etc/samba/smb.conf"

# clear volumes state

ini_clear_section "$VOLUME_REGISTRY" "global"

# register dynamic volumes

for S_NAME in $(find "$VOLUME_DIR" -mindepth 1 -maxdepth 1 -type f -name "*.share" -o -type d); do
	if [ -d "$S_NAME" ]; then
		register_directory "$S_NAME"
	else
	  	register_file "$S_NAME"
	fi
done

# check removed

ini_list_sections "$SAMBA_CONFIG" | while IFS= read -r S_NAME; do
        # check if valid name
        if echo "$S_NAME" | grep -E "global|home|printers" > /dev/null; then
                # reserved section name
		continue
	elif ini_is_key "$VOLUME_REGISTRY" "$S_NAME" "type" "static"; then
                # volume is static
                continue
	elif register_isaction "$S_NAME" "add"; then
                # volume added
                continue
	elif register_isaction "$S_NAME" "none"; then
                # volume not changed
                continue
        else
		echo ">> DYNAMIC-VOLUMES: Unregister directory $S_NAME"
		ini_del_section "$VOLUME_REGISTRY" "$S_NAME"
		ini_del_section "$SAMBA_CONFIG" "$S_NAME"
		register_action "$S_NAME" "del"
        fi
done

# reload samba if needed

if ! register_ischanged; then
        : # do nothing, smb.conf not changed
elif ! which smbcontrol > /dev/null; then
        echo ">> DYNAMIC-VOLUMES: Samba configuration changed, smbcontrol missing!!"
elif ! smbcontrol all reload-config; then
        echo ">> DYNAMIC-VOLUMES: Samba configuration changed, error reloading!!"
else
        echo ">> DYNAMIC-VOLUMES: Samba configuration changed, reload"
fi
