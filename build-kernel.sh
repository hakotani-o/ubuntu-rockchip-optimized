#!/bin/bash

set -eE
trap 'echo Error: in $0 on line $LINENO' ERR

set -x

linux_dir=$1
rm -rf $linux_dir && mkdir $linux_dir
cd $linux_dir

echo "Downloading VP9 hardware decode patch for rkvdec2..."
mkdir minimyth2 && cd minimyth2
# 3559-media-rkvdec-fix-PM-runtime-teardown-ordering-in-remove.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.3/files/3559-media-rkvdec-fix-PM-runtime-teardown-ordering-in-remove.patch
# 3569-media-rkvdec-prime-VDPU383-deblock-warmup-rk3576.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.3/files/3569-media-rkvdec-prime-VDPU383-deblock-warmup-rk3576.patch
# 3570-media-rkvdec-add-VP9-VDPU381-decoder-support.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.3/files/3570-media-rkvdec-add-VP9-VDPU381-decoder-support.patch
# 3571-media-rkvdec-vp9-fix-altref-vscale-and-segmap-size-for-2K-decode.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.3/files/3571-media-rkvdec-vp9-fix-altref-vscale-and-segmap-size-for-2K-decode.patch
# 3572-media-rkvdec-vdpu381-add-VP9-profile-2-10bit-support.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.3/files/3572-media-rkvdec-vdpu381-add-VP9-profile-2-10bit-support.patch
# 3573-media-rkvdec-vdpu381-vp9-use-the-real-buffer-stride.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.3/files/3573-media-rkvdec-vdpu381-vp9-use-the-real-buffer-stride.patch
# 3574-media-rkvdec-Add-support-for-the-VDPU346-variant.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.3/files/3574-media-rkvdec-Add-support-for-the-VDPU346-variant.patch

cd ..

git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git -b linux-7.3.y

cd linux
# minimyth2 patch
for i in ../minimyth2/*.patch
do
        echo $i
        patch -p1 < $i
done
cp /my-add.txt .
wget https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/refs/heads/master/core/linux-aarch64/config

sed -i '/_AC97_/d' config
sed -i '/CONFIG_WLAN_VENDOR_SILABS/d' config
sed -i '/^CONFIG_INFINIBAND/d' config
sed -i '/^CONFIG_SND_SOC_FSL_/d' config
sed -i '/^CONFIG_SND_HDA/d' config
sed -i '/^CONFIG_SND_SOC_IMX_AUDMUX/d' config
sed -i '/^CONFIG_DRM_LONTIUM_LT8912B/d' config
sed -i '/^CONFIG_DRM_LONTIUM_LT9611/d' config
sed -i '/^CONFIG_DRM_LONTIUM_LT9611UXC/d' config
sed -i '/^CONFIG_DRM_TOSHIBA_TC358767/d' config
sed -i '/^CONFIG_DRM_TI_TFP410/d' config
# dont delete CONFIG_DRM_TI_SN65DSI86
#sed -i '/^CONFIG_DRM_TI_SN65DSI86/d' config
sed -i '/^CONFIG_DRM_I2C_ADV7511/d' config
sed -i '/^CONFIG_DRM_BOCHS/d' config
sed -i '/^CONFIG_DRM_CIRRUS_QEMU/d' config
sed -i '/^CONFIG_DRM_LIMA/d' config

sed -i '/^CONFIG_BROADCOM_PHY/d' config
sed -i '/^CONFIG_BCM54140_PHY/d' config
sed -i '/^CONFIG_BCM7XXX_PHY/d' config
sed -i '/^CONFIG_BCM87XX_PHY/d' config
sed -i '/^CONFIG_MICROCHIP_PHY/d' config


#make defconfig
./scripts/kconfig/merge_config.sh -m config ./my-add.txt

./scripts/config --set-val DEBUG_INFO_NONE y
./scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
./scripts/config --disable DEBUG_INFO_DWARF4
./scripts/config --disable DEBUG_INFO_DWARF5

make olddefconfig
sed -i 's/CONFIG_LOCALVERSION="-ARCH"/CONFIG_LOCALVERSION=""/' .config
cp .config /2-config.txt

export KCFLAGS="-O2 -mcpu=cortex-a76.cortex-a55+crypto+dotprod+nosve -fno-plt"
fakeroot make -j$(nproc) LOCALVERSION="-rockchip"  deb-pkg
cd ..
cp *.deb /


# Exit trap is no longer needed
trap '' EXIT

exit 0
