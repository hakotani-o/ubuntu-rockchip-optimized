# Ubuntu 26.04 LTS Mini-Image with Hardware Acceleration for Orange Pi 5 / 5 Plus

Orange Pi 5 および Orange Pi 5 Plus 向けに、極限まで軽量化・最適化された Ubuntu 26.04 LTS (Resolute Raccoon) のハードウェアアクセラレーション対応カスタムディスクイメージ、およびその自動ビルドツールです。

最新のメインライン環境（Linux Kernel 7.1系 ＆ Mesa 26.0系）を採用し、不要なモジュールやコンポーネントを徹底的に排除することで、超軽量かつ圧倒的にスムーズなデスクトップ体験を実現しています。

## 🚀 主な特徴

- **完全メインラインのグラフィックス駆動**:
  Mesa 26.0 (Panfrost/PanVK) により、Mali-G610 GPU のポテンシャルを100%引き出し、GNOME (Wayland) デスクトップ環境でシルクのように滑らかな描画を実現。
- **効率的なハードウェア動画デコード**:
  Linux 7.1 カーネルの V4L2 Request API と GStreamer 1.28+ (v4l2codecs) が直接連携。低発熱・低CPU負荷での4K動画再生をサポート。
- **極限のミニマリズム (1.6 GB)**:
  カーネルを限界までコンパクト化し、圧縮後のイメージサイズをわずか **1.6 GB (xz)** に集約。
- **100% Snap-Free**:
  Ubuntu 標準の Snap デーモンおよび Snap アプリを完全に排除。システムのオーバーヘッドを極限まで低減しています。（後からsnapdを入れても動作OK）
- **Panthor向け最適化ビルド**:
  軽量化のためMesaの再構築とUbuntu標準版、Freedesktop Mesa 26.0版の２種類を採用。
- **デュアルカーネル構成**:
  `7.1.2-ondemand`（高パフォーマンス）と `7.1.2-conservative`（省電力・低発熱）の2つのカーネルを1つのイメージに収録。起動時に用途に合わせて選択可能。
- **クリーンビルド環境**:
  U-Boot・カーネル・Mesa・rootfs をそれぞれ独立したクリーン環境（systemd-nspawn）でビルド。ビルド環境の汚染を排除し、再現性の高い最高品質のバイナリを生成。

## 🛠️ カーネルの最適化（無効化されたコンポーネント）

本イメージは、サーバー/特化型デスクトップとしての純粋なパフォーマンスを追求するため、以下の不要な機能をカーネルレベルで無効化し、メモリフットプリントとビルドサイズを最小化しています。

- **ネットワーク関連**: Wi-Fi, Bluetooth, IPv6, Netfilter (ファイアウォール), VLAN, DVB_NET, CAN バス
- **ファイルシステム**: NFS (Network File System)
- **入力デバイス**: ジョイスティック、タブレット、タッチスクリーン
- **不要なサブシステム**: `CONFIG_FTRACE` (デバッグトレース), `CONFIG_SND_HDA` (不要なオーディオドライバ), kdump-tools, その他不要なPHYドライバ群
- **ハードウェアアクセラレーション強化**: `CONFIG_DMABUF_HEAPS`・`CONFIG_ROCKCHIP_IOMMU` を有効化し、GPU↔VPU 間のゼロコピーバッファ転送を実現。Chromium のハードウェアデコードを最適化。
- **AHCI/SATA対応**: M.2スロット経由の PCIe→SATA 変換（JMB582等）に対応。

## ⚡ CPU Governor について

本イメージには用途に合わせて2種類のカーネルを収録しています。

| Governor | 特性 | 推奨用途 |
|---|---|---|
| **ondemand** | 高負荷時に最大クロックへ即応 | 3Dグラフィックス・ゲーム |
| **conservative** | 必要な分だけクロックを上げる | 動画再生・省電力・夏場の発熱対策 |

U-Boot からの起動のため、`/boot/extlinux/extlinux.conf` の `default` を `l0` または `l1` に設定変更後リブートしてください。

## 📊 パフォーマンス実測値

### glmark2-es2-wayland スコア

GNOME (Wayland) セッション、Mesa 26.0.8 (Panfrost) 使用時の実測値です。

| ボード | Governor | スコア |
|---|---|---|
| Orange Pi 5 | ondemand | **3241** |
| Orange Pi 5 | conservative | 2740 |
| Orange Pi 5 Plus | ondemand | **3138** |
| Orange Pi 5 Plus | conservative | 2654 |

### 4K動画ハードウェアデコード時の CPU 負荷 (uptime)

テスト素材: YouTube 4K HDR「3 Hours of Rainy Night Walk in Tokyo」
Chromium + enhanced-h264ify 使用時の実測値。

