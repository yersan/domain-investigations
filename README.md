# domain-investigations

# Managed Domain demo 

A demo that runs:
* A POD for a domain controller with openshift-group and openshift-ha-group. todo-backend.war deployed in openshift-group, web-clustering.war deployed in openshift-ha-group
* A POD for a host controller + EAP server-1 based on openshift-group to run todo-backend
* A first POD for a host controller + EAP server-1 based on openshift-ha-group to run web-clustering
* A second POD for a host controller + EAP server-1 based on openshift-ha-group to run web-clustering

* Create the posgresql server: 
** Select a postgresql template from the catalog and instantiate it. 
** Set the Database service name to be: database-server 
** Set the user, password and database name to : todos-db

* cd container/pods
* oc create -f domain-controller-service.yaml
* oc create -f domain-ping-service.yaml
* oc create -f kubernetes-dc-pod.yaml
* oc create -f host-controller-service.yaml
* oc create -f host-controller-route.yaml
* oc create -f kubernetes-hc-pod.yaml
* oc create -f ha-service.yaml
* oc create -f kubernetes-hc-ha-pod1.yaml
* oc create -f kubernetes-hc-ha-pod2.yaml

To access the non HA running applications:
* `<host-controller-route>/todo-backend`

To access the HA running application :
* `<ha-route>/web-clustering`

You can kill one of the 2 ha pods, the session is persisted.
 
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
