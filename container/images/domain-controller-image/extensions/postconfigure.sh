#!/bin/bash
echo "Adding user secondary"
$JBOSS_HOME/bin/add-user.sh -u secondary -p secondary

echo "deploying kitchensink.war"
$JBOSS_HOME/bin/jboss-cli.sh --file=$JBOSS_HOME/extensions/cli.txt
