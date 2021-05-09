**asix**

This is just an experiment for me to find out more about linux before it
turns into something we all know as "linux".

This little iso boots an initramfs compressed by xz. I built a minimal kernel
and together with all the required tools the whole iso is just about 25 MiB in 
file size and boots in 1-2 seconds.

![welcome](files/welcome.png?raw=true "Welcome")

The system as is is quite useless but it could be a base to boot off an encrypted
partition / filesystem. It currently automatically creates an ext4 and a swap
partition.

It can be used to start an installer for a full linux distribution.
It can also be its own "system" aka a rescue shell.

The system boots using syslinux 6.03 which is already able to boot off *efi.
In this case, though, it only works on "bios".

The whole distribution can be build using:

```bash
./asix.sh
```

