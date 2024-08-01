#!/bin/bash
echo "Configuring the host controller"
$JBOSS_HOME/bin/jboss-cli.sh --file=$JBOSS_HOME/extensions/cli.txt
