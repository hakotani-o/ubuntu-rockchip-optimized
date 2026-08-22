#!/bin/bash
set -e # エラーが発生したらその時点で停止
set -x
sudo apt update
sudo apt install -y build-essential devscripts dpkg-dev fakeroot wget equivs
sudo apt install -y docutils-common libudev-dev python3-docutils python3-roman-numerals libpaper-utils python3-pil docutils-common libudev-dev python3-docutils python3-roman-numerals sgml-base xml-core 

export DEBEMAIL="user@localhost"
export DEBFULLNAME="Panthor Builder"
export DEB_CFLAGS_APPEND="-march=armv8-a+crypto+crc -mtune=cortex-a76.cortex-a55" 
export DEB_CXXFLAGS_APPEND="-march=armv8-a+crypto+crc -mtune=cortex-a76.cortex-a55" 

# 1. 作業用のディレクトリを作成して移動
rm -rf libdrm-build && mkdir -p libdrm-build && cd libdrm-build

# 最新 libdrm ソース
wget http://httpredir.debian.org/debian/pool/main/libd/libdrm/libdrm_2.4.134-3.dsc
wget http://httpredir.debian.org/debian/pool/main/libd/libdrm/libdrm_2.4.134.orig.tar.xz
wget http://httpredir.debian.org/debian/pool/main/libd/libdrm/libdrm_2.4.134.orig.tar.xz.asc

wget http://httpredir.debian.org/debian/pool/main/libd/libdrm/libdrm_2.4.134-3.debian.tar.xz

# 2. ソースコードの展開
dpkg-source -x libdrm_2.4.134-3.dsc

# 3. ビルド依存関係（Build-Depends）の解決
cd libdrm-2.4.134
mk-build-deps -i -r

# 4. パッケージをビルドする（署名はスキップ）
DEB_BUILD_OPTIONS="noautodbgsym" dpkg-buildpackage -us -uc -b

# 5. 1つ上のディレクトリに .deb ファイルが生成されるので、それをインストール
cd ..
sudo dpkg -i *.deb
cp *.deb /
cd /
echo "------------------ LIBDRM -----------------------"
pwd
ls -l *.deb
echo "-------------------------------------------------"

# 作業ディレクトリの作成
WORK_DIR="panthor-mesa-build"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

cd "$WORK_DIR"

echo "=== 1. 最小限のビルドツールのインストール ==="
sudo apt-get update
sudo apt-get install -y build-essential devscripts debhelper ninja-build \
    pkg-config python3-mako libdrm-dev libwayland-dev wayland-protocols \
    libx11-dev libxext-dev libxdamage-dev libxfixes-dev libxcb-glx0-dev \
    libxcb-shm0-dev libxcb-dri2-0-dev libxcb-dri3-dev libxshmfence-dev \
    libxrandr-dev libxxf86vm-dev libexpat1-dev libzstd-dev zlib1g-dev \
    python3-ply python3-yaml python3-pip python3-setuptools glslang-tools \
    spirv-tools libclc-21-dev llvm-21-dev libclang-cpp21-dev spirv-tools-dev \
    libllvmspirvlib-21-dev libclang-21-dev libwayland-egl-backend-dev \
    libxcb-randr0-dev  libdrm-dev libpciaccess-dev libffi-dev libsensors-dev libxml2-dev \
  libx11-dev libx11-xcb-dev libxcb-dri2-0-dev libxcb-dri3-dev libxcb-glx0-dev \
  libxcb-present-dev libxcb-randr0-dev libxcb-shm0-dev libxcb-xfixes0-dev libxcb1-dev \
  libxdmcp-dev libxext-dev libxrandr-dev libxrender-dev libxshmfence-dev libxxf86vm-dev \
  libwayland-dev libwayland-bin libwayland-egl-backend-dev wayland-protocols \
  libglvnd-core-dev libvulkan-dev glslang-tools python3-pycparser
  #libarchive-dev

