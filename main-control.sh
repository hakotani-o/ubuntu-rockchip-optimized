#!/bin/bash

#suite=plucky
suite=resolute
#Uri="http://ftp.udx.icscoe.jp/Linux/ubuntu-ports/"
Uri="http://ports.ubuntu.com/ubuntu-ports"


	start_time=`date`

	sudo rm -f log?
	sudo ./build_kernel_env.sh orangepi-5-rk3588s_defconfig $Uri $suite kernel 2>&1|tee log0
	sudo  ./mesa-build-env.sh arm64 $1 $Uri $suite 2>&1|tee log2
	#sudo  ./meas-build-env.sh arm64 ubuntu $Uri $suite 2>&1|tee log2
	sudo  ./rootfs-bootstrap.sh arm64 $Uri $suite 2>&1|tee log3
	sudo  ./disk_image.sh arm64 orangepi-5 rk3588s-orangepi-5 2>&1|tee log4
	sudo mv overlay/u-boot-rockchip.bin overlay/orangepi-5-u-boot-rockchip.bin
	sudo ./build_kernel_env.sh orangepi-5-plus-rk3588_defconfig $Uri $suite u-boot 2>&1|tee log5
	sudo  ./disk_image.sh arm64 orangepi-5-plus rk3588-orangepi-5-plus 2>&1|tee log6
	sudo mv overlay/u-boot-rockchip.bin overlay/orangepi-5-PLUS-u-boot-rockchip.bin

	echo "$start_time"
	date
