#!/bin/bash
# ==============================================================
# diy-part1.sh: 添加额外的软件源 (Feed)
# ==============================================================

# 1. 移除可能导致冲突的默认源 (可选，为了保险)
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# 2. 添加 OpenClash 源 (科学上网神器)
echo "src-git openclash https://github.com/vernesong/OpenClash.git" >> feeds.conf.default

# 3. 添加 Passwall 完整源 (包含核心组件)
echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> feeds.conf.default
echo "src-git passwall_luci https://github.com/xiaorouji/openwrt-passwall.git;main" >> feeds.conf.default

# 4. 添加 LinkEase 源 (为了编译 ddnsto, quickstart 等)
echo "src-git nas_packages https://github.com/linkease/nas-packages.git;master" >> feeds.conf.default
echo "src-git nas_luci https://github.com/linkease/nas-packages-luci.git;main" >> feeds.conf.default

# 5. 添加 SBWML 源 (高质量插件库: MosDNS, Argon, 常用工具)
# 它的适配性极好，非常推荐 FW4 系统使用
echo "src-git sbwml https://github.com/sbwml/openwrt-3rdparty.git" >> feeds.conf.default

# 6. 添加 Sirpdboy 源 (主题和常用设置工具)
# KuCat 主题就在这里，加了这个源后，menuconfig 里会有更多好玩的
echo "src-git sirpdboy https://github.com/sirpdboy/sirpdboy-package" >> feeds.conf.default

# --------------------------------------------------------------
# ⚠️ 警告：不要添加 kenzok8 (kenzo/small) 源！
# 虽然它的插件很多，但它会强制修改系统底层依赖，极大概率导致 OpenWrt 25/FW4 编译报错。
# 上面这些源已经足够覆盖 99% 的需求了。
# --------------------------------------------------------------
