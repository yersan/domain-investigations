#!/bin/bash

# Always start sourcing the launch script supplied by wildfly-cekit-modules
source ${JBOSS_HOME}/bin/launch/launch.sh
source ${JBOSS_HOME}/bin/launch/openshift-node-name.sh

function run_clean_shutdown() {
  local management_port=""
  if [ -n "${PORT_OFFSET}" ]; then
    management_port=$((9990 + PORT_OFFSET))
  fi
  log_error "*** JBOSS EAP Managed Domain wrapper process ($$) received TERM signal ***"
  host=${JBOSS_EAP_DOMAIN_HOST_NAME}
  log_error "*** Shutting down $host"
  if [ -z ${management_port} ]; then
    $JBOSS_HOME/bin/jboss-cli.sh -c "/host=${host}:shutdown()"
  else
    $JBOSS_HOME/bin/jboss-cli.sh --commands="connect remote+http://localhost:${management_port},/host=${host}:shutdown()"
  fi
  wait $!
}

function run_setup_shutdown_hook() {
  trap "run_clean_shutdown" TERM
  trap "run_clean_shutdown" INT

  if [ -n "$CLI_GRACEFUL_SHUTDOWN" ] ; then
    trap "" TERM
    log_error "Graceful shutdown via a TERM signal has been disabled. Graceful shutdown will need to be initiated via a CLI command."
  fi
}
run_setup_shutdown_hook

# Execute extensions
if [ -f $JBOSS_HOME/extensions/postconfigure.sh ]; then
  log_info "Calling extensions/postconfigure.sh"
  sh $JBOSS_HOME/extensions/postconfigure.sh
fi

SERVER_LAUNCH_SCRIPT_OVERRIDE=domain.sh /opt/jboss/container/wildfly/run/run &
pid=$!
wait $pid 2>/dev/null