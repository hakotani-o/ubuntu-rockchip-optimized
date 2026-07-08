# Ubuntu 26.04 LTS 迷你镜像，带硬件加速，面向 Orange Pi 5 / 5 Plus

针对 Orange Pi 5 及 Orange Pi 5 Plus，极度轻量化、优化的 Ubuntu 26.04 LTS (Resolute Raccoon) 硬件加速定制磁盘镜像及其自动构建工具。

采用最新主线环境（Linux Kernel 7.1 系列 & Mesa 26.0 系列），彻底排除不需要的模块和组件，实现超轻量且极为流畅的桌面体验。

## 🚀 主要特性

- **完全主线的图形驱动**:
  Mesa 26.0 (Panfrost/PanVK) 100% 发挥 Mali-G610 GPU 的潜力，在 GNOME (Wayland) 桌面环境下实现丝滑般流畅的渲染。
- **高效的硬件视频解码**:
  Linux 7.1 内核的 V4L2 Request API 与 GStreamer 1.28+ (v4l2codecs) 直接联动。支持低发热、低CPU负载下的4K视频播放。
- **极致的极简主义 (1.6 GB)**:
  将内核压缩到极限，压缩后镜像大小仅 **1.6 GB (xz)**。
- **100% Snap-Free**:
  完全排除 Ubuntu 标准的 Snap 守护进程及 Snap 应用。将系统开销降至极致。（之后安装 snapd 也可正常运行）
- **Panthor 优化构建**:
  为轻量化，采用 Mesa 重构版本及 Ubuntu 标准版、Freedesktop Mesa 26.0 版两种类型。
- **双内核配置**:
  一个镜像收录 `7.1.2-ondemand`（高性能）和 `7.1.2-conservative`（省电、低发热）两种内核。启动时可根据用途选择。
- **洁净构建环境**:
  U-Boot、内核、Mesa、rootfs 分别在独立的洁净环境（systemd-nspawn）中构建。排除构建环境污染，生成高再现性的最高品质二进制文件。

## 🛠️ 内核优化（已禁用的组件）

本镜像为追求作为服务器/专用桌面的纯粹性能，在内核级别禁用以下不需要的功能，最小化内存占用和构建体积。

- **网络相关**: Wi-Fi, Bluetooth, IPv6, Netfilter (防火墙), VLAN, DVB_NET, CAN 总线
- **文件系统**: NFS (Network File System)
- **输入设备**: 手柄、数位板、触摸屏
- **不需要的子系统**: `CONFIG_FTRACE` (调试追踪), `CONFIG_SND_HDA` (不需要的音频驱动), kdump-tools, 其他不需要的PHY驱动群
- **硬件加速增强**: 启用 `CONFIG_DMABUF_HEAPS`·`CONFIG_ROCKCHIP_IOMMU`，实现 GPU↔VPU 之间的零拷贝缓冲传输。优化 Chromium 硬件解码。
- **AHCI/SATA支持**: 支持M.2插槽通过 PCIe→SATA 转换（JMB582等）。

## ⚡ 关于 CPU Governor

本镜像根据用途收录2种内核。

| Governor | 特性 | 推荐用途 |
|---|---|---|
| **ondemand** | 高负载时立即响应最大频率 | 3D图形·游戏 |
| **conservative** | 仅提升所需的频率 | 视频播放·省电·夏季防过热 |

为从 U-Boot 启动，请将 `/boot/extlinux/extlinux.conf` 的 `default` 更改为 `l0` 或 `l1` 后重启。

## 📊 实测性能数据

### glmark2-es2-wayland 得分

GNOME (Wayland) 会话，使用 Mesa 26.0.8 (Panfrost) 时的实测值。

| 板子 | Governor | 得分 |
|---|---|---|
| Orange Pi 5 | ondemand | **3241** |
| Orange Pi 5 | conservative | 2740 |
| Orange Pi 5 Plus | ondemand | **3138** |
| Orange Pi 5 Plus | conservative | 2654 |

### 4K视频硬件解码时的 CPU 负载 (uptime)

测试素材: YouTube 4K HDR「3 Hours of Rainy Night Walk in Tokyo」
使用 Chromium + enhanced-h264ify 时的实测值。

