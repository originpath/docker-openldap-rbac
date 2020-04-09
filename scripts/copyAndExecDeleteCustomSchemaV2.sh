#!/bin/bash
docker cp deleteCustomSchemaV2.sh ldap:/
docker exec -it ldap chmod 744 /deleteCustomSchemaV2.sh
docker exec -it ldap ./deleteCustomSchemaV2.sh
