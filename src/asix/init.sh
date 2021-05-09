#!/bin/ash
cwd=$(pwd)
clear
mount -n -t devtmpfs none /dev
mount -t proc /proc /proc
mount -t sysfs none /sys
echo 3 4 1 3 > /proc/sys/kernel/printk
mknod /dev/null c 1 3
mknod /dev/tty c 5 0
mdev -s
mkdir -p /mnt/cdrom
mkdir -p /tmp/packages
clear

echo "asix auto setup"
loadkmap < /etc/keymaps/de.map
mount /dev/sr0 /mnt/cdrom

# setup glibc
echo "installing glibc..."
mkdir -p /tmp/packages/glibc && \
cp /mnt/cdrom/packages/glibc.tar.xz /tmp/packages/glibc && \
cd /tmp/packages/glibc && \
tar xf glibc.tar.xz && \
rm glibc.tar.xz && \
cp -R . / && \
cd / && ln -s /lib /lib64 && \
export LD_LIBRARY_PATH=/lib64 && \
rm -rf /tmp/packages/glibc

# setup welcome
echo "installing welcome..."
mkdir -p /tmp/packages/welcome && \
cp /mnt/cdrom/packages/welcome.tar.xz /tmp/packages/welcome && \
cd /tmp/packages/welcome && \
tar xf welcome.tar.xz && \
rm welcome.tar.xz && \
cp -R . / && \
rm -rf /tmp/packages/welcome

cd $cwd

setsid cttyhack /bin/ash --login

dd if=/dev/zero of=/dev/hda bs=512 count=1 conv=notrunc

echo "n
p
1
1
4000
w
" | fdisk /dev/hda

echo "n
p
2


t
2
82
w
" | fdisk /dev/hda

echo "y
" | mkfs.ext4 -q /dev/hda1
mkswap /dev/hda2
swapon /dev/hda2

# mount the newly created filesystem
mkdir -p /mnt/root
mount /dev/hda1 /mnt/root

# mount the cdrom and install the packages to the new root
mkdir -p /mnt/root/tmp
mkdir -p /mnt/cdrom
mount /dev/hdc /mnt/cdrom

# also copy the one and only keymap
mkdir /mnt/root/.Keymaps
cp /mnt/cdrom/keymaps/de.map /mnt/root/.Keymaps/
cd /mnt/root/tmp

# glibc
mkdir -p /mnt/root/tmp/glibc
cp /mnt/cdrom/packages/glibc.tar.xz /mnt/root/tmp/glibc
cd /mnt/root/tmp/glibc && xz -d glibc.tar.xz && tar -xf glibc.tar && rm glibc.tar
cp -R . /
cd / && ln -s /lib /lib64
export LD_LIBRARY_PATH=/lib64
rm -rf /mnt/root/tmp/glibc
cd $cwd

# mksh
mkdir -p /mnt/root/tmp/mksh
cp /mnt/cdrom/packages/mksh.tar.xz /mnt/root/tmp/mksh
cd /mnt/root/tmp/mksh && xz -d mksh.tar.xz && tar -xf mksh.tar && rm mksh.tar
cp -R . /
rm -rf /mnt/root/tmp/mksh
cd $cwd

# also copy busybox (no package for that as it's already part of the initram)
mkdir -p /mnt/root/Software/busybox/bin/
cp -R /bin/busybox /mnt/root/Software/busybox/bin/

# for switch_root; it's not used by me; busybox switch_root needs it
touch /init

#exec switch_root /mnt/root

#exec /bin/ash --login
#setsid cttyhack sh