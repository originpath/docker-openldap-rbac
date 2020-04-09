#!/bin/bash
./generateUserLdif.sh test user > people.ldif
join -j 2 -o '1.1 2.1' /names.txt /surnames.txt | head -5 | ./generateUserLdif.sh >> people.ldif
ldapadd -x -D "cn=admin,dc=example,dc=com" -w originpath -H ldaps://ldap -f people.ldif
ldapadd -x -D "cn=admin,dc=example,dc=com" -w originpath -H ldaps://ldap -f /roles.ldif
ldapmodify -x -D "cn=admin,dc=example,dc=com" -w originpath -H ldaps://ldap -f /users-in-groups.ldif

ldapsearch -D "cn=test user,ou=People,dc=example,dc=com" -w test.user -H ldaps://ldap -b "dc=example,dc=com" -s sub "objectclass=*" > output.txt

NUM_EXPECTED=6
RET=1
LINES=$(grep dn output.txt | wc -l)
grep dn output.txt
echo "Lines $LINES; Expected $NUM_EXPECTED"
#Expected
#dc=example,dc=com
#cn=project-a-a,cn=project-a,ou=Groups,dc=example,dc=com

if [ $LINES -eq $NUM_EXPECTED ]; then
	RET=0
fi
echo "returning $RET"
exit $RET