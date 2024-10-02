#!/bin/sh

. "$JBOSS_HOME/bin/probe_common.sh"

if [ true = "${DEBUG}" ] ; then
    # short circuit liveness check in dev mode
    exit 0
fi

OUTPUT=/tmp/liveness-output
ERROR=/tmp/liveness-error
LOG=/tmp/liveness-log

DEBUG_SCRIPT=false
PROBE_IMPL="probe.eap.dmr.EapProbe"

if [ $# -gt 0 ] ; then
    DEBUG_SCRIPT=$1
fi

if [ $# -gt 1 ] ; then
    PROBE_IMPL=$2
fi

if [ "$DEBUG_SCRIPT" = "true" ]; then
    DEBUG_OPTIONS="--debug --logfile $LOG --loglevel DEBUG"
fi

if python3 $JBOSS_HOME/bin/probes/runner.py -c READY -c NOT_READY $DEBUG_OPTIONS $PROBE_IMPL; then
    exit 0
fi

if [ "$DEBUG_SCRIPT" == "true" ]; then
    jps -v | grep standalone | awk '{print $1}' | xargs kill -3
fi

exit 1