| 板子 | Governor | 开始时 | 稳定后 |
|---|---|---|---|
| Orange Pi 5 | ondemand | 〜2.77 | 〜2.16 |
| Orange Pi 5 | conservative | 〜1.96 | **〜0.85** |
| Orange Pi 5 Plus | ondemand | 〜3.00 | 〜2.70 |
| Orange Pi 5 Plus | conservative | 〜1.17 | **〜0.82** |

*CPU软件解码时 uptime 超过10。硬件解码效果极为显著。*

*uptime 的值会根据视频内容的运动剧烈程度（画面变化量）而变动。动作越少的影像值越低。*

## 📦 硬件加速体验·测试方法

### 1. 3D图形 (GPU) 测试
确认 Mesa Panfrost/PanVK 是否正常处理图形。

```bash
# OpenGL ES 测试
sudo apt install glmark2-es2-wayland
glmark2-es2-wayland

# Vulkan 测试
sudo apt install vulkan-tools
vkcube
```

### 2. 视频解码 (VPU) 确认
确认内核的 V4L2 编解码引擎是否通过最新的 GStreamer 识别 H.264/H.265/AV1。

```bash
gst-inspect-1.0 v4l2codecs
```
*如果显示 `v4l2slh264dec`、`v4l2slh265dec`、`v4l2slav1dec` 等即为正常。视频播放推荐使用直接调用 GStreamer 的「Clapper」等现代播放器。*

### 3. 🔥 Special Feature: Pure APT Native Browsing (Snap-free)
此磁盘镜像为最大限度发挥 Orange Pi 5 / 5 Plus 的硬件性能，采用**完全排除 Snap 的清洁设计**。

在将初始状态的磁盘容量（镜像大小）压缩至最小的同时，预先在系统中内置了 **Mozilla Team PPA 和 xtradeb packaging team PPA 的预映射（APT Pinning）**，使用户随时可安装「APT版」Firefox、Thunderbird 和 Chromium。
通过「Chrome 网上应用店 - 扩展程序」安装 **enhanced-h264ify**，即可轻松体验**硬件解码**。

由此，不会被 Ubuntu 官方的「Snap强制虚拟包」干扰，一条命令即可获得超轻量、高速的浏览环境。

### 🚀 How to Install Native Firefox & Thunderbird & Chromium

镜像启动后，在终端中执行以下命令，即可从PPA直接安装软件包（APT版）。

```bash
sudo apt update
sudo apt install firefox-esr thunderbird-gnome-support chromium
```

- **No Snap Overhead**: 启动慢、浪费内存的Snap守护进程完全不运行。
- **Hardware Accelerator Friendly**: 请体验最大限度活用SBC资源的轻快性能。

## 📝 开发者笔记

- Mesa 版本升级带来的渲染质量提升虽然不易在性能跑分数值中体现，但在实际使用感受中可体会到清晰度的提高。与半年前的构建相比，差异更加明显。
- 作为夏季防过热措施，推荐使用 `conservative` 内核。对CPU更友好，4K视频播放的体感差异也几乎不存在。
- glmark2 得分会因测量时的系统负载（后台构建作业等）而大幅变动。空闲状态下的测量值才是公平的比较。

## 🛠️ 关于开发者 (Authors)

本项目诞生于人类工程师的构想力与AI技术支持融合的「AI共同开发（AI Co-Development）」。

- **Main Lead & Build Architect**: hakotani
  - **GitHub**: [@hakotani-o](https://github.com/hakotani-o)
  - *负责概念设计、高级内核定制、Mesa隔离构建、洁净构建环境的搭建，以及GitHub自动化流水线的构建。*

- **AI Co-Pilot & Technical Advisor**: Google AI / Anthropic Claude
  - *Google AI: 协助内核选项优化提案、Mesa构建标志验证、最新Linux 7.0/Mesa 25.3环境下V4L2/GStreamer相关问题的排查。*
  - *Anthropic Claude: 协助内核配置的审查·优化（Rockchip/RK3588专用）、DMABUF_HEAPS·AHCI/SATA支持的添加、洁净构建环境（systemd-nspawn）的设计、CPU Governor实测比较·选型、kdump-tools排除（APT Pin方式）、性能数据分析。*

---
*本项目使用 GitHub Actions，完全自动完成从源码编译内核、Mesa隔离编译（创建deb包），到发布上传的全部流程。*
