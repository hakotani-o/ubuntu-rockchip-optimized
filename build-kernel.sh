#!/bin/bash

set -eE
trap 'echo Error: in $0 on line $LINENO' ERR

set -x

linux_dir=$1
rm -rf $linux_dir && mkdir $linux_dir
cd $linux_dir


git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git -b linux-7.1.y

cd linux
cp /my-add.txt .
kernel_para=$2
echo "kernel_para=${kernel_para}"
sed -i "s/$kernel_para\=n/$kernel_para\=y/" my-add.txt
kernel_name=$( echo $2 | sed 's/_/ /g' | awk '{ print $6 }' )
echo "kernel_name=$kernel_name"


make defconfig
./scripts/kconfig/merge_config.sh -m .config ./my-add.txt

./scripts/config --set-val DEBUG_INFO_NONE y
./scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
./scripts/config --disable DEBUG_INFO_DWARF4
./scripts/config --disable DEBUG_INFO_DWARF5

make olddefconfig
cp .config /2-config.txt

fakeroot make -j$(nproc) LOCALVERSION="-${kernel_name,,}"  deb-pkg
cd ..
cp *.deb /


# Exit trap is no longer needed
trap '' EXIT

exit 0
