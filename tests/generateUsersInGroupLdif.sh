#!/bin/bash
SCRIPT=`basename "$0"`
echo "dn: $1
changetype: modify
replace: memberuid"
while IFS= read line; do
	TMP_FOLDER=/tmp/groups
	USERNAME=`echo $line | tr '[:upper:]' '[:lower:]' | sed 's/\ /\./'`
	mkdir -p $TMP_FOLDER
	touch $TMP_FOLDER/$1
	LDAP_GUID=$(( `ls $TMP_FOLDER | wc -l` + 500 ))
	echo "memberuid: $USERNAME"
done
echo "
"
