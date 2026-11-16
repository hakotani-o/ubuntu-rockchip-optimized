#!/bin/bash


	rm -rf work
	mkdir work
	cd work

		git clone --depth 1 https://github.com/rockchip-linux/rkbin
		
		DDR=`ls rkbin/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v*.bin`
		BL31=`ls rkbin/bin/rk35/rk3588_bl31*.elf`
	export BL31=`pwd`/$BL31
	export ROCKCHIP_TPL=`pwd`/$DDR
echo ""
echo "export ROCKCHIP_TPL=$ROCKCHIP_TPL"
echo "export BL31=$BL31"
echo ""
		export PATH=`pwd`/tools/binman:$PATH
echo ""
echo "PATH=$PATH"
echo ""

		git clone --depth 1 https://gitlab.com/u-boot/u-boot.git -b v2026.04
		cd u-boot
		if [ ! -f configs/$1 ]; then
			echo "$1 not found in configs"
			cd ..
			exit 1
		fi

	echo 'CONFIG_SYS_SOC="rk3588"' >> configs/$1
sed -i 's/#ifndef CONFIG_XPL_BUILD/#ifndef CONFIG_XPL_BUILD\n\n #define BOOT_TARGETS    "nvme scsi"\n\n/' include/configs/rockchip-common.h

		make clean $1
		make -j8
		cp u-boot-rockchip.bin /
	echo "dd if=u-boot-rockchip.bin of=/dev/sdX seek=1 bs=32k conv=fsync"
	cd ../..
exit 0

