#!/bin/bash
if [ -d "${JBOSS_EAP_DOMAIN_DOMAIN_INIT_PATH}" ]; then
  sh "${JBOSS_EAP_DOMAIN_DOMAIN_INIT_PATH}/domain-init.sh"
else
  echo "No Init script to execute"
fi
