sudo /usr/bin/qemu-system-x86_64 -m 8G -accel kvm -cpu host -nographic -netdev user,id=usernet,hostfwd=tcp::8230-:8230,hostfwd=tcp::9991-:9990,hostfwd=tcp::8081-:8080,hostfwd=tcp::2223-:22 -device virtio-net,netdev=usernet disk.raw

/var/eap/bin/jboss-cli.sh
embed-host-controller --std-out=echo --host-config=host-secondary.xml

/host=secondary/subsystem=elytron/authentication-configuration=secondary-hc-auth:add(authentication-name=secondary, credential-reference={clear-text=secondary})
/host=secondary/subsystem=elytron/authentication-context=secondary-hc-auth-context:add(match-rules=[{authentication-configuration=secondary-hc-auth}])
/host=secondary:write-attribute(name=domain-controller.remote.authentication-context, value=secondary-hc-auth-context)

/var/eap/bin/domain.sh --host-config=host-primary.xml \
-b 10.0.2.15 \
-Dmanagement 0.0.0.0

/var/eap/bin/domain.sh --host-config=host-secondary.xml \
-Djboss.bind.address.management=10.0.2.15 \
-Djboss.bind.address=0.0.0.0 \
-Djboss.domain.primary.address=10.0.2.2 \
-Djboss.domain.primary.port=9990

YES!!!!!!!!!!!!!!!!!!!!
http://localhost:8230/kitchensink/index.jsf