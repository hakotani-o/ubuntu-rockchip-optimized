#!/bin/bash

#suite=plucky
suite=resolute
#Uri="http://ftp.udx.icscoe.jp/Linux/ubuntu-ports/"
Uri="http://ports.ubuntu.com/ubuntu-ports"


	start_time=`date`

	sudo rm -f log?
	sudo ./build_kernel_env.sh orangepi-5-rk3588s_defconfig $Uri $suite kernel
	sudo ./mesa-build-env.sh arm64 $1 $Uri $suite
	#sudo ./meas-build-env.sh arm64 ubuntu $Uri $suite
	sudo ./rootfs-bootstrap.sh arm64 $Uri $suite
	sudo ./disk_image.sh arm64 orangepi-5 rk3588s-orangepi-5
	sudo mv overlay/u-boot-rockchip.bin overlay/orangepi-5-u-boot-rockchip.bin
	sudo ./build_kernel_env.sh orangepi-5-plus-rk3588_defconfig $Uri $suite u-boot
	sudo ./disk_image.sh arm64 orangepi-5-plus rk3588-orangepi-5-plus
	sudo mv overlay/u-boot-rockchip.bin overlay/orangepi-5-PLUS-u-boot-rockchip.bin

	echo "$start_time"
	date