sudo apt-get -y install bindgen cbindgen directx-headers-dev flatbuffers-compiler \
  flatbuffers-compiler-dev libclang-dev libclc-21 libdisplay-info-dev \
  libflatbuffers-dev libflatbuffers23.5.26 libgbm1 libgl1 libgl1-mesa-dri \
  libglvnd0 libglx-mesa0 libglx0 libpng-dev librust-allocator-api2-dev \
  librust-arbitrary-dev librust-bumpalo-dev librust-cfg-if-dev \
  librust-critical-section-dev librust-crossbeam-deque-dev \
  librust-crossbeam-epoch+std-dev librust-crossbeam-epoch-dev \
  librust-crossbeam-utils-dev librust-derive-arbitrary-dev librust-either-dev \
  librust-equivalent-dev librust-erased-serde-dev librust-foldhash-dev \
  librust-getrandom-dev librust-hashbrown-dev librust-indexmap-dev \
  librust-itoa-dev librust-js-sys-dev librust-libc-dev librust-log-dev \
  librust-malloc-size-of-dev librust-memchr-dev librust-no-panic-dev \
  librust-once-cell-dev librust-parking-lot-core-dev librust-paste-dev \
  librust-portable-atomic-dev librust-ppv-lite86-dev librust-proc-macro2-dev \
  librust-quote-dev librust-rand-chacha-dev librust-rand-core+getrandom-dev \
  librust-rand-core+serde-dev librust-rand-core+std-dev librust-rand-core-dev \
  librust-rand-dev librust-rayon-core-dev librust-rayon-dev \
 librust-rustc-hash-2-dev librust-rustversion-dev librust-ryu-dev \
  librust-serde-core-dev librust-serde-derive-dev librust-serde-dev \
  librust-serde-fmt-dev librust-serde-json-dev librust-serde-test-dev \
  librust-smallvec-dev librust-sval-buffer-dev librust-sval-derive-dev \
  librust-sval-dev librust-sval-dynamic-dev librust-sval-fmt-dev \
  librust-sval-ref-dev librust-sval-serde-dev librust-syn-dev \
  librust-unicode-ident-dev librust-value-bag-dev librust-value-bag-serde1-dev \
  librust-value-bag-sval2-dev librust-void-dev librust-wasm-bindgen-dev \
  librust-wasm-bindgen-macro-dev librust-wasm-bindgen-macro-support-dev \
  librust-wasm-bindgen-shared-dev librust-zerocopy-derive-dev \
  librust-zerocopy-dev libset-scalar-perl libstd-rust-1.93 \
libstd-rust-1.93-dev libva-dev libva-drm2 libva-glx2 libva-wayland2 \
  libva-x11-2 libva2 libxtensor-dev llvm-spirv-21 mesa-libgallium \
  nlohmann-json3-dev rustc rustc-1.93 rustfmt rustfmt-1.93 xtl-dev 

# 1. mesa ダウンロード
wget http://httpredir.debian.org/debian/pool/main/m/mesa/mesa_26.1.6-1.dsc
wget http://httpredir.debian.org/debian/pool/main/m/mesa/mesa_26.1.6.orig.tar.xz
wget http://httpredir.debian.org/debian/pool/main/m/mesa/mesa_26.1.6.orig.tar.xz.asc
wget http://httpredir.debian.org/debian/pool/main/m/mesa/mesa_26.1.6-1.debian.tar.xz

# 2. ソースコードの展開
dpkg-source -x mesa_26.1.6-1.dsc

# 3. ビルド依存関係（Build-Depends）の解決
cd mesa-26.1.6
mk-build-deps -i -r

mesa_version="$(cat VERSION)"
echo "mesa_version=$mesa_version"

### === 【追加】debian/changelog の自動書き換え ===
echo "=== 2.5. debian/changelog の自動書き換え (Panthorバージョン化) ==="
# Ubuntu 26.04 (resolute) の場合を想定しています。お使いのバージョンに合わせて noble を変更してください。
# エディタを開かずに、非対話で changelog の先頭にカスタムバージョンを追加します。
DEBEMAIL="opi5plus@bcc.example.com" DEBFULLNAME="hakotani-o" \
dch -b --newversion "${mesa_version}-1ubuntu1~panthor1" \
    --distribution resolute \
    --force-distribution \
    "Build for Panthor GPU support with optimization"

# vulkan-drivers の行を置換 (panfrost,swrast のみに制限)
echo "=== 3. debian/rules の書き換え (Panthor最適化) ==="
# 1. ドライバーの絞り込み（これはそのまま残します。ビルドが爆速・軽量になります）
sed -i 's/-Dgallium-drivers=.*/-Dgallium-drivers=panfrost,kmsro,zink,softpipe /' debian/rules
if [ -d "src/vulkan/drivers/panvk" ]; then VULKAN="panvk"; else VULKAN="panfrost"; fi
sed -i "s/-Dvulkan-drivers=.*/-Dvulkan-drivers=${VULKAN},swrast /" debian/rules
sed -i 's/-Dllvm=enabled/-Dllvm=disabled/g' debian/rules

