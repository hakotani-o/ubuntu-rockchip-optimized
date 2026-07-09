# Ubuntu 26.04 LTS，面向 Orange Pi 5 / 5 Plus

Orange Pi 5 / 5 Plus 的 Ubuntu 26.04 LTS (Resolute Raccoon) 磁盘镜像自动构建工具。

基于 Linux 7.1 主线内核 + Mesa 26.0，开箱即用。

## 镜像特点

| 特性 | 说明 |
|------|------|
| **内核** | Linux 7.1.y 主线，近乎原生（defconfig + 最小硬件配置） |
| **CPU Governor** | ondemand（高负载立即拉满，3D/游戏优化） |
| **GPU** | Mesa 26.0 (Panfrost/PanVK) |
| **视频解码** | V4L2 Request API + GStreamer，4K 硬件解码 |
| **显示** | HDMI + DP，GNOME Wayland |
| **WiFi / 蓝牙** | RTL8852BE 已启用 |
| **PWM 风扇** | 设备树内置，30°C 起转自动温控 |
| **构建** | systemd-nspawn 隔离环境，CI 自动 desktop + server matrix 构建 |
| **安装源** | apt + snapd 均可使用 |

## 构建

```bash
# 本地
sudo ./main-control.sh upstream    # Freedesktop Mesa 26.0
sudo ./main-control.sh ubuntu      # Ubuntu 官方 Mesa
```

CI 手动触发后 matrix 并行构建 desktop + server 镜像，自动发布 Release。

## 内核配置

`my-add.txt` 仅添加硬件必需项，其余全由 `defconfig` 决定：

| 类别 | 内容 |
|------|------|
| 平台 | Rockchip RK3588，8 核 |
| GPU | Mali G610 (Panthor) |
| 显示 | Rockchip DRM (HDMI/DP/DSI/LVDS/RGB) |
| 视频 | V4L2 硬解 + DMABUF 零拷贝 (Chromium 优化) |
| 音频 | ES8328 + HDMI Codec |
| 存储 | AHCI/SATA (JMB582) |
| WiFi | RTL8852BE (rtw89) |
| 风扇 | PWM + pwm-fan，绑定 package-thermal |
| LED | 触发器 (timer/disk/heartbeat/cpu) |

## 📊 实测性能

### glmark2-es2-wayland (Mesa 26.0.8, Panfrost)

| 板子 | 得分 |
|------|------|
| Orange Pi 5 | **3241** |
| Orange Pi 5 Plus | **3138** |

### 4K 视频硬件解码 CPU 负载 (uptime)

测试: YouTube 4K HDR，Chromium + enhanced-h264ify

| 板子 | ondemand |
|------|----------|
| Orange Pi 5 | ~2.16 |
| Orange Pi 5 Plus | ~2.70 |

## 验证 GPU

```bash
glxinfo -B | grep -E "Device|Renderer"     # Mali-G610 (Panfrost)
vulkaninfo --summary | grep deviceName      # Mali-G610 MC4
glmark2-es2-wayland                          # 得分 2500+
gst-inspect-1.0 v4l2codecs                  # v4l2slh264dec 等
```

## 温度监控

```bash
for z in /sys/class/thermal/thermal_zone*; do
  echo "$(cat $z/type): $(( $(cat $z/temp) / 1000 ))°C"
done
```

## 开发者

- **Main Lead & Build Architect**: [@hakotani-o](https://github.com/hakotani-o)
- **AI Co-Development**: Google AI / Anthropic Claude
