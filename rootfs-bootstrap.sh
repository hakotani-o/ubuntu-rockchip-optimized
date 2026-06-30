#!/bin/bash

set -eE
trap 'echo Error: in $0 on line $LINENO' ERR

if [ "$(id -u)" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi
set -x
kernel=`ls kernel/linux*.deb|wc -l`
if [ $kernel -ne 5 ]; then
	echo "Build kernel first"
	exit 1
fi

#Bootstrap the system
rm -rf $1
mkdir $1
chroot_dir=$1
mem_size=`free --giga|grep Mem|awk '{print $2}'`
if [ $mem_size -gt 10 ]; then
	mount -t tmpfs -o size=10G tmpfs $chroot_dir
fi
rm -f wget-log* overlay/kernel_version

suite=$3
#suite=resolute
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
echo "127.0.0.1 localhost" > $1/etc/hosts
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

mkdir -p "$1/etc/apt/preferences.d"
{
echo "Package: firefox*"
echo "Pin: release o=LP-PPA-mozillateam"
echo "Pin-Priority: 1001"
echo ""
echo "Package: firefox*"
echo "Pin: release o=Ubuntu"
echo "Pin-Priority: -1"
echo ""
echo "Package: thunderbird*"
echo "Pin: release o=LP-PPA-mozillateam"
echo "Pin-Priority: 1001"
echo ""
echo "Package: thunderbird*"
echo "Pin: release o=Ubuntu"
echo "Pin-Priority: -1"
} > $1/etc/apt/preferences.d/mozillateam-ppa
echo "sudo apt install firefox-esr thunderbird-gnome-support"

{
echo 'Package: *'
echo 'Pin: release o=LP-PPA-xtradeb-apps'
echo 'Pin-Priority: 100'
echo ''
echo 'Package: chromium*'
echo 'Pin: release o=LP-PPA-xtradeb-apps'
echo 'Pin-Priority: 700'
echo ''
echo 'Package: chromium-browser'
echo 'Pin: release *'
echo 'Pin-Priority: -1'
} > $1/etc/apt/preferences.d/xtradeb-chromium-ppa
# kdump not install
cat > "$1/etc/apt/preferences.d/no-kdump" << 'EOF'
Package: kdump-tools
Pin: release *
Pin-Priority: -1
EOF


#setup custom packages

systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo apt-get update
systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo apt-get -y upgrade
systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo apt-get install -y software-properties-common
systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo add-apt-repository -y ppa:mozillateam/ppa
systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo add-apt-repository -y ppa:xtradeb/apps 
systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo apt-get update
systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo apt-get -y dist-upgrade
# もし他のパッケージでも同じように止まった場合は同じパターンで：
# echo 'パッケージ名 パッケージ名/質問キー boolean false' | debconf-set-selections
systemd-nspawn -D $1 \
  --resolv-conf=replace-host \
  --as-pid2 \
  --setenv=DEBIAN_FRONTEND=noninteractive \
  --setenv=DEBCONF_NONINTERACTIVE_SEEN=true \
  /bin/bash -c "echo 'kdump-tools kdump-tools/use_kdump boolean false' | debconf-set-selections && \
  sudo apt-get -y install ubuntu-desktop-minimal gdm3 linux-firmware oem-config-gtk ubiquity-frontend-gtk ubiquity-slideshow-ubuntu yaru-theme-unity yaru-theme-icon yaru-theme-gtk aptdaemon initramfs-tools vim cloud-guest-utils e2fsprogs sudo"
systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 /bin/bash -c "sudo apt-get install -y gstreamer1.0-plugins-bad gstreamer1.0-plugins-good gstreamer1.0-tools clapper mpv vulkan-tools mesa-utils"

systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo apt-get -y purge cloud-init flash-kernel fwupd nano grub-efi-arm64

systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo apt-get update
systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo apt-get -y upgrade

sed -i 's/#EXTRA_GROUPS=.*/EXTRA_GROUPS="video"/g' $1/etc/adduser.conf
sed -i 's/#ADD_EXTRA_GROUPS=.*/ADD_EXTRA_GROUPS=1/g' $1/etc/adduser.conf


# kernel
mkdir $1/kkk && rm -f overlay/libdrm-dev_*.deb overlay/libegl1-mesa-dev_*.deb overlay/libgbm-dev_*.deb && \
rm -f overlay/libgl1-mesa-dev_*.deb overlay/libgles2-mesa-dev_*.deb overlay/mesa-common-dev_*.deb && \
rm -f overlay/mesa-opencl-icd_*.deb overlay/mesa-teflon-delegate_*.deb overlay/mesa-drm-shim_*.deb && \
rm -f overlay/libdrm-tests_*.deb && cp overlay/*.deb $1/kkk && cp kernel/*.deb $1/kkk

systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo /bin/bash -c "sudo apt-get -y purge \$(dpkg --list | grep -Ei 'linux-image|linux-headers|linux-modules|linux-rockchip' | awk '{ print \$2 }')"
systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo /bin/bash -c "cd kkk && sudo dpkg -i *.deb 
#&& sudo dpkg -i kernel/*conservative*.deb && sudo dpkg -i kernel/*ondemand*.deb"

rm -rf $1/kkk
kernel_version="`ls -1 $1/boot/vmlinu?-*|sed 's#-# #g' | awk '{ print $2 }'|head -1`"
echo "kernel_version=$kernel_version" > overlay/kernel_version
# install U-Boot
systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo apt-get -y install u-boot-tools u-boot-menu

# Default kernel command line arguments
echo -n "rootwait rw console=ttyS2,1500000 console=tty1 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory" > $1/etc/kernel/cmdline
echo -n " quiet splash plymouth.ignore-serial-consoles" >> $1/etc/kernel/cmdline

# Override u-boot-menu config
mkdir -p $1/usr/share/u-boot-menu/conf.d
cat << 'EOF' > $1/usr/share/u-boot-menu/conf.d/ubuntu.conf
U_BOOT_UPDATE="true"
U_BOOT_PROMPT="1"
U_BOOT_PARAMETERS="$(cat /etc/kernel/cmdline)"
U_BOOT_TIMEOUT="20"
EOF

rm -f $1/var/lib/dbus/machine-id
true > $1/etc/machine-id
touch $1/var/log/syslog
chown syslog:adm $1/var/log/syslog
systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 ssh-keygen -A
# debug
echo "linux-version"
systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 linux-version list

# chromium
mkdir -p $1/etc/chromium.d/
echo 'export CHROMIUM_FLAGS="$CHROMIUM_FLAGS --enable-features=AcceleratedVideoDecoder,V4l2VideoDecode --disable-features=UseChromeOSDirectVideoDecoder"' > $1/etc/chromium.d/opi5-v4l2


systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo apt-get -y autoremove
systemd-nspawn -D $1 --resolv-conf=replace-host --as-pid2 sudo apt-get  clean


rm -f wget-log*
rm -f $1/boot/*.old
#tar the rootfs
rootfs="overlay/ubuntu.rootfs.tar.gz"
echo "rootfs=$rootfs" > overlay/rootfs
cd $1
rm -rf ../$rootfs
sync
echo " Now create $rootfs "
tar -zcf ../$rootfs --xattrs --xattrs-include='*' ./*
cd ..
echo "DISK usage"
df $1  
# Exit trap is no longer needed
trap '' EXIT
if [ $mem_size -gt 10 ]; then
	umount $1
	sleep 2
fi
exit 0
