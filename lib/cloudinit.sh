#!/bin/bash
##
# Cloudinit user data and metadata methods
##

function __write_userdata {
    keycontent="$(<sshkey.pub)"
    cat >user-data << EOF
#cloud-config
disable_root: true
hostname: qemu
users:
  - name: gonzalo
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    home: /home/gonzalo
    shell: /bin/bash
    ssh-authorized-keys:
      - ${keycontent}
chpasswd:
  users:
    - name: gonzalo
      password: linux
      type: text
  expire: False
packages:
  - qemu-guest-agent
# written to /var/log/cloud-init-output.log
final_message: "The system is finally up, after \$UPTIME seconds"
EOF
}

function __write_metadata {
    cat >meta-data <<EOF
# meta-data
hostname: qemu
EOF
}


