#!/bin/bash

set -eE
trap 'echo Error: in $0 on line $LINENO' ERR

set -x

linux_dir=$1
rm -rf $linux_dir && mkdir $linux_dir
cd $linux_dir

cp -r /patch .

git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git -b linux-7.2.y

cd linux
# minimyth2 patch
for i in ../patch/*.patch
do
        echo $i
        patch -p1 < $i
done
cp /my-add.txt .
wget https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/refs/heads/master/core/linux-aarch64/config

#make defconfig
./scripts/kconfig/merge_config.sh -m config ./my-add.txt

./scripts/config --set-val DEBUG_INFO_NONE y
./scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
./scripts/config --disable DEBUG_INFO_DWARF4
./scripts/config --disable DEBUG_INFO_DWARF5

make olddefconfig
sed -i 's/CONFIG_LOCALVERSION="-ARCH"/CONFIG_LOCALVERSION=""/' .config
cp .config /2-config.txt

export KCFLAGS="-march=armv8-a+crypto+crc -mtune=cortex-a76.cortex-a55"
fakeroot make -j$(nproc) LOCALVERSION="-rockchip"  deb-pkg
cd ..
cp *.deb /


# Exit trap is no longer needed
trap '' EXIT

exit 0
