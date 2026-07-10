#!/bin/bash
set -e # 发生错误时立即停止
set -x
 echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports resolute main restricted universe multiverse" | sudo tee /etc/apt/sources.list.d/ubuntu26-src.list
 echo "deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports resolute-updates main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list.d/ubuntu26-src.list

# 1. 创建工作目录并进入
mkdir -p ~/libdrm-build && cd ~/libdrm-build

# 最新 libdrm 源码（例：从 GitHub clone）
# git clone https://github.com source
# cd source

# 2. 安装依赖关系，下载官方源代码
sudo apt update
sudo apt build-dep libdrm -y
apt-get source libdrm
# 使用最新libdrm源码时
# cp -r libdrm-*/debian ./
# rm -rf libdrm-*/


# 3. 【重要】进入下载的源代码「文件夹内部」
# (执行 apt-get source 后会自动创建 libdrm-2.x.x 这样的文件夹)
cd libdrm-*/

# 4. 构建软件包（跳过签名）
DEB_BUILD_OPTIONS="noautodbgsym" dpkg-buildpackage -us -uc -b

# 5. .deb 文件生成在上级目录中，安装它们
cd ..
sudo dpkg -i *.deb
cp *.deb /
cd /
echo "------------------ LIBDRM -----------------------"
pwd
ls -l *.deb
echo "-------------------------------------------------"
# 创建工作目录
WORK_DIR="panthor-mesa-build"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

cd "$WORK_DIR"

echo "=== 1. 安装最小构建工具集 ==="
sudo apt-get update
sudo apt-get install -y build-essential devscripts debhelper ninja-build \
    pkg-config python3-mako libdrm-dev libwayland-dev wayland-protocols \
    libx11-dev libxext-dev libxdamage-dev libxfixes-dev libxcb-glx0-dev \
    libxcb-shm0-dev libxcb-dri2-0-dev libxcb-dri3-dev libxshmfence-dev \
    libxrandr-dev libxxf86vm-dev libexpat1-dev libzstd-dev zlib1g-dev \
    python3-ply python3-yaml python3-pip python3-setuptools glslang-tools \
    spirv-tools libclc-21-dev llvm-21-dev libclang-cpp21-dev \
    libllvmspirvlib-21-dev libclang-21-dev libwayland-egl-backend-dev \
    libxcb-randr0-dev  libdrm-dev libpciaccess-dev libffi-dev libsensors-dev libxml2-dev spirv-tools-dev \
  libx11-dev libx11-xcb-dev libxcb-dri2-0-dev libxcb-dri3-dev libxcb-glx0-dev \
  libxcb-present-dev libxcb-randr0-dev libxcb-shm0-dev libxcb-xfixes0-dev libxcb1-dev \
  libxdmcp-dev libxext-dev libxrandr-dev libxrender-dev libxshmfence-dev libxxf86vm-dev \
  libwayland-dev libwayland-bin libwayland-egl-backend-dev wayland-protocols \
  libglvnd-core-dev libvulkan-dev glslang-tools python3-pycparser 
  #libarchive-dev


# 2. 如果已安装 apt 版的旧 meson，将其删除，用 pip 安装最新版 meson
# sudo apt-get remove -y meson
# sudo python3 -m pip install --break-system-packages --upgrade meson

# 【★在此添加★】在 debuild 能识别的位置创建符号链接
# sudo ln -sf /usr/local/bin/meson /usr/bin/meson



# 下载源码
apt source mesa
MESA_SRC_DIR=$(ls -d mesa-*)
cd "$MESA_SRC_DIR"

### === 【追加】自动重写 debian/changelog ===
echo "=== 2.5. 自动重写 debian/changelog (Panthor版本化) ==="
# 假设为 Ubuntu 26.04 (resolute)。请根据您使用的版本更改 noble。
# 不打开编辑器，以非交互方式将自定义版本添加到 changelog 的开头。
DEBEMAIL="opi5plus@bcc.example.com" DEBFULLNAME="hakotani-o" \
dch -b --newversion "26.0.3-1ubuntu1~panthor1" \
    --distribution resolute \
    --force-distribution \
    "Build for Panthor GPU support with optimization"


