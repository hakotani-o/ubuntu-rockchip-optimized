#!/bin/bash
set -eE 
trap 'echo Error: in $0 on line $LINENO' ERR

set -x

cleanup_loopdev() {
    local loop="$1"

    sync --file-system
    sync

    sleep 1

    if [ -b "${loop}" ]; then
        for part in "${loop}"p*; do
            if mnt=$(findmnt -n -o target -S "$part"); then
                umount "${mnt}"
            fi
        done
        losetup -d "${loop}"
    fi
}

wait_loopdev() {
    local loop="$1"
    local seconds="$2"

    until test $((seconds--)) -eq 0 -o -b "${loop}"; do sleep 1; done

    ((++seconds))

    ls -l "${loop}" &> /dev/null
}

if [ "$(id -u)" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

export  LC_ALL=C 
export  LC_CTYPE=C
export  LANGUAGE=C
export  LANG=C

if [ ! -f ./overlay/rootfs ]; then 
	exit 1 
fi

sudo apt-get update && sudo apt-get -y install uuid-runtime 

. ./overlay/rootfs
. ./overlay/kernel_version

rootfs="$(readlink -f "$rootfs")"
if [[ "$(basename "${rootfs}")" != *".rootfs.tar.gz" || ! -e "${rootfs}" ]]; then
    echo "Error: $(basename "${rootfs}") must be a rootfs tarfile"
    exit 1
fi

now=`date +%F`
# Create an empty disk image
img="./Ubuntu-${kernel_version}-$2-$now.img"
size="$(( $(gzip -l "${rootfs}" | awk 'NR==2 {print $2}')   / 1024 / 1024 ))"
truncate -s "$(( size + 2048 ))M" "${img}"

# Create loop device for disk image
loop="$(losetup -f)"
losetup -P "${loop}" "${img}"
disk="${loop}"

# Cleanup loopdev on early exit
trap 'cleanup_loopdev ${loop}' EXIT

# Ensure disk is not mounted
mount_point=/tmp/mnt
umount "${disk}"* 2> /dev/null || true
umount ${mount_point}/* 2> /dev/null || true
mkdir -p ${mount_point}

    # Setup partition table
    dd if=/dev/zero of="${disk}" count=4096 bs=512
    parted --script "${disk}" \
    mklabel gpt \
    mkpart primary ext4 16MiB 100%

    # Create partitions
    {
        echo "t"
        echo "1"
        echo "C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
        echo "w"
    } | fdisk "${disk}" &> /dev/null || true

    partprobe "${disk}"

    partition_char="$(if [[ ${disk: -1} == [0-9] ]]; then echo p; fi)"

    sleep 1

    wait_loopdev "${disk}${partition_char}1" 60 || {
        echo "Failure to create ${disk}${partition_char}1 in time"
        exit 1
    }

    sleep 1

    # Generate random uuid for bootfs
    root_uuid=$(uuidgen)

    # Create filesystems on partitions
    dd if=/dev/zero of="${disk}${partition_char}1" bs=1KB count=10 > /dev/null
    mkfs.ext4 -U "${root_uuid}" -L desktop-rootfs "${disk}${partition_char}1"

    # Mount partitions
    mkdir -p ${mount_point}/writable
    mount "${disk}${partition_char}1" ${mount_point}/writable


# Copy the rootfs to root partition
tar -zxpf "${rootfs}" -C ${mount_point}/writable

fdt_name="rockchip/$3.dtb"
dtbs_install_path="/usr/lib/linux-image-"

#if [ ! -f ${mount_point}/writable${dtbs_install_path}${kernel_version}${fdt_name} ]; then
#	echo "${dtbs_install_path}${kernel_version}${fdt_name}"
#	echo "$3.dtb not found"
#	exit 1
#fi



# Create fstab entries
echo "# <file system>     <mount point>  <type>  <options>   <dump>  <fsck>" > ${mount_point}/writable/etc/fstab
echo "UUID=${root_uuid,,} /              ext4    defaults,noatime,errors=remount-ro    0       1" >> ${mount_point}/writable/etc/fstab

# Write bootloader to disk image
if [ -f "overlay/u-boot-rockchip.bin" ]; then
    dd if="overlay/u-boot-rockchip.bin" of="${loop}" seek=1 bs=32k conv=fsync
else
	echo "overlay/u-boot-rockchip.bin not found"
	exit 1
fi

echo U_BOOT_FDT='"'"$fdt_name"'"' >> ${mount_point}/writable/etc/default/u-boot
echo U_BOOT_FDT_DIR='"'"$dtbs_install_path"'"' >> ${mount_point}/writable/etc/default/u-boot
#echo U_BOOT_FDT_OVERLAYS_DIR='"/usr/lib/linux-image-"' >> ${mount_point}/writable/etc/default/u-boot

mountpoint="${mount_point}/writable"

mount dev-live -t devtmpfs "$mountpoint/dev"
mount devpts-live -t devpts -o nodev,nosuid "$mountpoint/dev/pts"
mount proc-live -t proc "$mountpoint/proc"
mount sysfs-live -t sysfs "$mountpoint/sys"
mount securityfs -t securityfs "$mountpoint/sys/kernel/security"

# ==================== ★【確定版】自作自動拡張サービスをchroot内に仕込む ====================
echo "仕込み中: Ubuntu 26.04 用自動拡張サービス"
chroot ${mount_point}/writable/ /bin/bash -c "
# 1. まずAPTリポジトリを更新し、正しいパッケージ名（e2fsprogs）でインストール
# apt-get update
# apt-get install -y cloud-guest-utils e2fsprogs

# 2. 自動拡張設定スクリプト本体の作成
cat << 'EOF' > /usr/local/bin/firstboot-growroot.sh
#!/bin/bash
# ログファイルに出力をすべてリダイレクト
exec > /var/log/firstboot-growroot.log 2>&1

echo \"=== Starting RootFS Auto Grow ===\"

# ルートマウント元のデバイスとパーティション番号を取得
ROOT_DEV=\$(findmnt -n -o SOURCE /)
DEV=\$(lsblk -no PKNAME \"\${ROOT_DEV}\")
PART=\$(echo \"\${ROOT_DEV}\" | grep -o '[0-9]*\$')

if [ -z \"\${DEV}\" ] || [ -z \"\${PART}\" ]; then
    echo \"ERROR: Could not detect root device.\"
    exit 1
fi

DEV_PATH=\"/dev/\${DEV}\"
echo \"Target Device: \${DEV_PATH}, Partition: \${PART}\"

# パーティション拡張
growpart \"\${DEV_PATH}\" \"\${PART}\"

# カーネルへパーティション変更の通知
partx -u \"\${ROOT_DEV}\"

# オンラインリサイズ実行 (e2fsprogsのresize2fsを使用)
resize2fs \"\${ROOT_DEV}\"

echo \"=== RootFS Auto Grow Completed ===\"

# 自身を無効化して次回から動かさない（自爆）
systemctl disable firstboot-growroot.service
EOF

# 実行権限の付与
chmod +x /usr/local/bin/firstboot-growroot.sh

# 3. systemd サービスファイルの作成
cat << 'EOF' > /etc/systemd/system/firstboot-growroot.service
[Unit]
Description=First Boot Root Partition Resizer
After=local-fs.target
Before=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/firstboot-growroot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# サービスの有効化
systemctl enable firstboot-growroot.service
"
# ====================================================================================


echo "---------------Check the u-boot settings.----------------"
cat ${mount_point}/writable/etc/default/u-boot
echo "----------------------------------------------------------"

# u-boot-update 
chroot ${mount_point}/writable/ /bin/bash -c "u-boot-update&&sync"

sync --file-system
sync

umount "$mountpoint/sys/kernel/security"
umount "$mountpoint/sys"
umount "$mountpoint/proc"
umount "$mountpoint/dev/pts"
umount "$mountpoint/dev"
umount "$mountpoint"

# Umount partitions

# Remove loop device
losetup -d "${loop}"

# Exit trap is no longer needed
trap '' EXIT
mkdir -p images
mv ${img} images
#echo -e "\nCompressing $(basename "${img}.xz")\n"
xz -v -9 -T0 images/"${img}"
#rm "${img}"
#cd ./images && sha256sum "$(basename "${img}.xz")" > "$(basename "${img}.xz.sha256")"
exit 0
