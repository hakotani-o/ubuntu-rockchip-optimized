#!/bin/bash

# ディスクイメージを作成するために必要なツールをインストール
sudo apt-get update && sudo apt-get -y install  systemd-container debootstrap

rm -rf arm64
mkdir arm64
chroot_dir=arm64
mem_size=`free --giga|grep Mem|awk '{print $2}'`
if [ $mem_size -gt 13 ]; then
        mount -t tmpfs -o size=10G tmpfs $chroot_dir
fi
suite=$3
Uri=$2
#Uri="http://ports.ubuntu.com/ubuntu-ports"

debootstrap --arch=arm64 $suite arm64 $Uri

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
export  LC_ALL=C
export  LC_CTYPE=C
export  LANGUAGE=C
export  LANG=C

#Setup DNS
echo "127.0.0.1 localhost" > arm64/etc/hosts
echo "127.0.0.1 ubuntu-desktop" > arm64/etc/hosts
echo "nameserver 8.8.8.8" > arm64/etc/resolv.conf
echo "nameserver 8.8.4.4" >> arm64/etc/resolv.conf

#sources.list setup
rm arm64/etc/hostname
echo "ubuntu-desktop" > arm64/etc/hostname
{
echo "Types: deb"
echo "URIs: $Uri"
echo "Suites: $suite $suite-updates $suite-backports"
echo "Components: main universe restricted multiverse"
echo "Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg"
echo ""
echo "## Ubuntu security updates. Aside from URIs and Suites,"
echo "## this should mirror your choices in the previous section."
echo "Types: deb"
echo "URIs: $Uri"
echo "Suites: $suite-security"
echo "Components: main universe restricted multiverse"
echo "Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg"
} > arm64/etc/apt/sources.list.d/ubuntu.sources
rm -f arm64/etc/apt/sources.list

echo "\n##################      systemd-nspawn  START   #######################\n"

systemd-nspawn -D arm64 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get clean
systemd-nspawn -D arm64 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get update
systemd-nspawn -D arm64 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get -y upgrade
systemd-nspawn -D arm64 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get -y dist-upgrade
systemd-nspawn -D arm64 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get -y install build-essential gcc-aarch64-linux-gnu bison \
debootstrap libssl-dev kmod cpio xz-utils fakeroot flex rsync \
device-tree-compiler zstd python3 \
python-is-python3 fdisk bc debhelper python3-pyelftools python3-setuptools \
python3-pkg-resources swig libfdt-dev libpython3-dev \
git fakeroot build-essential ncurses-dev \
libelf-dev libgnutls28-dev gcc-13 g++-13 libdw-dev

systemd-nspawn -D arm64 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 13
systemd-nspawn -D arm64 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 13

echo "\n##################      systemd-nspawn  END     #######################\n"

# u-boot
cp das-u-boot.sh arm64
chmod +x arm64/das-u-boot.sh

systemd-nspawn -D arm64 \
  --resolv-conf=replace-host \
  --as-pid2 \
  --setenv=DEBIAN_FRONTEND=noninteractive \
  --setenv=DEBCONF_NONINTERACTIVE_SEEN=true \
/bin/bash -c "./das-u-boot.sh $1"

cp arm64/*.bin overlay

if [ $4 == "kernel" ]; then
# kernel
cp build-kernel.sh arm64
cp overlay/my-add.txt arm64
chmod +x arm64/build-kernel.sh

# CONFIG_CPU_FREQ_DEFAULT_GOV_CONSERVATIVE
systemd-nspawn -D arm64 \
  --resolv-conf=replace-host \
  --as-pid2 \
  --setenv=DEBIAN_FRONTEND=noninteractive \
  --setenv=DEBCONF_NONINTERACTIVE_SEEN=true \
/bin/bash -c "./build-kernel.sh kernel CONFIG_CPU_FREQ_DEFAULT_GOV_CONSERVATIVE"

# CONFIG_CPU_FREQ_DEFAULT_GOV_ONDEMAND
systemd-nspawn -D arm64 \
  --resolv-conf=replace-host \
  --as-pid2 \
  --setenv=DEBIAN_FRONTEND=noninteractive \
  --setenv=DEBCONF_NONINTERACTIVE_SEEN=true \
/bin/bash -c "./build-kernel.sh kernel CONFIG_CPU_FREQ_DEFAULT_GOV_ONDEMAND"

mkdir -p kernel
cp arm64/*.deb kernel
cp arm64/2-config.txt overlay
fi

if [ $mem_size -gt 13 ]; then
        sudo umount arm64
	sleep 2
fi 
exit 0

