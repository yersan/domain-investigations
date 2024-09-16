#!/bin/bash
if [ -n "${JBOSS_EAP_DOMAIN_DOMAIN_INIT_PATH}" ]; then
  sh "${JBOSS_EAP_DOMAIN_DOMAIN_INIT_PATH}/domain-init.sh"
fi
