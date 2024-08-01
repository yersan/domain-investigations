Host controller
sudo /usr/bin/qemu-system-x86_64 -m 8G -accel kvm -cpu host -nographic -netdev user,id=usernet,hostfwd=tcp::8080-:8080,hostfwd=tcp::2223-:22 -device virtio-net,netdev=usernet image/disk.raw

podman run -it --rm -e SERVER_ARGS="--host-config=my-host.xml -Djboss.domain.primary.address=10.0.2.2 -Djboss.management.http.port=9991" quay.io/jdenise/my-host-controller:1.0 bash