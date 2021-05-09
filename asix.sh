#!/bin/bash
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -euo pipefail
IFS=$'\n\t'

command=${1:-compile}
sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function extract-software {
  files=(
    "linux-5.5.7.tar.xz"
    "busybox-1.31.1.tar.bz2"
    "syslinux-6.03.tar.xz"
    "e2fsprogs-1.45.5.tar.xz"
    "glibc-2.27.tar.xz"
    "welcome-0.0.1.tar.xz"
  )
  for file in "${files[@]}"
  do
    dir_name=$(echo $file | awk 'BEGIN { FS="-" } ; { print $1 }')
    mkdir -p "${sdir}/kompilate/${dir_name}"
    printf "extracting %s to %s\n" "${sdir}/files/${file}" "${sdir}/kompilate/${dir_name}"
    tar xf "${sdir}/files/${file}" -C "${sdir}/kompilate/${dir_name}" --strip-components=1
  done
}

function compile-software {
  # linux
  printf "%s" "building: linux -> "
  cp "${sdir}/src/linux/kernel_config" "${sdir}/kompilate/linux/.config"
  cd "${sdir}/kompilate/linux" && make -j8
  printf "%s\n" "done"
  cd "${sdir}"
  # busybox
  printf "%s" "building: busybox -> "
  cp "${sdir}/src/busybox/busybox_config" "${sdir}/kompilate/busybox/.config"
  cd "${sdir}/kompilate/busybox" && make -j8 && make install
  printf "%s\n" "done"
  cd "${sdir}"
  # e2fsprogs
  printf "%s" "building: e2fsprogs -> "
  cd "${sdir}/kompilate/e2fsprogs" && \
    ./configure --prefix=/tmp/e2fsprogs \
      --with-udev-rules-dir=/tmp/dontcare \
      --with-systemd-unit-dir=/tmp/dontcare \
      --with-crond-dir=/tmp/dontcare && \
    make -j8 && make install
  mkdir -p "${sdir}/kompilate/e2fsprogs/build"
  cp /tmp/e2fsprogs/sbin/mkfs.ext4 "${sdir}/kompilate/e2fsprogs/build"
  printf "%s\n" "done"
  cd "${sdir}"
  # glibc
  mkdir -p "${sdir}/kompilate/glibc/build"
  cd "${sdir}/kompilate/glibc/build" && \
  ../configure --prefix="${sdir}/package/glibc" --host=x86_64-asix-linux-gnu && \
    CFLAGS=-Os make -j8 && make install && cd "${sdir}/package/glibc" && \
    tar -cvf glibc.tar . && xz glibc.tar
  cp "${sdir}/package/glibc/glibc.tar.xz" "${sdir}/package/"
  rm -rf "${sdir}/package/glibc"
  cd "${sdir}"
  # welcome
  cd "${sdir}/kompilate/welcome"
  tar -cvf welcome.tar . && xz welcome.tar
  cp "${sdir}/kompilate/welcome/welcome.tar.xz" "${sdir}/package/"
  rm -rf "${sdir}/package/welcome"
  cd "${sdir}"
}

function build-iso {
  cd "${sdir}"
  mkdir -p "${sdir}/build/CD_root/isolinux"
  mkdir -p "${sdir}/build/CD_root/kernel"
  cp "${sdir}/kompilate/syslinux/bios/core/isolinux.bin" "${sdir}/build/CD_root/isolinux/"
  cp "${sdir}/kompilate/syslinux/bios/com32/elflink/ldlinux/ldlinux.c32" "${sdir}/build/CD_root/isolinux/"
  cp "${sdir}/src/syslinux/isolinux.cfg" "${sdir}/build/CD_root/isolinux/"
  cp "${sdir}/src/syslinux/message.txt" "${sdir}/build/CD_root/isolinux/"
  cp "${sdir}/src/asix/asix-version" "${sdir}/build/CD_root/"
  cp "${sdir}/src/asix/generateIso.sh" "${sdir}/build/CD_root/"
  chmod +x "${sdir}/build/CD_root/generateIso.sh"
  cp "${sdir}/kompilate/linux/arch/x86/boot/bzImage" "${sdir}/build/CD_root/kernel/vmlinuz"
  mkdir -p "${sdir}/build/CD_root/isolinux/initrd"
  mkdir -p "${sdir}/build/CD_root/isolinux/initrd/tmp"
  mkdir -p "${sdir}/build/CD_root/isolinux/initrd/bin"
  mkdir -p "${sdir}/build/CD_root/isolinux/initrd/etc"
  mkdir -p "${sdir}/build/CD_root/isolinux/initrd/etc/keymaps"
  mkdir -p "${sdir}/build/CD_root/isolinux/initrd/proc"
  mkdir -p "${sdir}/build/CD_root/isolinux/initrd/sys"
  chmod 755 "${sdir}/build/CD_root/isolinux/initrd/proc"
  chmod 755 "${sdir}/build/CD_root/isolinux/initrd/sys"
  mkdir -pv "${sdir}/build/CD_root/isolinux/initrd/var/log"
  mkdir -pv "${sdir}/build/CD_root/isolinux/initrd/var/mail"
  mkdir -pv "${sdir}/build/CD_root/isolinux/initrd/var/spool"
  cp "${sdir}/src/asix/init.sh" "${sdir}/build/CD_root/isolinux/initrd/"
  chmod +x "${sdir}/build/CD_root/isolinux/initrd/init.sh"
  cp "${sdir}/src/asix/asix-version" "${sdir}/build/CD_root/isolinux/initrd/etc/"
  cp -r "${sdir}/kompilate/busybox/_install/"* "${sdir}/build/CD_root/isolinux/initrd/"
  cp "${sdir}/kompilate/e2fsprogs/build/mkfs.ext4" "${sdir}/build/CD_root/isolinux/initrd/bin/"
  cp "${sdir}/src/asix/keymaps/de.map" "${sdir}/build/CD_root/isolinux/initrd/etc/keymaps/"
  cd "${sdir}/build/CD_root/isolinux/initrd" && find . | cpio -H newc -o > ../initramfs.cpio && \
  cd .. && cat initramfs.cpio | xz --check=none --lzma2=dict=512KiB > initramfs.xz
  cd "${sdir}"
  rm "${sdir}/build/CD_root/isolinux/initramfs.cpio"
  rm -rf "${sdir}/build/CD_root/isolinux/initrd"

  # copy the packages to the cd root
  mkdir -p "${sdir}/build/CD_root/packages"
  cp "${sdir}/package/glibc.tar.xz" "${sdir}/build/CD_root/packages/"
  cp "${sdir}/package/welcome.tar.xz" "${sdir}/build/CD_root/packages/"

  # create the iso
  mkdir -p "${sdir}/iso"
  cd "${sdir}/build/CD_root/" && ./generateIso.sh ../../iso
  cd "${sdir}"
}

function clean {
  rm -f "${sdir}/*~"
  rm -rf "${sdir}/kompilate"
  rm -rf "${sdir}/build"
}

case "$command" in
  "compile")
    extract-software && compile-software && build-iso
    ;;
  "iso")
    build-iso
    ;;
  "clean")
    clean
    ;;
  "version")
    echo $(cat "${sdir}/src/asix/asix-version")
    ;;
esac
