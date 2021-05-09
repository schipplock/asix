#!/bin/bash
# By Andreas Schipplock <andreas@schipplock.de>

VERSION="$(cat asix-version)"
DEPLOYPATH=".."

if ! [ -z "$1" ] 
then
  if ! [ -d $1 ] 
  then
    echo "$1 does not exist"
    exit
  fi
  DEPLOYPATH=$1
fi

function createIso {
	#find . | xargs chown root:root
	rm -f $2/asix-$1.iso
	> /tmp/asix-deployment.log
	genisoimage -o "$2/asix-$1.iso" \
	-V asix \
	-A asix \
	-no-emul-boot \
	-boot-load-size 4 \
	-boot-info-table \
	-hide-rr-moved \
	-input-charset utf-8 \
	-output-charset utf-8 \
	-b isolinux/isolinux.bin \
	-c isolinux/boot.cat \
	-R -J . 2>> /tmp/asix-deployment.log
}

function report {
  echo ""
  echo "--"
  echo "Deployment for ASIX $1 succeeded:"
  echo "--"

  if [ -f "$2/asix-$1.iso" ]
  then
    size=$(du -sh $2/asix-$1.iso | awk 'BEGIN{FS=" "};{print $1}') 
    echo "iso : $2/asix-$1.iso ($size)"
  fi

  if [ -f "$2/asix-$1.iso.md5" ]
  then
    size=$(du -sh $2/asix-$1.iso.md5 | awk 'BEGIN{FS=" "};{print $1}')
    echo "md5 : $2/asix-$1.iso.md5 ($size)"
  fi

  if [ -f "$2/asix-$1.iso.sha1" ]
  then
    size=$(du -sh $2/asix-$1.iso.sha1 | awk 'BEGIN{FS=" "};{print $1}')
    echo "sha1: $2/asix-$1.iso.sha1 ($size)"
  fi

  echo
}

function sums {
	(cd ${2} && md5sum asix-${1}.iso > asix-${1}.iso.md5) &&
	(cd ${2} && sha1sum asix-${1}.iso > asix-${1}.iso.sha1)
}

createIso ${VERSION} ${DEPLOYPATH} &&
sums ${VERSION} ${DEPLOYPATH} &&
report ${VERSION} ${DEPLOYPATH}

