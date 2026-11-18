# Ubuntu 26.04 LTS Mini-Image with Hardware Acceleration for Orange Pi 5 / 5 Plus

Orange Pi 5 および Orange Pi 5 Plus 向けに、極限まで軽量化・最適化された Ubuntu 26.04 LTS (Resolute Raccoon) のハードウェアアクセラレーション対応カスタムディスクイメージ、およびその自動ビルドツールです。

最新のメインライン環境（**Linux Kernel 7.3系 + VP9パッチ** ＆ **Mesa 26.2系**）を採用し、不要なモジュールやコンポーネントを徹底的に排除することで、超軽量かつ圧倒的にスムーズなデスクトップ体験を実現しています。

## 🚀 主な特徴

- **完全メインラインのグラフィックス駆動 (Mesa 26.2 + libdrm 2.4.134)**:
  最新の **Mesa 26.2.4 (Panfrost / Panthor / PanVK)** と **libdrm 2.4.134** により、Mali-G610 GPU のポテンシャルを最大限に引き出し、GNOME (Wayland) デスクトップ環境でシルクのように滑らかな描画を実現。
- **16K ページサイズ（47-bit VA）対応カーネル**:
  標準の 4K ページ版に加え、**`PAGE_SIZE=16K` + 47-bit VA** 構成のカーネルを用意。ページテーブルの階層（3-level）と TLB ミスを大幅に削減し、Chromium での WebGL 描画（高負荷時の FPS 向上）や動画再生時のドロップフレーム抑制、デスクトップ全体の軽快なレスポンスに貢献。
- **VP9パッチ適用済み・即戦力のハードウェア動画デコード**:
  独自ビルドの Linux 7.3 カーネルには **VP9 ハードウェアデコードパッチを標準適用済み**。H.264 / H.265 / AV1 に加え、YouTube 標準の **VP9** コーデックも V4L2 Request API（`v4l2codecs`）経由でフルハードウェアデコードに対応。さらに Chromium 用の V4L2 設定（`/etc/chromium.d/opi5-v4l2`）もプリセット済みのため、低発熱・低CPU負荷での 4K 動画再生をすぐに体験可能。
- **最大パフォーマンス志向（CPU Governor: `performance` 固定）**:
  CPU Governor を **`performance`** に固定設定し、クロック変動による遅延や引っかかりを排除。デスクトップ操作から 3D グラフィックスまで、RK3588 の演算性能を常に 100% 引き出します。
- **極限のミニマリズム (約 1.6 GB)**:
  カーネルを限界までコンパクト化し、圧縮後のイメージサイズをわずか **約 1.6 GB (xz)** に集約。
- **100% Snap-Free**:
  Ubuntu 標準の Snap デーモンおよび Snap アプリを完全に排除。システムのオーバーヘッドを極限まで低減しています。（後から `snapd` を導入して利用することも可能です）
- **クリーンビルド環境**:
  U-Boot・カーネル・Mesa・rootfs をそれぞれ独立したクリーン環境（`systemd-nspawn`）でビルド。ビルド環境の汚染を排除し、再現性の高い最高品質のバイナリを生成。

## 🛠️ カーネルの最適化（カスタマイズ内容）

本イメージは、特化型デスクトップ・サーバーとしての純粋なパフォーマンスを追求するため、以下の機能をカーネルレベルで最適化し、メモリフットプリントとビルドサイズを最小化しています。

- **CPU / スケジューリング最適化**: デフォルト CPU Governor を **`performance`** に固定し、レスポンシブな動作を確保
- **メモリ管理・アーキテクチャ最適化**: `PAGE_SIZE=16K` + `47-bit VA` 対応によるアドレス変換オーバーヘッドの削減（16K版カーネル）
- **ハードウェアアクセラレーション強化**:
  - **VP9 ハードウェアデコードパッチ適用**（V4L2 stateless VP9 デコード対応）
  - `CONFIG_DMABUF_HEAPS`・`CONFIG_ROCKCHIP_IOMMU` を有効化し、GPU↔VPU 間のゼロコピーバッファ転送を実現
- **AHCI/SATA対応**: M.2スロット経由の PCIe→SATA 変換（JMB582等）に対応
- **無効化された不要コンポーネント**:
  - ネットワーク関連: Wi-Fi, Bluetooth, IPv6, Netfilter (ファイアウォール), VLAN, DVB_NET, CAN バス
  - ファイルシステム: NFS (Network File System)
  - 入力デバイス: ジョイスティック、タブレット、タッチスクリーン
  - その他サブシステム: `CONFIG_FTRACE` (デバッグトレース), `CONFIG_SND_HDA` (不要なオーディオドライバ), `kdump-tools`, その他不要な PHY ドライバ群

## 📊 パフォーマンス実測値

### glmark2-es2-wayland スコア

GNOME (Wayland) セッション、CPU Governor `performance` 設定時の実測値です（※4Kページ版・16Kページ版ともに **3400 超え** の高スコアを記録）。

| ボード | Governor | スコア |
|---|---|---|
| Orange Pi 5 | performance | **3600+** |
| Orange Pi 5 Plus | performance | **3600+** |

### 4K動画ハードウェアデコード時の CPU 負荷 (uptime)

テスト素材: YouTube 4K HDR「3 Hours of Rainy Night Walk in Tokyo」  
Chromium ハードウェアデコード使用時の目安。

