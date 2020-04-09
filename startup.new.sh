#!/bin/bash -e

function start_ldap() {
	if log-helper level ge debug; then
		slapd -h "ldap://localhost ldapi:///" -u openldap -g openldap -d $LDAP_LOG_LEVEL 2>&1 &
	else
		slapd -h "ldap://localhost ldapi:///" -u openldap -g openldap
	fi

	log-helper info "Waiting for OpenLDAP to start..."
	while [ ! -e /run/slapd/slapd.pid ]; do sleep 0.1; done
}

function stop_ldap() {
	log-helper info "Stop OpenLDAP..."

	SLAPD_PID=$(cat /run/slapd/slapd.pid)
	kill -15 $SLAPD_PID
	while [ -e /proc/$SLAPD_PID ]; do sleep 0.1; done # wait until slapd is terminated
}

set -o pipefail
IS_FIRST_START_DONE=0
if [ ! -e ${CONTAINER_STATE_DIR}/slapd-first-start-done ]; then
	IS_FIRST_START_DONE=1
fi

# Replace the very last exit by a return
tac /container/service/slapd/startup.old.sh | sed '1 s/exit/return/' | tac > /container/service/slapd/sourced_startup.old.sh
source /container/service/slapd/sourced_startup.old.sh

log-helper debug "Applying roles if required"
if [ $IS_FIRST_START_DONE -eq 1 ]; then

	start_ldap

	log-helper debug "ROLES_SCHEMAS"
	ROLES_SCHEMAS="$(find /etc/ldap/slapd.d/cn\=config/cn\=schema/ -name *roles.ldif | wc -l)"
	log-helper debug "ROLES_SCHEMAS"

	if [ $ROLES_SCHEMAS -eq 0 ]; then
		# Fallback in case the directory was previously initialized

		log-helper debug "Applying roles schema"

		${CONTAINER_SERVICE_DIR}/slapd/assets/schema-to-ldif.sh /container/service/slapd/assets/config/bootstrap/schema/roles.schema
		ldap_add_or_modify /container/service/slapd/assets/config/bootstrap/schema/roles.ldif

		log-helper debug "Roles schema applied successfully"
	else
		log-helper debug "Roles schema already exists"
	fi

	log-helper info "ldapsearch -D cn=admin,$LDAP_BASE_DN -w $LDAP_ADMIN_PASSWORD -H ldap://localhost -b $LDAP_BASE_DN -s sub objectclass=*"
	# Base and admin
	if [ 2 -eq "$(ldapsearch -D "cn=admin,$LDAP_BASE_DN" -w "$LDAP_ADMIN_PASSWORD" -H ldap://localhost -b "$LDAP_BASE_DN" -s sub "objectclass=*" | grep dn | wc -l )" ] && \
		[ "${LDAP_RBAC_INIT,,}" == "true" ]; then

		log-helper info "Initializing base structure /container/service/slapd/assets/config/bootstrap/rbac/ldif/01-base.ldif"
		# if the directory is empty and LDAP_RBAC_INIT is set to true
		ldap_add_or_modify /container/service/slapd/assets/config/bootstrap/rbac/ldif/01-base.ldif
	fi

	log-helper info "Generating a new /container/service/slapd/assets/config/bootstrap/ldif/02-security.ldif"
	/container/service/slapd/scripts/makeSecurity.sh

	log-helper info "Applying new security (/container/service/slapd/assets/config/bootstrap/ldif/02-security.ldif)"

	ldap_add_or_modify /container/service/slapd/assets/config/bootstrap/ldif/02-security.ldif

	stop_ldap
else
	log-helper debug "Roles already applied"
fi
