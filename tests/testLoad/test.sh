#!/bin/bash
echo "Generating People"
./generateUserLdif.sh test user > people.ldif
join -j 2 -o '1.1 2.1' /names.txt /surnames.txt | ./generateUserLdif.sh >> people.ldif
ldapadd -x -D "cn=admin,dc=example,dc=com" -w originpath -H ldaps://ldap -f people.ldif
ldapadd -x -D "cn=admin,dc=example,dc=com" -w originpath -H ldaps://ldap -f /roles.ldif
echo "Generating People in Groups"
join -j 2 -o '1.1 2.1' /names.txt /surnames.txt |  head -2500 | tail -2500 | ./generateUsersInGroupLdif.sh "cn=project-a-a,cn=project-a,ou=Groups,dc=example,dc=com" >> groupsUpdate.ldif
join -j 2 -o '1.1 2.1' /names.txt /surnames.txt |  head -5000 | tail -2500 | ./generateUsersInGroupLdif.sh "cn=project-a-b,cn=project-a,ou=Groups,dc=example,dc=com" >> groupsUpdate.ldif
join -j 2 -o '1.1 2.1' /names.txt /surnames.txt |  head -7500 | tail -2500 | ./generateUsersInGroupLdif.sh "cn=project-b-a,cn=project-b,ou=Groups,dc=example,dc=com" >> groupsUpdate.ldif
join -j 2 -o '1.1 2.1' /names.txt /surnames.txt | head -10000 | tail -2500 | ./generateUsersInGroupLdif.sh "cn=project-b-b,cn=project-b,ou=Groups,dc=example,dc=com" >> groupsUpdate.ldif
echo "Loading People in Groups"
ldapmodify -x -D "cn=admin,dc=example,dc=com" -w originpath -H ldaps://ldap -f groupsUpdate.ldif

RET=$?
if [ $RET -eq 0 ]; then
	START=`date +%s`
	ldapsearch -D "cn=test user,ou=People,dc=example,dc=com" -w test.user -H ldaps://ldap -b "dc=example,dc=com" -s sub "objectclass=*" > output.txt
	END=`date +%s`
	RET=1
	NUM_EXPECTED=2502
	LINES=$(grep -i 'dn:' output.txt | wc -l)
	grep -i 'dn:' output.txt
	echo "Lines $LINES; Expected $NUM_EXPECTED"
	RUNTIME=$((END-START))
	echo "Search run in $RUNTIME s"
	#Expected
	#memberUid: abigail.adams
	#memberUid: abigail.anderson
	if [ $LINES -eq $NUM_EXPECTED ]; then
		RET=0
	fi
fi


echo "returning $RET"
exit $RET