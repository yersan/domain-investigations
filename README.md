# domain-investigations

# Managed Domain demo 

A demo that runs:

* A POD for a domain controller with openshift-group and openshift-ha-group. todo-backend.war deployed in openshift-group, web-clustering.war deployed in openshift-ha-group
* A POD for a host controller + EAP server based on openshift-group to run todo-backend
* A first POD for a host controller + EAP server based on openshift-ha-group to run web-clustering
* A second POD for a host controller + EAP server based on openshift-ha-group to run web-clustering

* Create the posgresql server:

  - Select a postgresql template from the catalog and instantiate it. 
  - Set the Database service name to be: database-server 
  - Set the user, password and database name to : todos-db

* Persistent Volume for DC deployments and configuration

  - cd container/pods
  - oc create -f persistent-volume.yaml
  - oc create -f kubernetes-dc-pod.yaml
  - oc rsync startup/dc/v1/ domain-controller:/tmp/domain-init
  - oc delete pod domain-controller

* HC configuration

  - oc create secret generic hc-setup --from-file=startup/hc

* Create the EAP server resources

  - cd container/pods
  - oc create -f domain-controller-service.yaml
  - oc create -f domain-ping-service.yaml
  - oc create -f kubernetes-dc-pod.yaml
  - oc create -f host-controller-service.yaml
  - oc create -f host-controller-route.yaml
  - oc create -f kubernetes-hc-pod.yaml
  - oc create -f ha-service.yaml
  - oc create -f ha-route.yaml
  - oc create -f kubernetes-hc-ha-pod1.yaml
  - oc create -f kubernetes-hc-ha-pod2.yaml

* To access the non HA running applications:

  - `<host-controller-route>/todo-backend`

* To access the HA running application :
  - `<ha-route>/web-clustering`

N.B.: You can kill one of the 2 ha pods, the session is persisted.

# Updating deployments

We are here updating the deployments, log to the DC, run the CLI script to update and reload the host controllers.

* oc rsync startup/dc/v2/ domain-controller:/tmp/domain-init
* install the cli plugin for kubectl: https://github.com/jmesnil/kubectl-jboss-cli/tree/main
* kubectl jboss-cli -p domain-controller -f ./startup/dc/upgrade.cli

# Building your own EAP image

N.B.: replace `quay.io/jdenise` with the repo where you want to push the images`.
N.B: If building and pushing your own images, you will need to update the pods resources that reference the images.

* `cd container/images/eap8-domain-openjdk21-openshift/`
* `podman build -t quay.io/jdenise/jboss-eap8-domain-openjdk21-openshift:latest .`


# Virtual machine demo
The latest POC can be run without requiring to build container nor VM images:

* cd openshift-virtualization/domain-controller-vm/
* oc create -f data-volume.yaml
* oc create -f service.yaml
* oc create -f vm.yaml

Then in OpenShift sandbox start the VM
Wait, when the comain controller is ready,

* cd openshift-virtualization/host-controller-vm/
* oc create -f data-volume.yaml
* oc create -f service.yaml
* oc create -f vm.yaml

Then in OpenShift sandbox start the VM
Wait, when the host controller is ready,

You can then create a route to the host controller service, Port 8080, kitchensink is running.
