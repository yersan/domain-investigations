#!/bin/bash

#build the images
podman build -t localhost/jboss-eap8-domain-openjdk21-openshift ./eap8-domain-openjdk21-openshift
podman build -t localhost/domain-controller \
./domain-controller-image
podman build -t localhost/host-controller \
./host-controller-image

# Create a shared network so all the machines can communicate directly using the host names
podman network create domain-mode-network

# Start PostgreSQL Database, required for the todo application
podman run -d --rm \
  --name postgresql \
  --hostname database-server \
  --network domain-mode-network \
  -p 5432:5432 \
  -e POSTGRES_USER=todos-db \
  -e POSTGRES_PASSWORD=todos-db \
  -e POSTGRES_DB=todos-db \
  docker.io/postgres:16

# Run the domain-controller container
podman run -d --rm \
  --name domain-controller \
  --hostname primaryhostname \
  --network domain-mode-network \
  -p 9990:9990 \
  -e JBOSS_EAP_DOMAIN_HOST_NAME=primary \
  -e JBOSS_EAP_DOMAIN_USER=secondary \
  -e JBOSS_EAP_DOMAIN_PASSWORD=secondary \
  -e JBOSS_EAP_DOMAIN_DOMAIN_CONFIG=openshift-domain.xml \
  -e JBOSS_EAP_DOMAIN_HOST_CONFIG=my-host-primary.xml \
  --label mode=domain-controller \
  localhost/domain-controller

# Wait for the domain controller to start, just to make sure it's ready and the host controller can join the domain
# on the first try
sleep 2

# Run the secondary-host container
podman run -d --rm \
  --name host-controller \
  --hostname secondaryhostname \
  --network domain-mode-network \
  -p 8080:8080 \
  -e JBOSS_EAP_DOMAIN_HOST_NAME=secondary \
  -e JBOSS_EAP_DOMAIN_USER=secondary \
  -e JBOSS_EAP_DOMAIN_PASSWORD=secondary \
  -e JBOSS_EAP_DOMAIN_PRIMARY_ADDRESS=primaryhostname \
  -e JBOSS_EAP_DOMAIN_HOST_CONFIG=my-host-secondary.xml \
  -e POSTGRESQL_DATABASE=todos-db \
  -e POSTGRESQL_USER=todos-db \
  -e POSTGRESQL_PASSWORD=todos-db \
  -e POSTGRESQL_DATASOURCE=ToDos \
  -e POSTGRESQL_SERVICE_HOST=database-server \
  -e POSTGRESQL_SERVICE_PORT="5432" \
  --label mode=host-controller \
  localhost/host-controller

sleep 5

# show the logs
podman logs domain-controller
podman logs host-controller