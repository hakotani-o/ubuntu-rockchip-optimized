#!/bin/bash

set -eE
trap 'echo Error: in $0 on line $LINENO' ERR

if [ "$(id -u)" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi
# ディスクイメージを作成するために必要なツールをインストール
sudo apt-get update && sudo apt-get -y install  debootstrap systemd-container 

#Bootstrap the system
rm -rf $1
mkdir $1
chroot_dir=$1
mem_size=`free --giga|grep Mem|awk '{print $2}'`
if [ $mem_size -gt 13 ]; then
	mount -t tmpfs -o size=12G tmpfs $chroot_dir
fi
suite=$4
Uri=$3
#Uri="http://ports.ubuntu.com/ubuntu-ports"
	debootstrap --arch=arm64 $suite arm64 $Uri

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
export  LC_ALL=C
export  LC_CTYPE=C
export  LANGUAGE=C
export  LANG=C 

#Setup DNS
echo "127.0.0.1 localhost" > $1/etc/hosts
echo "127.0.0.1 ubuntu-desktop" > $1/etc/hosts
echo "nameserver 8.8.8.8" > $1/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $1/etc/resolv.conf

#sources.list setup
rm $1/etc/hostname
echo "ubuntu-desktop" > $1/etc/hostname
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
} > $1/etc/apt/sources.list.d/ubuntu.sources
rm -f $1/etc/apt/sources.list

echo "\n##################	systemd-nspawn	START	#######################\n"

systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get clean
systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get update
systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get -y upgrade
systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get -y dist-upgrade
systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get -y install build-essential \
flex libssl-dev bc rsync kmod cpio xz-utils fakeroot python3 bison \
python-is-python3 debhelper python3-pyelftools python3-setuptools \
python3-pkg-resources swig libfdt-dev libpython3-dev \
git fakeroot libssl-dev libelf-dev libgnutls28-dev gcc-13 g++-13

systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 13
systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 13

systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 sudo apt-get -y install meson ninja-build pkgconf pkgconf-bin python3-mako \
  libdrm-dev libpciaccess-dev libffi-dev libsensors-dev libxml2-dev \
  libx11-dev libx11-xcb-dev libxcb-dri2-0-dev libxcb-dri3-dev libxcb-glx0-dev \
  libxcb-present-dev libxcb-randr0-dev libxcb-shm0-dev libxcb-xfixes0-dev libxcb1-dev \
  libxdmcp-dev libxext-dev libxrandr-dev libxrender-dev libxshmfence-dev libxxf86vm-dev \
  libwayland-dev libwayland-bin libwayland-egl-backend-dev wayland-protocols \
  libglvnd-core-dev libvulkan-dev glslang-tools spirv-tools spirv-tools-dev \
libclc-21-dev llvm-21-dev libllvmspirvlib-21-dev libclang-cpp21-dev \
libclang-21-dev lua5.4 liblua5.4-dev valgrind libarchive-dev libconfig-dev
#libunwind-dev

echo "\n##################	systemd-nspawn	END	#######################\n"

# Mesa new part1
#echo "--------------- build-dep -y mesa start ---------------------"
# set echo "Types: deb deb-src" to ubuntu.sources
#chroot $1 apt-get build-dep -y mesa
#echo "--------------- build-dep -y mesa end  ----------------------"


echo "=== 1. Mesaソースコードの取得 ==="
if [ "$2" == "upstream" ]; then
    echo "freedesktop staging/26.0 から取得します..."
	# mesa staging 26.0 version
	cp staging_panthor_mesa.sh overlay/libdrm-amdgpu1.symbols.patch $1 && chmod +x $1/staging_panthor_mesa.sh
	systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 /staging_panthor_mesa.sh
else
	# ubuntu version
	cp build_panthor_mesa.sh $1 && chmod +x $1/build_panthor_mesa.sh
systemd-nspawn -D $1 --resolv-conf=replace-host -E DEBIAN_FRONTEND=noninteractive --as-pid2 /build_panthor_mesa.sh
fi
rm -f overlay/*.deb overlay/rel.txt
cp $1/*.deb $1/rel.txt overlay
ls overlay/*.deb overlay/rel.txt

if [ $mem_size -gt 13 ]; then
	umount $chroot_dir
	sleep 2
fi
