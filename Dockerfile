FROM osixia/openldap:1.3.0

COPY schema/roles.schema /container/service/slapd/assets/config/bootstrap/schema/
COPY scripts /container/service/slapd/scripts
COPY startup.new.sh /container/service/slapd/
COPY image/service/slapd/assets/config/bootstrap/rbac/ldif/ /container/service/slapd/assets/config/bootstrap/rbac/ldif/
ENV LDAP_RBAC_INIT=true
RUN apt-get update && apt-get -y install nano gawk \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN chmod 777 /container/service/slapd/*.sh && \
	mv /container/service/slapd/startup.sh /container/service/slapd/startup.old.sh && \
	mv /container/service/slapd/startup.new.sh /container/service/slapd/startup.sh 