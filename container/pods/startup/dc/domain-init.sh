#!/bin/bash
echo "Adding user secondary"
$JBOSS_HOME/bin/add-user.sh -u ${JBOSS_EAP_DOMAIN_USER} -p ${JBOSS_EAP_DOMAIN_PASSWORD}

echo "deploying applications"
$JBOSS_HOME/bin/jboss-cli.sh --file=${JBOSS_EAP_DOMAIN_DOMAIN_INIT_PATH}/scripts/cli.txt --echo-command

