#!/bin/bash

# Always start sourcing the launch script supplied by wildfly-cekit-modules
source ${JBOSS_HOME}/bin/launch/launch.sh
source ${JBOSS_HOME}/bin/launch/openshift-node-name.sh

function run_clean_shutdown_domain() {
  log_error "*** JBOSS EAP Managed Domain wrapper process ($$) received TERM signal ***"
  host=${JBOSS_EAP_DOMAIN_HOST_NAME}
  log_error "*** Shutting down $host"
  $JBOSS_HOME/bin/jboss-cli.sh -c "shutdown --host=${host}"
  wait $!
}

function run_setup_shutdown_hook() {
  trap "run_clean_shutdown_domain" TERM
  trap "run_clean_shutdown_domain" INT

  if [ -n "$CLI_GRACEFUL_SHUTDOWN" ] ; then
    trap "" TERM
    log_error "Graceful shutdown via a TERM signal has been disabled. Graceful shutdown will need to be initiated via a CLI command."
  fi
}
run_setup_shutdown_hook

# Copied from run launcher.
source "${JBOSS_CONTAINER_WILDFLY_RUN_MODULE}/run-utils.sh"

# HANDLE JAVA OPTIONS
source /usr/local/dynamic-resources/dynamic_resources.sh > /dev/null
GC_METASPACE_SIZE=${GC_METASPACE_SIZE:-96}

JAVA_OPTS="$(adjust_java_options ${JAVA_OPTS})"

# If JAVA_DIAGNOSTICS and there is jvm_specific_diagnostics, move the settings to PREPEND_JAVA_OPTS
# to bypass the specific EAP checks done on JAVA_OPTS in standalone.sh that could remove the GC EAP specific log configurations
JVM_SPECIFIC_DIAGNOSTICS=$(jvm_specific_diagnostics)
if [ "x$JAVA_DIAGNOSTICS" != "x" ] && [ "x{JVM_SPECIFIC_DIAGNOSTICS}" != "x" ]; then
  JAVA_OPTS=${JAVA_OPTS/${JVM_SPECIFIC_DIAGNOSTICS} /}
  PREPEND_JAVA_OPTS="${JVM_SPECIFIC_DIAGNOSTICS} ${PREPEND_JAVA_OPTS}"
fi

# Make sure that we use /dev/urandom (CLOUD-422)
JAVA_OPTS="${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom"

JAVA_OPTS="${JAVA_OPTS} -Djava.net.preferIPv4Stack=true"

if [ -z "$JBOSS_MODULES_SYSTEM_PKGS" ]; then
  JBOSS_MODULES_SYSTEM_PKGS="jdk.nashorn.api,com.sun.crypto.provider"
fi

if [ -n "$JBOSS_MODULES_SYSTEM_PKGS_APPEND" ]; then
  JBOSS_MODULES_SYSTEM_PKGS="$JBOSS_MODULES_SYSTEM_PKGS,$JBOSS_MODULES_SYSTEM_PKGS_APPEND"
fi

JAVA_OPTS="${JAVA_OPTS} -Djboss.modules.system.pkgs=${JBOSS_MODULES_SYSTEM_PKGS}"

# DO WE KEEP?
# White list packages for use in ObjectMessages: CLOUD-703
if [ -n "$MQ_SERIALIZABLE_PACKAGES" ]; then
  JAVA_OPTS="${JAVA_OPTS} -Dorg.apache.activemq.SERIALIZABLE_PACKAGES=${MQ_SERIALIZABLE_PACKAGES}"
fi

# Append to JAVA_OPTS.
JAVA_OPTS="$JAVA_OPTS $JAVA_OPTS_APPEND"

#Handle proxy options
source /opt/run-java/proxy-options
eval preConfigure
eval configure

imgName=${JBOSS_IMAGE_NAME:-$IMAGE_NAME}
imgVersion=${JBOSS_IMAGE_VERSION:-$IMAGE_VERSION}

log_info "Running $imgName image, version $imgVersion"

if [ -n "$JBOSS_EAP_DOMAIN_PRIMARY_ADDRESS" ]; then
  is_domain_controller="false"
else
  is_domain_controller="true"
fi

# Handle port offset
if [ -n "${PORT_OFFSET}" ]; then
  PORT_OFFSET_PROPERTY="-Djboss.socket.binding.port-offset=${PORT_OFFSET}"
fi

