#!/bin/bash
set -eE
trap 'echo "Error in $0 on line $LINENO"' ERR
set -x

# 1. 必ず /tmp で作業する（/ 直下での cp 自己参照エラー防止）

sudo apt-get update
sudo apt-get install -y build-essential devscripts dpkg-dev fakeroot wget equivs \
    docutils-common libudev-dev python3-docutils python3-roman-numerals \
    libpaper-utils python3-pil sgml-base xml-core

export DEBEMAIL="user@gmail.com"
export DEBFULLNAME="Panthor Builder"
export DEB_CFLAGS_APPEND=" -O3 -mcpu=cortex-a76.cortex-a55+crypto+dotprod+nosve -fno-plt"
export DEB_CXXFLAGS_APPEND=" -O3 -mcpu=cortex-a76.cortex-a55+crypto+dotprod+nosve -fno-plt"

# ==========================================
# 2. libdrm-2.4.134 のビルドとインストール
# ==========================================
rm -rf libdrm-build && mkdir -p libdrm-build && cd libdrm-build

wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/libdrm/2.4.134-3/libdrm_2.4.134-3.dsc
wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/libdrm/2.4.134-3/libdrm_2.4.134.orig.tar.xz
wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/libdrm/2.4.134-3/libdrm_2.4.134.orig.tar.xz.asc
wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/libdrm/2.4.134-3/libdrm_2.4.134-3.debian.tar.xz

dpkg-source -x libdrm_2.4.134-3.dsc
cd libdrm-2.4.134

#sudo mk-build-deps -i -r -t "apt-get -y"
mk-build-deps -t "apt-get -y"
DEB_BUILD_OPTIONS="noautodbgsym" dpkg-buildpackage -us -uc -b

cd ..
rm -f *build-deps*.deb
sudo dpkg -i *.deb
cp *.deb /

echo "------------------ LIBDRM 2.4.134 -----------------------"
ls -l /*libdrm*.deb
echo "---------------------------------------------------------"

# ==========================================
# 3. mesa-26.2.4 のビルド (Panthor特化)
# ==========================================
cd ..
WORK_DIR="panthor-mesa-build"
rm -rf "$WORK_DIR" && mkdir -p "$WORK_DIR" && cd "$WORK_DIR"

sudo apt-get install -y debhelper ninja-build meson pkg-config python3-mako \
    libdrm-dev libwayland-dev libwayland-bin libwayland-egl-backend-dev wayland-protocols \
    libx11-dev libx11-xcb-dev libxext-dev libxdamage-dev libxfixes-dev \
    libxcb-glx0-dev libxcb-shm0-dev libxcb-dri2-0-dev libxcb-dri3-dev \
    libxcb-present-dev libxcb-randr0-dev libxcb-xfixes0-dev libxcb-sync-dev libxcb1-dev \
    libxdmcp-dev libxrandr-dev libxrender-dev libxshmfence-dev libxxf86vm-dev x11proto-dev \
    libexpat1-dev libzstd-dev zlib1g-dev libpciaccess-dev libffi-dev libsensors-dev libxml2-dev \
    python3-ply python3-yaml python3-pip python3-setuptools python3-pycparser \
    glslang-tools spirv-tools spirv-tools-dev libglvnd-core-dev libvulkan-dev \
    libpng-dev libdisplay-info-dev libva-dev flatbuffers-compiler libflatbuffers-dev \
    libxtensor-dev nlohmann-json3-dev xtl-dev valgrind \
    bindgen cbindgen rustc rustfmt

sudo apt-get -y install directx-headers-dev libclang-22-dev libclang-cpp22-dev \
    libclc-22 libclc-22-dev libllvmspirvlib-22-dev librust-paste-dev \
    librust-rustc-hash-2-dev librust-syn-dev llvm-22-dev llvm-spirv-22
wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/mesa/26.2.7-1ubuntu1/mesa_26.2.7.orig.tar.xz
wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/mesa/26.2.7-1ubuntu1/mesa_26.2.7.orig.tar.xz.asc
wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/mesa/26.2.7-1ubuntu1/mesa_26.2.7-1ubuntu1.debian.tar.xz
wget https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/mesa/26.2.7-1ubuntu1/mesa_26.2.7-1ubuntu1.dsc

dpkg-source -x mesa_26.2.7-1ubuntu1.dsc
cd mesa-26.2.7
mk-build-deps -t "apt-get -y"
dpkg -i mesa-build-deps_26.2.7-1ubuntu1_arm64.deb

mesa_version="$(cat VERSION)"
echo "mesa_version=$mesa_version"

# changelog の更新（1回のみ）
dch -b --newversion "${mesa_version}-1ubuntu1+panthor1" \
    --distribution resolute \
    --force-distribution \
    "Custom Panthor-only build without heavy dependencies"

# debian/rules の書き換え
sed -i 's/-Dgallium-drivers=.*/-Dgallium-drivers=panfrost,kmsro,zink,softpipe /' debian/rules
if [ -d "src/vulkan/drivers/panvk" ]; then VULKAN="panvk"; else VULKAN="panfrost"; fi
sed -i "s/-Dvulkan-drivers=.*/-Dvulkan-drivers=${VULKAN},swrast /" debian/rules
sed -i 's/-Dllvm=enabled/-Dllvm=disabled/g' debian/rules
sed -i 's|usr/share/drirc.d/;|usr/share/drirc.d/ 2>/dev/null \|\| true;|g' debian/rules

# ダミーパッケージと Vulkan 指示書の調整
echo "README.rst usr/share/doc/mesa-common-dev/" > debian/mesa-drm-shim.install
echo "README.rst usr/share/doc/mesa-common-dev/" > debian/mesa-opencl-icd.install
echo "README.rst usr/share/doc/mesa-common-dev/" > debian/mesa-teflon-delegate.install

cat << EOF > debian/mesa-vulkan-drivers.install
README.rst usr/share/doc/mesa-common-dev/
usr/lib/*/libvulkan_lvp.so
usr/lib/*/libvulkan_${VULKAN}.so
usr/share/vulkan/icd.d/lvp_icd.*.json
usr/share/vulkan/icd.d/${VULKAN}_icd.*.json
EOF

# 依存チェックをスキップしてビルド
DEB_BUILD_OPTIONS="noautodbgsym" debuild -us -uc -b -d

DETECTED_VERSION=$(dpkg-parsechangelog -S Version)
echo "Freedesktop Mesa ${DETECTED_VERSION}" > /rel.txt

cd ..
cp *.deb /

echo "=========== MESA-DEB 26.2.4 完了 ========"
ls -l /*.deb /rel.txt

