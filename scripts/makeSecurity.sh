#!/bin/bash
SYSTEM_ENVS=`env | sed -E 's/=.*//'`
FOLDER_PATH="/container/service/slapd/scripts"
TEMP_FOLDER="temp"
source $FOLDER_PATH/roles.env
log-helper debug "CREATING TEMP FOLDER IF NOT EXISTS ($FOLDER_PATH/$TEMP_FOLDER)"
mkdir -p $FOLDER_PATH/$TEMP_FOLDER & sync
log-helper debug "REMOVING TEMP FOLDER CONTENTS"
rm -rf $FOLDER_PATH/$TEMP_FOLDER/*
log-helper debug "COPYING ROLES_TEMPLATES TO TEMP_FOLDER"
cp -r $FOLDER_PATH/roles_templates/* $FOLDER_PATH/$TEMP_FOLDER/
cd $FOLDER_PATH/$TEMP_FOLDER/
log-helper debug "Replacing Templates $(pwd)"
# Get .env files
for f in $(find . -maxdepth 1 -type f -name \*.env | sort); do
	FILENAME=$(basename -- "$f")
	source $f
	VAR_NAME="${FILENAME%.*}"
	VAR_VALUE=${!VAR_NAME}
	VAR_VALUE_SANITIZED=$VAR_VALUE
	log-helper debug $VAR_NAME
	
	#Load ALL environment variables starting with LDAP
	LDAP_ENVS=`env | grep LDAP | sed -E 's/=.*//'`
	ENVS=`{ echo $SYSTEM_ENVS & echo $LDAP_ENVS ; }`
	PREVIOUS_FILE_SIZE=""
	FILE_SIZE=${#VAR_VALUE_SANITIZED}
	# WHILE var length has changed
	while [ "$PREVIOUS_FILE_SIZE" != "$FILE_SIZE" ]; do
		for ENV in $ENVS ; do
			# Replace in VAR_VALUE_SANITIZED all occurrences of "{{ $ENV }}" with the value of $ENV
			VAR_VALUE_SANITIZED=${VAR_VALUE_SANITIZED//"{{ $ENV }}"/"${!ENV}"}
		done
		# Set the var value
		declare "$VAR_NAME=$VAR_VALUE_SANITIZED"
		PREVIOUS_FILE_SIZE=$FILE_SIZE
		FILE_SIZE=${#VAR_VALUE_SANITIZED}
	done
done
log-helper debug "Replacing LDIF"
# COPY THE TEMPLATE TO THE TARGET
cd $FOLDER_PATH
cp templates/02-security.ldif.template /container/service/slapd/assets/config/bootstrap/ldif/02-security.ldif
#REPLACE THE TARGET
for ENV in $ENVS ; do
	SANITIZED_ENV_VAL=${!ENV//&/\\&}
	SANITIZED_ENV_VAL=${SANITIZED_ENV_VAL//|/\\|}
	awk -i inplace -v old="{{ $ENV }}" -v new="$SANITIZED_ENV_VAL" 's=index($0,old){$0=substr($0,1,s-1) new substr($0,s+length(old))} 1' /container/service/slapd/assets/config/bootstrap/ldif/02-security.ldif 2> /dev/null
done
#cat /container/service/slapd/assets/config/admin-pw/ldif/02-security.ldif
#ls -la /container/service/slapd/assets/config/admin-pw/ldif/
exit 0