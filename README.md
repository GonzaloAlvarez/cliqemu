# cliqemu
QEmu CLI interface with templates and host configurations

## Goal
This project has four goals:

1. Simple Interface
2. Quick Execution
3. Configurable Defaults
4. Easy CI/CD Integrations

### 1 - Simple Interface

Creating a new VM and SSH-ing into it:
```
$ vm run debian12
downloading image... [ok]
creating virtual machine... [ok]
applying defaults... [ok]
configuring system... [ok]
ssh-ing into the system...
Linux vm 6.6.51+rpt-rpi-2712 #1 SMP PREEMPT Debian 1:6.6.51-1+rpt3 (2024-10-08) aarch64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
cliqemu@vm:~ $
```

Stopping the VM:

```
$ vm destroy debian12
stopping virtual machine.. [ok]
removing virtual machine... [ok]
```
### 2 - Quick Execution
A 'vm run debian12' call should take less than **5 seconds** to complete, after the VM has been downloaded.

### 3 - Configurable Defaults

By default, the configuration for any new VM can be discovered by doing:

```
$ vm config show
disk.size         10G   (2-X Gb)
disk.ephemeral  false   (true: disk does not persist after reboots)
memory.size        4G   (1-X Gb)
display.mode      VNC   ([vnc,term,sdl])
onboot.ssh      false   (true: immediately ssh after run)
```

And, those can be changed with:

```
$ vm config set disk.size 20G
disk.size    20G
```

### 4 - Easy CI/CD Integrations

It allows to run something directly once the machine is ready, and then collect the output and shutdown the machine:

```
$ vm run debian12 ./execute.sh
downloading image... [ok]
creating virtual machine... [ok]
applying defaults... [ok]
configuring system... [ok]
sharing current folder with VM... [ok]
launching provided command [execute.sh]...
This message is from the script.
Linux vm 6.6.51-2712 #1 SMP PREEMPT Debian 1:6.6.51 (2024-10-08) aarch64 GNU/Linux
shutting down the machine... [ok]
destroying the machine... [ok]
```