### echo "=== 3. 重写 debian/rules (Panthor优化) ==="
# 替换 gallium-drivers 行 (限制为 panfrost,kmsro,zink,softpipe)
### sed -i 's/-Dgallium-drivers=.*/-Dgallium-drivers=panfrost,kmsro,zink,softpipe/' debian/rules
# (请在已有的驱动重写处理之后添加以下内容)
# 为防止不存在的文件导致错误，为 rm 添加 -f 标志
###  sed -i 's/rm debian\/tmp\/usr\/lib\/\*\/libEGL_mesa.so/rm -f debian\/tmp\/usr\/lib\/\*\/libEGL_mesa.so/g' debian/rules
###  sed -i 's/rm debian\/tmp\/usr\/lib\/\*\/libGLX_mesa.so/rm -f debian\/tmp\/usr\/lib\/\*\/libGLX_mesa.so/g' debian/rules
# vdpau文件不存在时防止 mv 命令出错的补丁
#sed -i 's/mv debian\/tmp\/usr\/lib\/\*\/vdpau/if [ -d debian\/tmp\/usr\/lib\/\*\/vdpau ]; then mv debian\/tmp\/usr\/lib\/\*\/vdpau/g' debian/rules
#sed -i 's/libvdpau\*.so\*/libvdpau\*.so\*; fi/g' debian/rules
### echo "=== 3. 重写 debian/rules (Panthor优化) ==="
# (前略：保留 rm -f 的两行即可)
# 【★删除上次 vdpau 的2行，替换为这一行★】
# 将试图移动 vdpau 的处理（连续3行）全部在行首添加「#」注释掉
### sed -i '/install -m755 -d debian\/mesa-vdpau-drivers/,/debian\/mesa-vdpau-drivers\/usr\/lib/ s/^/#/' debian/rules
# 【★此次新增的1行★】
# 将试图移动 _drv_video.so 的处理（连续2行）全部在行首添加「#」注释掉
### sed -i '/install -m755 -d debian\/mesa-va-drivers/,/debian\/mesa-va-drivers\/usr\/lib/ s/^/#/' debian/rules
# HAKO 01
### sed -i '/mv debian\/tmp\/usr\/lib\/\${DEB_HOST_MULTIARCH}\/dri\/\*_drv_video.so/,/debian\/mesa-libgallium\/usr\/lib\/\${DEB_HOST_MULTIARCH}\/dri/ s/^/#/' debian/rules
### truncate -s 0 debian/mesa-drm-shim.install
### truncate -s 0 debian/mesa-opencl-icd.install
# 【★此次新增的2行★】
# 从 Vulkan 软件包的安装列表中，删除未生成的 layer 文件的描述
### sed -i '/libVkLayer_/d' debian/mesa-vulkan-drivers.install
### sed -i '/implicit_layer.d/d' debian/mesa-vulkan-drivers.install
# 【★此次新增的1行★】
# 从 Vulkan 软件包的安装列表中，也删除 explicit_layer 的描述
### sed -i '/explicit_layer.d/d' debian/mesa-vulkan-drivers.install
# 【★此次新增的1行★】
# 从 Vulkan 软件包的安装列表中，删除 AMD 用配置文件的描述
### sed -i '/00-radv-defaults.conf/d' debian/mesa-vulkan-drivers.install
# 从安装列表中彻底删除不需要的文件的4行（这4行齐了就OK）
### sed -i '/libVkLayer_/d' debian/mesa-vulkan-drivers.install
### sed -i '/implicit_layer.d/d' debian/mesa-vulkan-drivers.install
### sed -i '/explicit_layer.d/d' debian/mesa-vulkan-drivers.install
### sed -i '/00-radv-defaults.conf/d' debian/mesa-vulkan-drivers.install
# 1. 将 teflon 软件包的安装列表清空
### truncate -s 0 debian/mesa-teflon-delegate.install
# 2. 从 Vulkan 软件包的安装列表中，删除 overlay-control 的描述
### sed -i '/mesa-overlay-control.py/d' debian/mesa-vulkan-drivers.install
# HAKO 02
### sed -i '/mesa-screenshot-control.py/d' debian/mesa-vulkan-drivers.install

# 替换 vulkan-drivers 行 (限制为 panfrost,swrast)
# ※根据 Mesa 版本，指定名可能是 panfrost 或 panvk，从源码文件夹名自动判断
### if [ -d "src/vulkan/drivers/panvk" ]; then
###    VULKAN_DRIVER_NAME="panvk"
### else
###    VULKAN_DRIVER_NAME="panfrost"
### fi
### sed -i "s/-Dvulkan-drivers=.*/-Dvulkan-drivers=${VULKAN_DRIVER_NAME},swrast/" debian/rules

# 因已禁用需要 LLVM 的其他驱动（iris, radeonsi等），关闭 LLVM 依赖设置本身
### sed -i 's/-Dllvm=enabled/-Dllvm=disabled/g' debian/rules

