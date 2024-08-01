sudo /usr/bin/qemu-system-x86_64 -m 8G -accel kvm -cpu host -nographic -netdev user,id=usernet,hostfwd=tcp::9990-:9990,hostfwd=tcp::8080-:8080,hostfwd=tcp::2222-:22 -device virtio-net,netdev=usernet image/disk.raw

