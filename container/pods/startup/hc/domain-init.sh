#!/bin/bash

echo "configuring security"
$JBOSS_HOME/bin/jboss-cli.sh --file=${JBOSS_EAP_DOMAIN_DOMAIN_INIT_PATH}/cli.txt