| ボード | Governor | 開始時 | 安定後 |
|---|---|---|---|
| Orange Pi 5 | ondemand | 〜2.77 | 〜2.16 |
| Orange Pi 5 | conservative | 〜1.96 | **〜0.85** |
| Orange Pi 5 Plus | ondemand | 〜3.00 | 〜2.70 |
| Orange Pi 5 Plus | conservative | 〜1.17 | **〜0.82** |

*CPUソフトウェアデコード時は uptime 10以上。ハードウェアデコードの効果は絶大です。*

*uptime の値は動画コンテンツの動きの激しさ（画面変化量）によって変動します。動きが少ない映像ほど低い値になります。*

## 📦 ハードウェアアクセラレーションの体感・テスト方法

### 1. 3Dグラフィックス (GPU) のテスト
Mesa Panfrost/PanVK が正常にグラフィックスを処理しているか確認します。

```bash
# OpenGL ES のテスト
sudo apt install glmark2-es2-wayland
glmark2-es2-wayland

# Vulkan のテスト
sudo apt install vulkan-tools
vkcube
```

### 2. ビデオデコード (VPU) の確認
カーネルの V4L2 コーデックエンジンが、最新の GStreamer 経由で H.264/H.265/AV1 を認識しているか確認します。

```bash
gst-inspect-1.0 v4l2codecs
```
*`v4l2slh264dec`、`v4l2slh265dec`、`v4l2slav1dec` 等が表示されれば正常です。動画再生には GStreamer を直接叩く「Clapper」などのモダンなプレイヤーの利用を推奨します。*

### 3. 🔥 Special Feature: Pure APT Native Browsing (Snap-free)
このディスクイメージは、Orange Pi 5 / 5 Plus のハードウェアパワーを極限まで引き出すため、**完全にSnapを排除したクリーンな設計**を採用しています。

初期状態でのディスク容量（イメージサイズ）を最小限に抑えつつ、ユーザーがいつでも「APT版」の Firefox, Thunderbird および Chromium を導入できるよう、**Mozilla Team PPA と xtradeb packaging team PPA の事前マッピング（APT Pinning）** をあらかじめシステムに組み込んであります。
「Chrome ウェブストア - 拡張機能」から **enhanced-h264ify** を組み込むことで簡単に **ハードウェアデコード** が体験できます。

これにより、Ubuntu公式の「Snap強制ダミーパッケージ」に邪魔されることなく、超軽量・高速なブラウジング環境をワンコマンドで手に入れることができます。

### 🚀 How to Install Native Firefox & Thunderbird & Chromium

イメージ起動後、ターミナルで以下のコマンドを実行するだけで、PPAからパッケージ（APT版）が直接インストールされます。

```bash
sudo apt update
sudo apt install firefox-esr thunderbird-gnome-support chromium
```

- **No Snap Overhead**: 起動が遅い、メモリを無駄に消費するSnapデーモンは一切動きません。
- **Hardware Accelerator Friendly**: SBCのリソースを最大限に活かした、軽快なパフォーマンスを体感してください。

## 📝 開発者ノート

- Mesa のバージョンアップによる描画品質の向上はベンチマーク数値には現れにくいですが、実際の使用感では鮮明感の向上として体感できます。半年前のビルドと比較すると違いがわかります。
- 夏場の発熱対策として `conservative` カーネルの使用を推奨します。CPU に優しく、4K動画再生においても体感差はほとんどありません。
- glmark2 スコアは測定時のシステム負荷（バックグラウンドのビルド作業等）によって大きく変動します。アイドル状態での測定値が最もフェアな比較になります。

## 🛠️ 開発者について (Authors)

本プロジェクトは、人間のエンジニアの構想力とAIの技術的サポートが融合した「AI共同開発（AI Co-Development）」によって誕生しました。

- **Main Lead & Build Architect**: hakotani
  - **GitHub**: [@hakotani-o](https://github.com/hakotani-o)
  - *コンセプト設計、高度なカーネルカスタマイズ、Mesa隔離ビルド、クリーンビルド環境の構築、およびGitHub自動化パイプラインの構築を担当。*

- **AI Co-Pilot & Technical Advisor**: Google AI / Anthropic Claude
  - *Google AI: カーネルオプションの最適化提案、Mesaビルドフラグの検証、最新Linux 7.0/Mesa 25.3環境におけるV4L2/GStreamer周りのトラブルシューティングをサポート。*
  - *Anthropic Claude: カーネルコンフィグの精査・最適化（Rockchip/RK3588特化）、DMABUF_HEAPS・AHCI/SATA対応の追加、クリーンビルド環境（systemd-nspawn）の設計、CPU Governor の実測比較・選定、kdump-tools排除（APT Pin方式）、パフォーマンスデータの分析をサポート。*

---
*本プロジェクトは、GitHub Actions を用いてソースからのカーネルビルド、Mesaの隔離コンパイル（debパッケージ作成）、およびリリースへのアップロードを完全に自動化しています。*
