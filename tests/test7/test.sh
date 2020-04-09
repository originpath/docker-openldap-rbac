#!/bin/bash
./generateUserLdif.sh test user > people.ldif
join -j 2 -o '1.1 2.1' /names.txt /surnames.txt | head -5 | ./generateUserLdif.sh >> people.ldif
ldapadd -x -D "cn=admin,dc=example,dc=com" -w originpath -H ldaps://ldap -f people.ldif
ldapadd -x -D "cn=admin,dc=example,dc=com" -w originpath -H ldaps://ldap -f /roles.ldif
ldapmodify -x -D "cn=admin,dc=example,dc=com" -w originpath -H ldaps://ldap -f /users-in-groups.ldif
echo "Updating Members"
ldapmodify -x -D "cn=test user,ou=People,dc=example,dc=com" -w test.user -H ldaps://ldap -f /update-members.ldif

RET=$?
if [ $RET -eq 0 ]; then
	ldapsearch -D "cn=test user,ou=People,dc=example,dc=com" -w test.user -H ldaps://ldap -b "cn=Abigail Adams,ou=People,dc=example,dc=com" -s sub "objectclass=*" sn > output.txt
	RET=1
	NUM_EXPECTED=1
	LINES=$(grep -i 'sn: Adam-Smith' output.txt | wc -l)
	grep -i 'sn: Adam-Smith' output.txt
	echo "Lines $LINES; Expected $NUM_EXPECTED"
	#Expected
	#memberUid: abigail.adams
	#memberUid: abigail.anderson
	if [ $LINES -eq $NUM_EXPECTED ]; then
		RET=0
	fi
fi


echo "returning $RET"
exit $RET