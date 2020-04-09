#!/bin/bash
if [ $# -eq 0 ]; then
	SCRIPT=`basename "$0"`
	while IFS= read line; do
#		echo "./$SCRIPT ${line}"
		./$SCRIPT $line
	done
else
	TMP_FOLDER=/tmp/people
	USERNAME=`echo $1.$2 | tr '[:upper:]' '[:lower:]'`
	mkdir -p $TMP_FOLDER
	touch $TMP_FOLDER/$USERNAME
	LDAP_UID=$(( `ls $TMP_FOLDER | wc -l` + 1000 ))
	echo "dn: cn=$@,ou=People,dc=example,dc=com
cn: $@
uidNumber: $LDAP_UID
gidnumber: 500
givenname: $1
homedirectory: /home/$USERNAME
loginshell: /usr/sbin/nologin
mail: $USERNAME@example.com
objectclass: inetOrgPerson
objectclass: posixAccount
objectclass: top
sn: $2
uid: $USERNAME
userPassword: $USERNAME
"
fi
