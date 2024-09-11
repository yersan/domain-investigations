#!/bin/bash

#build the images
podman build -t localhost/jboss-eap8-domain-openjdk21-openshift ./eap8-domain-openjdk21-openshift
podman build -t localhost/domain-controller \
./domain-controller-image
podman build -t localhost/host-controller \
./host-controller-image

# Create a shared network so all the machines can communicate directly using the host names
podman network create domain-mode-network

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
  -e SERVER_PUBLIC_BIND_ADDRESS=0.0.0.0 \
  -e SERVER_MANAGEMENT_BIND_ADDRESS=0.0.0.0 \
  --label mode=domain-controller \
  localhost/domain-controller

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
  -e SERVER_PUBLIC_BIND_ADDRESS=0.0.0.0 \
  -e SERVER_MANAGEMENT_BIND_ADDRESS=0.0.0.0 \
  --label mode=host-controller \
  localhost/host-controller

sleep 5

# show the logs
podman logs domain-controller
podman logs host-controller