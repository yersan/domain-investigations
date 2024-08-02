# domain-investigations

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