| ボード | 状態 | uptime 目安 |
|---|---|---|
| Orange Pi 5 / 5 Plus | 動画再生（安定後） | **〜1.0〜2.5 前後** |

*CPUソフトウェアデコード時は uptime 10以上。ハードウェアデコードの効果は絶大です。*  
*uptime の値は動画コンテンツの動きの激しさ（画面変化量）によって変動します。動きが少ない映像ほど低い値になります。*

## 📦 ハードウェアアクセラレーションの体感・テスト方法

### 1. 3Dグラフィックス (GPU) のテスト
Mesa Panfrost/Panthor/PanVK が正常にグラフィックスを処理しているか確認します。

```bash
# OpenGL ES のテスト
sudo apt install glmark2-es2-wayland
glmark2-es2-wayland

# Vulkan のテスト
sudo apt install vulkan-tools
vkcube
```

### 2. ビデオデコード (VPU) の確認
カーネルの V4L2 コーデックエンジンが、最新の GStreamer 経由で H.264 / H.265 / VP9 / AV1 を認識しているか確認します。

```bash
gst-inspect-1.0 v4l2codecs
```
*`v4l2slh264dec`、`v4l2slh265dec`、`v4l2slvp9dec`、`v4l2slav1dec` 等が表示されれば正常です。動画再生には GStreamer を直接叩く「Clapper」などのモダンなプレイヤーの利用を推奨します。*

### 3. 🔥 Special Feature: Pure APT Native Browsing (Snap-free)
このディスクイメージは、Orange Pi 5 / 5 Plus のハードウェアパワーを極限まで引き出すため、**完全にSnapを排除したクリーンな設計**を採用しています。

初期状態でのディスク容量（イメージサイズ）を最小限に抑えつつ、ユーザーがいつでも「APT版」の Firefox, Thunderbird および Chromium を導入できるよう、**Mozilla Team PPA と xtradeb packaging team PPA の事前マッピング（APT Pinning）** をあらかじめシステムに組み込んであります。

さらに、**カーネル側の VP9 パッチ適用** と **Chromium 用の V4L2 ハードウェアデコード設定（`/etc/chromium.d/opi5-v4l2`）の標準組み込み** により、ブラウザをインストールするだけで面倒な設定なしにすぐ **YouTube の 4K ハードウェアデコード（VP9 / AV1 / H.264）** を体験できます。（必要に応じて拡張機能 **enhanced-h264ify** を併用することで、再生コーデックを自由に指定することも可能です）

### 🚀 How to Install Native Firefox & Thunderbird & Chromium

イメージ起動後、ターミナルで以下のコマンドを実行するだけで、PPAからネイティブパッケージ（APT版）が直接インストールされます。

```bash
sudo apt update
sudo apt install firefox-esr thunderbird-gnome-support chromium
```

- **No Snap Overhead**: 起動が遅い、メモリを無駄に消費する Snap デーモンは一切動きません。
- **Out-of-the-Box 4K V4L2 Acceleration**: VP9 パッチ済みカーネルと `/etc/chromium.d/opi5-v4l2` の組み合わせにより、YouTube 標準の VP9 動画もそのままハードウェアデコードされます。

## 📝 開発者ノート

- **16K ページサイズカーネルの効果**: `glmark2` のような純粋な GPU ベンチマークでは 4K ページ版と大きな数値差は出ませんが、Chromium の WebGL ベンチマーク（Aquarium 5,000匹表示など）や YouTube 動画再生時のドロップフレーム抑制、普段のデスクトップ操作において、CPU に余裕が生まれたような軽快さを体感できます。
- **Mesa 26.2 へのアップデート**: バージョンアップによる描画品質や安定性の向上はベンチマーク数値以上に実際の使用感に現れます。
- **glmark2 スコアの測定について**: スコアは測定時のシステム負荷（バックグラウンド処理等）によって変動するため、アイドル状態での測定が最もフェアな比較になります。

## 🛠️ 開発者について (Authors)

本プロジェクトは、人間のエンジニアの構想力とAIの技術的サポートが融合した「AI共同開発（AI Co-Development）」によって誕生しました。

- **Main Lead & Build Architect**: hakotani
  - **GitHub**: [@hakotani-o](https://github.com)
  - *コンセプト設計、高度なカーネルカスタマイズ（16Kページ化・VP9パッチ適用・最適化）、Mesa / libdrm 隔離ビルド、クリーンビルド環境の構築、およびGitHub自動化パイプラインの構築を担当。*

- **AI Co-Pilot & Technical Advisor**: Google AI / Anthropic Claude
  - *Google AI: カーネルオプション（16Kページサイズ＋47-bit VA等）の最適化提案、Mesaビルドフラグの検証、V4L2/Chromium/GStreamer周りのトラブルシューティング、ドキュメント作成をサポート。*
  - *Anthropic Claude: カーネルコンフィグの精査・最適化（Rockchip/RK3588特化）、DMABUF_HEAPS・AHCI/SATA対応の追加、クリーンビルド環境（systemd-nspawn）の設計、CPU Governor の実測比較・選定、kdump-tools排除（APT Pin方式）、パフォーマンスデータの分析をサポート。*

---
*本プロジェクトは、GitHub Actions を用いてソースからのカーネルビルド、Mesaの隔離コンパイル（debパッケージ作成）、およびリリースへのアップロードを完全に自動化しています。*