echo "=== 3. 重写 debian/rules (Panthor优化) ==="
# 1. 精简驱动（保留此项。构建会变得极速、轻量）
sed -i 's/-Dgallium-drivers=.*/-Dgallium-drivers=panfrost,kmsro,zink,softpipe /' debian/rules
if [ -d "src/vulkan/drivers/panvk" ]; then VULKAN="panvk"; else VULKAN="panfrost"; fi
sed -i "s/-Dvulkan-drivers=.*/-Dvulkan-drivers=${VULKAN},swrast /" debian/rules
sed -i 's/-Dllvm=enabled/-Dllvm=disabled/g' debian/rules

# 2. 【★这是最大的关键点★】
# 不是「删除」安装列表，而是向 debian/rules 注入「即使文件不存在也继续打包」的魔法标志。
# 这样，内容为空的「第三方用.deb」就会自动生成！
### sed -i 's/dh_install/dh_install --missing-ok/g' debian/rules
echo "=== 3. 重写 debian/rules (Panthor优化) ==="
# 2. 【★此次新增的1行★】
# 将 Mesa 26 特有的 _drv_video.so 移动处理（连续3行）全部注释掉
sed -i '/Copy the hardlinked va drivers correctly/,/debian\/mesa-libgallium\/usr\/lib/ s/^/#/' debian/rules
sed -i '/mv debian\/tmp\/usr\/lib\/\${DEB_HOST_MULTIARCH}\/dri\/\*_drv_video.so/,/debian\/mesa-libgallium\/usr\/lib\/\${DEB_HOST_MULTIARCH}\/dri/ s/^/#/' debian/rules


echo "=== 3. 重写 debian/rules 和安装列表 (Panthor优化) ==="
# (前略：请保留 hakotani 先生之前创建的 *_drv_video.so mv 注释行！)

# 【★添加此项★】将导致错误的第三方软件包安装列表，改写为指向肯定存在的「空目录」
# 这样，即使内容是空的，也能 100% 安全地生成「有效的 .deb 文件」
echo "README.rst usr/share/doc/mesa-common-dev/" > debian/mesa-drm-shim.install
echo "README.rst usr/share/doc/mesa-common-dev/" > debian/mesa-opencl-icd.install
echo "README.rst usr/share/doc/mesa-common-dev/" > debian/mesa-teflon-delegate.install
# 2. 【★在此修正★】在 Vulkan 安装列表中，不仅写 dummy，而是只针对「Panthor的真货（panfrost/lvp）」来写入！
# 这样，在避免第三方错误的同时，Panthor 的核心组件能被正确打包。
cat << 'EOF' > debian/mesa-vulkan-drivers.install
README.rst usr/share/doc/mesa-common-dev/
usr/lib/*/libvulkan_lvp.so
usr/lib/*/libvulkan_panfrost.so
usr/share/vulkan/icd.d/lvp_icd.*.json
usr/share/vulkan/icd.d/panfrost_icd.*.json
EOF


echo "=== 4. 修改软件包版本 (防止自动覆盖) ==="
# 在版本末尾自动追加「~panthor1」
CURRENT_VERSION=$(dpkg-parsechangelog -S Version)
export DEBEMAIL="user@localhost"
export DEBFULLNAME="Panthor Builder"
debchange --force-bad-version --newversion "${CURRENT_VERSION}~panthor1" "Custom Panthor-only build without heavy dependencies"

echo "=== 5. 忽略依赖检查执行构建 ==="
# -d 标志跳过不必要的构建依赖（Intel/AMD用库等）检查
DEB_BUILD_OPTIONS="terse noautodbgsym" debuild -us -uc -b -d

echo "=== 6. 构建完成 ==="
DETECTED_VERSION=$(dpkg-parsechangelog -S Version)
echo "Ubuntu Mesa ${DETECTED_VERSION}" > /rel.txt
cd ..
cp *.deb /
cd /
echo "Panthor专用 .deb 软件包已生成在以下目录："
echo "=========== MESA-DEB ========"
pwd
ls -l *.deb

echo "---------------------- MESA ----------------------------"
echo "如需安装，请执行以下命令："
echo "cd $(pwd) && sudo dpkg -i *.deb"
echo "--------------------------------------------------"

	

# ubuntu-image hook或chroot内执行的处理示例
#dpkg -i /tmp/patches/mesa-panthor/*.deb
#apt-get install -f -y  # 仅自动解决执行所需的最小依赖（libdrm等）
