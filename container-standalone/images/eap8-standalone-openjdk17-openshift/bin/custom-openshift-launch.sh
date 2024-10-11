#!/usr/bin/env bash

echo "`date "+%Y-%m-%d %H:%M:%S"` Launching WildFly Server"

SERVER_CONFIG="${WILDFLY_SERVER_CONFIGURATION:-standalone.xml}"
export CONFIG_FILE="$JBOSS_HOME/standalone/configuration/${SERVER_CONFIG}"

# if persistent-standalone.xml exists but is empty, copy the configuration file to the persistent configuration directory
PERSISTENT_CONFIG_FILE="$JBOSS_HOME/standalone/configuration/persistent-standalone.xml"
if [ -e "${PERSISTENT_CONFIG_FILE}" ] && [ ! -s "${PERSISTENT_CONFIG_FILE}" ]; then
    echo "Copying ${CONFIG_FILE} to ${PERSISTENT_CONFIG_FILE}"
    cp "${CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"
else
    cp "${PERSISTENT_CONFIG_FILE}" "${CONFIG_FILE}"
fi

# Always start sourcing the launch script supplied by wildfly-cekit-modules
source ${JBOSS_HOME}/bin/launch/launch.sh
source ${JBOSS_HOME}/bin/launch/openshift-node-name.sh

# SERVER_XXX env variables are WildFly s2i API that this launcher also supports.
PUBLIC_IP_ADDRESS=${WILDFLY_PUBLIC_BIND_ADDRESS:-${SERVER_PUBLIC_BIND_ADDRESS:-${JBOSS_HA_IP:-$(hostname -i)}}}
PRIVATE_IP_ADDRESS=${PUBLIC_IP_ADDRESS}
MANAGEMENT_IP_ADDRESS=${WILDFLY_MANAGEMENT_BIND_ADDRESS:-${SERVER_MANAGEMENT_BIND_ADDRESS:-0.0.0.0}}
ENABLE_STATISTICS=${WILDFLY_ENABLE_STATISTICS:-${SERVER_ENABLE_STATISTICS:-true}}

# Handle JBOSS_TX_NODE_ID computation from JBOSS_NODE_NAME
# Do not rely on ha.sh launch script to set it. The ha logic will get removed at some point.
 init_node_name

launchServer "$JBOSS_HOME/bin/standalone.sh -c ${SERVER_CONFIG}" "-Djboss.node.name=${JBOSS_NODE_NAME} -Djboss.tx.node.id=${JBOSS_TX_NODE_ID} -bprivate ${PUBLIC_IP_ADDRESS} -b ${PUBLIC_IP_ADDRESS} -bmanagement ${MANAGEMENT_IP_ADDRESS} -Dwildfly.statistics-enabled=${ENABLE_STATISTICS} ${SERVER_ARGS}"