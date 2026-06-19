#!/bin/bash
export PATH=$PATH:$JBOSS_HOME/bin

# Create 
echo "Create my-theme".
cp /opt/keycloak/themes/ /opt/keycloak/themes/my-theme
cp /opt/keycloak/themes/my-theme/login/login.ftl /opt/keycloak/themes/my-theme/login/login.ftl