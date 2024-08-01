Domain controller
sudo /usr/bin/qemu-system-x86_64 -m 8G -accel kvm -cpu host -nographic -netdev user,id=usernet,hostfwd=tcp::9990-:9990,hostfwd=tcp::8080-:8080,hostfwd=tcp::2222-:22 -device virtio-net,netdev=usernet disk.raw

curl --insecure https://github.com/jfdenise/my-war-2/raw/main/kitchensink.war -LO
/var/eap/bin/add-user.sh -u secondary -p secondary

sh /var/eap/bin/domain.sh --host-config=host-primary.xml -b 10.0.2.15 -bmanagement 0.0.0.0

