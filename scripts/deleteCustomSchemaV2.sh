#!/bin/bash
# FUNCTIONS
delete_attribute(){ 
	sed "s/{{ ATTRIBUTE }}/$2/g" << EOF | ldapmodify -c -H ldap://localhost -D "cn=admin,$LDAP_BASE_DN" -w $ADMIN_PASS
dn: $1
changetype: modify
delete: {{ ATTRIBUTE }}
-
EOF
}

delete_index(){ 
	sed "s/{{ ATTRIBUTE }}/$1/g" << EOF | ldapmodify -c -Y EXTERNAL -Q -H ldapi:/// 
dn: olcDatabase=$LDAP_DATABASE,cn=config
changetype: modify
delete: olcDbIndex
olcDbIndex: {{ ATTRIBUTE }} eq
-
EOF
}

# SETTINGS VARS
declare -a ATTRIBUTES=("x-targetObject" "x-scope" "x-none" "x-auth" "x-read" "x-write" "x-follow" "x-parents" "x-include-role" "x-attribute" "x-is-global" "x-role")
FILTER_ATTRIBUTES="(objectClass=x-role)$(printf "(%s=*)" "${ATTRIBUTES[@]}")"
LDAP_BASE_DN=`echo dc=$LDAP_DOMAIN | sed 's/\./,dc=/g'`
LDAP_DATABASE=`ls -d /etc/ldap/slapd.d/cn\=config/olcDatabase*/ | egrep -o '\{[0-9]+}.{3}'`

echo "ENTER YOUR ADMIN PASSWORD"
read -s ADMIN_PASS
if [ $LDAP_ADMIN_PASSWORD != $ADMIN_PASS ]; then
	echo "PASSWORDS NOT MATCH"
	exit
fi

for i in `ldapsearch -H ldap://localhost -D "cn=admin,$LDAP_BASE_DN" -w $ADMIN_PASS -b "$LDAP_BASE_DN" "(|$FILTER_ATTRIBUTES)" | grep dn | cut -d : -f 2 | sed 's/^\ //g'`
do
echo "DELETE ATTRIBUTES FROM $i"
	
	delete_attribute $i "objectClass\nobjectClass:x-role"
	for attribute in "${ATTRIBUTES[@]}"
	do
		delete_attribute $i $attribute
	done
done

for attribute in "${ATTRIBUTES[@]}"
do
	delete_index $attribute
done
