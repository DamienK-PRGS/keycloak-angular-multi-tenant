FROM quay.io/keycloak/keycloak:15.0.0
COPY scripts/startup.sh /opt/jboss/startup-scripcreate-clientts/startup.sh
COPY scripts/create-client.sh /tmp/create-client.sh
