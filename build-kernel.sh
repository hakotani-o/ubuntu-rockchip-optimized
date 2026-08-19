#!/bin/bash

set -eE
trap 'echo Error: in $0 on line $LINENO' ERR

set -x

linux_dir=$1
rm -rf $linux_dir && mkdir $linux_dir
cd $linux_dir

mkdir minimyth2 && cd minimyth2
# 3559-media-rkvdec-fix-PM-runtime-teardown-ordering-in-remove.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3559-media-rkvdec-fix-PM-runtime-teardown-ordering-in-remove.patch
# 3569-media-rkvdec-prime-VDPU383-deblock-warmup-rk3576.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3569-media-rkvdec-prime-VDPU383-deblock-warmup-rk3576.patch
# 3570-media-rkvdec-add-VP9-VDPU381-decoder-support.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3570-media-rkvdec-add-VP9-VDPU381-decoder-support.patch
# 3571-media-rkvdec-vp9-fix-altref-vscale-and-segmap-size-for-2K-decode.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3571-media-rkvdec-vp9-fix-altref-vscale-and-segmap-size-for-2K-decode.patch
# 3572-media-rkvdec-vdpu381-add-VP9-profile-2-10bit-support.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3572-media-rkvdec-vdpu381-add-VP9-profile-2-10bit-support.patch
# 3573-media-rkvdec-vdpu381-vp9-use-the-real-buffer-stride.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3573-media-rkvdec-vdpu381-vp9-use-the-real-buffer-stride.patch
# 3574-media-rkvdec-Add-support-for-the-VDPU346-variant.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3574-media-rkvdec-Add-support-for-the-VDPU346-variant.patch

# add 4 patch for AV01 4K Hardware decode not work 2026/08/18

# 7.2 not need
# 3611-arm64-dtsi-rk3588-add-av1-iommu-nodes.patch
#wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3611-arm64-dtsi-rk3588-add-av1-iommu-nodes.patch

# 7.2 not need
# 3563-iommu-Add-verisilicon-IOMMU-driver.patch
#wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3563-iommu-Add-verisilicon-IOMMU-driver.patch

# 3565-media-rkvdec-remove-vb2_is_busy-check-in-rkvdec_s_ct.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3565-media-rkvdec-remove-vb2_is_busy-check-in-rkvdec_s_ct.patch

# 3566-media-v4l2-core-Initialize-h264-frame_mbs_only_flag-as-1.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3566-media-v4l2-core-Initialize-h264-frame_mbs_only_flag-as-1.patch

# 3567-media-verisilicon-AV1-Restore-IOMMU-context-before-d.patch
wget https://raw.githubusercontent.com/warpme/minimyth2/refs/heads/master/script/kernel/linux-7.1/files/3567-media-verisilicon-AV1-Restore-IOMMU-context-before-d.patch
cp /3563-remake.patch .

git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git -b linux-7.2.y

cd linux
wget https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/refs/heads/master/core/linux-aarch64/config
# minimyth2 patch
for i in ../minimyth2/*.patch
do
        echo $i
        patch -p1 < $i
done
 sed -i 's/CONFIG_LOCALVERSION="-ARCH"/CONFIG_LOCALVERSION=""/' config
cp /my-add.txt .
kernel_para=$2
echo "kernel_para=${kernel_para}"
sed -i "s/$kernel_para\=n/$kernel_para\=y/" my-add.txt
kernel_name=$( echo $2 | sed 's/_/ /g' | awk '{ print $6 }' )
echo "kernel_name=$kernel_name"


#make defconfig
./scripts/kconfig/merge_config.sh -m config ./my-add.txt

./scripts/config --set-val DEBUG_INFO_NONE y
./scripts/config --disable DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
./scripts/config --disable DEBUG_INFO_DWARF4
./scripts/config --disable DEBUG_INFO_DWARF5

make olddefconfig
cp .config /2-config.txt
export KCFLAGS="-march=armv8-a+crypto+crc -mtune=cortex-a76.cortex-a55"
fakeroot make -j$(nproc) LOCALVERSION="-${kernel_name,,}"  deb-pkg
cd ..
cp *.deb /


# Exit trap is no longer needed
trap '' EXIT

exit 0