# 2. 【★ここが最大のポイント★】
# 指示書を「消す」のではなく、「ファイルがなくてもパッケージ作成を続行しろ」という魔
# 法のフラグを debian/rules に注入します。
# これにより、中身が空っぽの「他社用.deb」が自動的に生成されるようになります！
### sed -i 's/dh_install/dh_install --missing-ok/g' debian/rules
echo "=== 3. debian/rules の書き換え (Panthor最適化) ==="
# 2. 【★今回新しく追加する1行★】
# Mesa 26特有の _drv_video.so 移動処理（連続する3行）を丸ごとコメントアウトします
sed -i '/Copy the hardlinked va drivers correctly/,/debian\/mesa-libgallium\/usr\/lib/ s/^/#/' debian/rules
sed -i '/mv debian\/tmp\/usr\/lib\/\${DEB_HOST_MULTIARCH}\/dri\/\*_drv_video.so/,/debian\/mesa-libgallium\/usr\/lib\/\${DEB_HOST_MULTIARCH}\/dri/ s/^/#/' debian/rules
# HAKO03
sed -i 's/# use -f here though/rm debian\/tmp\/usr\/lib\/aarch64-linux-gnu\/dri\/nouveau_drv_video.so \n	rm debian\/tmp\/usr\/lib\/aarch64-linux-gnu\/dri\/virtio_gpu_drv_video.so \n	# use -f here though\n/' debian/rules

echo "=== 3. debian/rules と指示書の書き換え (Panthor最適化) ==="
# 【★これを追加★】エラーの原因になる他社用パッケージの指示書を、絶対に存在する「空のディレクトリ」の指定に書き換えます
# これにより、中身は空っぽでも「有効な.debファイル」が100%安全に生成されるようになります
echo "README.rst usr/share/doc/mesa-common-dev/" > debian/mesa-drm-shim.install
echo "README.rst usr/share/doc/mesa-common-dev/" > debian/mesa-opencl-icd.install
echo "README.rst usr/share/doc/mesa-common-dev/" > debian/mesa-teflon-delegate.install
# 2. 【★ここを修正★】Vulkanの指示書には、ダミーだけでなく「Panthorの本物（panfrost/lvp）」だけを狙って書き込みます！
# これにより、他社製エラーを回避しつつ、Panthorのコアがちゃんとパッケージにパックされます。
cat << 'EOF' > debian/mesa-vulkan-drivers.install
README.rst usr/share/doc/mesa-common-dev/
usr/lib/*/libvulkan_lvp.so
usr/lib/*/libvulkan_panfrost.so
usr/share/vulkan/icd.d/lvp_icd.*.json
usr/share/vulkan/icd.d/panfrost_icd.*.json
EOF
# usr/lib/*/libvulkan_panvk.so
# usr/share/vulkan/icd.d/panvk_icd.*.json

echo "=== 4. パッケージバージョンの変更 (自動上書き防止) ==="
# バージョン末尾に「~panthor1」を自動付与
CURRENT_VERSION=$(dpkg-parsechangelog -S Version)
# debchange --force-bad-version --newversion "${CURRENT_VERSION}~panthor1" "Custom Panthor-only build without heavy dependencies"
# 修正後の推奨コード (例: 26.0.3-1ubuntu1+panthor1)
debchange --force-bad-version --newversion "${CURRENT_VERSION}+panthor1" "Custom Panthor-only build without heavy dependencies"

echo "=== 5. 依存チェックを無視してビルド実行 ==="
# -d フラグで不要なビルド依存（Intel/AMD用ライブラリなど）のチェックをスキップ
#DEB_BUILD_OPTIONS="terse noautodbgsym" debuild -us -uc -b -d
DEB_BUILD_OPTIONS="noautodbgsym" debuild -us -uc -b -d

echo "=== 6. ビルド完了 ==="
DETECTED_VERSION=$(dpkg-parsechangelog -S Version)
echo "Freedesktop Mesa ${DETECTED_VERSION}" > /rel.txt
cd ..
cp *.deb /
cd /
echo "以下のディレクトリにPanthor専用の .deb パッケージが生成されました:"
echo "=========== MESA-DEB ========"
pwd
ls -l *.deb

echo "---------------------- MESA ----------------------------"
echo "インストールする場合は、以下のコマンドを実行してください："
echo "cd $(pwd) && sudo dpkg -i *.deb"
echo "--------------------------------------------------"
