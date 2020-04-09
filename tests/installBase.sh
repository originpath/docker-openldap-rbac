#!/bin/bash
#ldapadd -x -D "cn=admin,dc=example,dc=com" -w originpath -H ldaps://ldap -f base.ldif
ldapadd -x -D "cn=admin,dc=example,dc=com" -w originpath -H ldaps://ldap -f groups.ldif