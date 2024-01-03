#!/bin/bash
ubuntu_version=23.04
iso=ubuntu-${ubuntu_version}-server-cloudimg-amd64.img
if [ ! -f "$iso" ]; then
  wget "https://cloud-images.ubuntu.com/releases/${ubuntu_version}/release/${iso}"
fi
img=ubuntu-${ubuntu_version}-server-cloudimg-amd64.qcow2
rm -f "${img}"
if [ ! -f $img ]; then
  qemu-img \
    create \
    -F qcow2 \
    -b "$iso" \
    -f qcow2 \
    "$img"
fi
rm -f cloud.img user-data seed.iso
keyfile=GonzaloAlvarez-MasterSSH-pubkey.pem
if [ ! -f "${keyfile}" ]; then
    wget "https://raw.githubusercontent.com/GonzaloAlvarez/credentials/master/SSH/${keyfile}"
fi
cat >user-data <<EOF
#cloud-config
ssh_pwauth: true
disable_root: false
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    home: /home/ubuntu
    shell: /bin/bash
    lock_passwd: false
    ssh-authorized-keys:
      - $(cat ${keyfile})
  - name: gonzalo
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    home: /home/gonzalo
    shell: /bin/bash
    lock_passwd: false
    ssh-authorized-keys:
      - $(cat ${keyfile})
chpasswd:
  users:
    - name: ubuntu
      password: linux
      type: text
    - name: gonzalo
      password: linux
      type: text
  expire: False
packages:
  - qemu-guest-agent
# written to /var/log/cloud-init-output.log
final_message: "The system is finally up, after \$UPTIME seconds"
EOF
cat >meta-data <<EOF
# meta-data
hostname: qemu
EOF
#cloud-localds --disk-format qcow2 cloud.img cloud.yaml
#cloud-localds --disk-format qcow2 cloud.img user-data
genisoimage -output seed.iso -volid cidata -joliet -rock user-data meta-data
#qemu-img convert -f raw -O qcow2 seed.iso cloud.img
qemu-system-x86_64 \
    -cpu host -smp 2 -enable-kvm -m 4G -nographic \
    -object iothread,id=io1 -device virtio-rng-pci \
    -drive if=none,format=qcow2,file=${img},id=disk1 \
    -drive if=virtio,format=raw,file=seed.iso \
    -device virtio-blk,drive=disk1,bootindex=1,iothread=io1 \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::2200-:22,hostname=qemu
