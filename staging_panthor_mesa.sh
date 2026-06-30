#!/bin/bash
set -e # エラーが発生したらその時点で停止
set -x
 echo "deb-src http://ports.ubuntu.com/ubuntu-ports resolute main restricted universe multiverse" | sudo tee /etc/apt/sources.list.d/ubuntu26-src.list
 echo "deb-src http://ports.ubuntu.com/ubuntu-ports resolute-updates main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list.d/ubuntu26-src.list

# 1. 作業用のディレクトリを作成して移動
rm -rf libdrm-build && mkdir -p libdrm-build && cd libdrm-build

# 最新 libdrm ソース（例: GitHubからcloneしたもの）
git clone --depth 1 https://gitlab.freedesktop.org/mesa/libdrm.git source
cd source

# 2. 依存関係のインストールと、公式ソースコードのダウンロード
sudo apt update
sudo apt build-dep libdrm -y
apt-get source libdrm
# 最新libdrm ソースの場合
cp -r libdrm-*/debian ./
rm -rf libdrm-*/

cd debian
patch -p1 < /libdrm-amdgpu1.symbols.patch
cd ..
# 3. 【重要】ダウンロードされたソースコードの「フォルダの中」に移動します
# (apt-get source を実行すると、libdrm-2.x.x のようなフォルダが自動で作られます)
#cd libdrm-*/

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


# 2. apt版の古いmesonが入っていれば削除し、pipで最新版のmesonをシステムに導入します
# sudo apt-get remove -y meson
# sudo python3 -m pip install --break-system-packages --upgrade meson

# 【★ここを追加★】debuildが認識できる場所にシンボリックリンクを作成します
# sudo ln -sf /usr/local/bin/meson /usr/bin/meson

# 最新 libdrm ソース（例: GitHubからcloneしたもの）
git clone --depth 1 https://gitlab.freedesktop.org/mesa/mesa.git -b staging/26.0 source
cd source


# ソースのダウンロード
apt source mesa
MESA_SRC_DIR=$(ls -d mesa-*)
cp -r $MESA_SRC_DIR/debian ./
rm -rf  "$MESA_SRC_DIR"
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


### echo "=== 3. debian/rules の書き換え (Panthor最適化) ==="
# gallium-drivers の行を置換 (panfrost,kmsro,zink,softpipe のみに制限)
### sed -i 's/-Dgallium-drivers=.*/-Dgallium-drivers=panfrost,kmsro,zink,softpipe/' debian/rules
# (既存のドライバー書き換え処理のあとに以下を追加してください)
# 存在しないファイルでエラーになるのを防ぐため、rm に -f フラグを追加する
###  sed -i 's/rm debian\/tmp\/usr\/lib\/\*\/libEGL_mesa.so/rm -f debian\/tmp\/usr\/lib\/\*\/libEGL_mesa.so/g' debian/rules
###  sed -i 's/rm debian\/tmp\/usr\/lib\/\*\/libGLX_mesa.so/rm -f debian\/tmp\/usr\/lib\/\*\/libGLX_mesa.so/g' debian/rules
# vdpauファイルが存在しない場合に mv コマンドでエラーになるのを防ぐパッチ
#sed -i 's/mv debian\/tmp\/usr\/lib\/\*\/vdpau/if [ -d debian\/tmp\/usr\/lib\/\*\/vdpau ]; then mv debian\/tmp\/usr\/lib\/\*\/vdpau/g' debian/rules
#sed -i 's/libvdpau\*.so\*/libvdpau\*.so\*; fi/g' debian/rules
### echo "=== 3. debian/rules の書き換え (Panthor最適化) ==="
# (前略：rm -f の2行は残したままでOKです)
# 【★前回のvdpauの2行を消して、この1行に差し替えます★】
# vdpauを移動させようとする処理（連続する3行）を、先頭に「#」をつけて丸ごと無効化します
### sed -i '/install -m755 -d debian\/mesa-vdpau-drivers/,/debian\/mesa-vdpau-drivers\/usr\/lib/ s/^/#/' debian/rules
# 【★今回新しく追加する1行★】
# _drv_video.soを移動させようとする処理（連続する2行）を、先頭に「#」をつけて無効化します
### sed -i '/install -m755 -d debian\/mesa-va-drivers/,/debian\/mesa-va-drivers\/usr\/lib/ s/^/#/' debian/rules
# HAKO 01
### sed -i '/mv debian\/tmp\/usr\/lib\/\${DEB_HOST_MULTIARCH}\/dri\/\*_drv_video.so/,/debian\/mesa-libgallium\/usr\/lib\/\${DEB_HOST_MULTIARCH}\/dri/ s/^/#/' debian/rules
### truncate -s 0 debian/mesa-drm-shim.install
### truncate -s 0 debian/mesa-opencl-icd.install
# 【★今回新しく追加する2行★】
# Vulkanパッケージの指示書から、生成されなかったレイヤーファイルの記述を削除します
### sed -i '/libVkLayer_/d' debian/mesa-vulkan-drivers.install
### sed -i '/implicit_layer.d/d' debian/mesa-vulkan-drivers.install
# 【★今回新しく追加する1行★】
# Vulkanパッケージの指示書から、explicit_layer の記述も削除します
### sed -i '/explicit_layer.d/d' debian/mesa-vulkan-drivers.install
# 【★今回新しく追加する1行★】
# Vulkanパッケージの指示書から、AMD用の設定ファイルの記述を削除します
### sed -i '/00-radv-defaults.conf/d' debian/mesa-vulkan-drivers.install
# 指示書から不要なファイルを確実に削除する4行（ここが揃っていればOKです）
### sed -i '/libVkLayer_/d' debian/mesa-vulkan-drivers.install
### sed -i '/implicit_layer.d/d' debian/mesa-vulkan-drivers.install
### sed -i '/explicit_layer.d/d' debian/mesa-vulkan-drivers.install
### sed -i '/00-radv-defaults.conf/d' debian/mesa-vulkan-drivers.install
# 1. teflon パッケージの指示書を空っぽにします
### truncate -s 0 debian/mesa-teflon-delegate.install
# 2. Vulkanパッケージの指示書から、overlay-control の記述を削除します
### sed -i '/mesa-overlay-control.py/d' debian/mesa-vulkan-drivers.install
# HAKO 02
### sed -i '/mesa-screenshot-control.py/d' debian/mesa-vulkan-drivers.install

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


echo "=== 3. debian/rules と指示書の書き換え (Panthor最適化) ==="
# (前略：hakotaniさんが作ってくれた、先ほどの *_drv_video.so の mv コメントアウト行はそのまま残してください！)

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
export DEBEMAIL="user@localhost"
export DEBFULLNAME="Panthor Builder"
# debchange --force-bad-version --newversion "${CURRENT_VERSION}~panthor1" "Custom Panthor-only build without heavy dependencies"
# 修正後の推奨コード (例: 26.0.3-1ubuntu1+panthor1)
debchange --force-bad-version --newversion "${CURRENT_VERSION}+panthor1" "Custom Panthor-only build without heavy dependencies"

echo "=== 5. 依存チェックを無視してビルド実行 ==="
# -d フラグで不要なビルド依存（Intel/AMD用ライブラリなど）のチェックをスキップ
DEB_BUILD_OPTIONS="terse noautodbgsym" debuild -us -uc -b -d

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

	

# ubuntu-imageのフックやchroot内で実行する処理のイメージ
#dpkg -i /tmp/patches/mesa-panthor/*.deb
#apt-get install -f -y  # 実行に必要な最小限の依存（libdrm等）だけを自動解決

