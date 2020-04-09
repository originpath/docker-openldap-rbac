#!/bin/bash
chmod +x /installBase.sh && chmod +x /test.sh && apt-get update && apt-get install -y ldap-utils iputils-ping nano && echo "TLS_REQCERT NEVER" > /etc/ldap/ldap.conf && \
	echo "Installing base" && /installBase.sh && \
	echo "Running test" && /test.sh

if [ "${DEBUG,,}" == "true" ]; then
	tail -f /dev/null
fi