PUBLIC_IP_ADDRESS=${SERVER_PUBLIC_BIND_ADDRESS:-$(hostname -i)}
MANAGEMENT_IP_ADDRESS=${SERVER_MANAGEMENT_BIND_ADDRESS:-0.0.0.0}
ENABLE_STATISTICS=${SERVER_ENABLE_STATISTICS:-true}
JBOSS_EAP_DOMAIN_DOMAIN_CONFIG=${JBOSS_EAP_DOMAIN_DOMAIN_CONFIG:-openshift-domain.xml}

if [ "$is_domain_controller" = "true" ]; then
  default_host_name="primary"
  JBOSS_EAP_DOMAIN_HOST_NAME="${JBOSS_EAP_DOMAIN_HOST_NAME:-$default_host_name}"
  JBOSS_EAP_DOMAIN_HOST_CONFIG="${JBOSS_EAP_DOMAIN_HOST_CONFIG:-my-host-primary.xml}"
else
  default_host_name="secondary"
  JBOSS_EAP_DOMAIN_HOST_NAME="${JBOSS_EAP_DOMAIN_HOST_NAME:-$default_host_name}"
  JBOSS_EAP_DOMAIN_HOST_CONFIG="${JBOSS_EAP_DOMAIN_HOST_CONFIG:-my-host-secondary.xml}"
fi

rm -rf /tmp/jvm-cli-script.cli
commands="
    embed-host-controller --std-out=echo --host-config=$JBOSS_EAP_DOMAIN_HOST_CONFIG
      /host=$default_host_name:write-attribute(name=name, value=$JBOSS_EAP_DOMAIN_HOST_NAME)"

if [ "$is_domain_controller" = "false" ]; then
  commands="$commands
      if (outcome != success) of /host=$JBOSS_EAP_DOMAIN_HOST_NAME/jvm=openshift:read-resource
        /host=$JBOSS_EAP_DOMAIN_HOST_NAME/jvm=openshift:add"
  for option in $(echo $PREPEND_JAVA_OPTS); do
    commands="$commands
        /host=$JBOSS_EAP_DOMAIN_HOST_NAME/jvm=openshift:add-jvm-option(jvm-option=\"$option\")"
  done
  for option in $(echo $JAVA_OPTS); do
    commands="$commands
            /host=$JBOSS_EAP_DOMAIN_HOST_NAME/jvm=openshift:add-jvm-option(jvm-option=\"$option\")"
  done
  commands="$commands
       end-if"
  SERVER_ARGS="-Djboss.domain.primary.address=$JBOSS_EAP_DOMAIN_PRIMARY_ADDRESS $SERVER_ARGS"
fi
commands="$commands
    quit"
echo "$commands" >> /tmp/jvm-cli-script.cli
echo "------- CLI script to configure the server -------"
cat /tmp/jvm-cli-script.cli
echo "--------------------------------------------------"
$JBOSS_HOME/bin/jboss-cli.sh --file=/tmp/jvm-cli-script.cli

# Initialize JBOSS_NODE_NAME and JBOSS_TX_NODE_ID
run_init_node_name

# Execute extensions after our configurations, so users can override our settings
if [ -f $JBOSS_HOME/extensions/postconfigure.sh ]; then
  log_info "Calling extensions/postconfigure.sh"
  sh $JBOSS_HOME/extensions/postconfigure.sh
fi

SERVER_ARGS="--domain-config=$JBOSS_EAP_DOMAIN_DOMAIN_CONFIG $SERVER_ARGS"
SERVER_ARGS="--host-config=$JBOSS_EAP_DOMAIN_HOST_CONFIG $SERVER_ARGS"
SERVER_ARGS="-Djboss.host.name=$JBOSS_EAP_DOMAIN_HOST_NAME $SERVER_ARGS"
SERVER_ARGS="${JAVA_PROXY_OPTIONS} -Djboss.node.name=${JBOSS_NODE_NAME} -Djboss.tx.node.id=${JBOSS_TX_NODE_ID} ${PORT_OFFSET_PROPERTY} -b ${PUBLIC_IP_ADDRESS} -bprivate ${PUBLIC_IP_ADDRESS} -bmanagement ${MANAGEMENT_IP_ADDRESS} -Dwildfly.statistics-enabled=${ENABLE_STATISTICS} ${SERVER_ARGS}"

log_info "Launching domain with <<${SERVER_ARGS}>>"
$JBOSS_HOME/bin/domain.sh ${SERVER_ARGS} &

pid=$!
wait $pid 2>/dev/null
