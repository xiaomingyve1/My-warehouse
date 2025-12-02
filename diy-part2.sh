#!/bin/bash
# Description: OpenWrt DIY script part 2 (After Update feeds)

# =========================================================
# 1. 基础设置 (你的自定义变量)
# =========================================================
WRT_IP="192.168.6.1"       # 主机IP
WRT_NAME="MyRouter-0"      # 主机名
WRT_THEME="argon"          # 默认主题
WRT_SSID="My_AP8220"       # WiFi 名称
WRT_WORD="12345678"        # WiFi 密码

# =========================================================
# 2. 核心修复逻辑 (移植自 Handles.sh)
#    (必须执行这些，否则 NSS 驱动和部分软件会编译失败)
# =========================================================

# 修改 qca-nss-drv 启动顺序
NSS_DRV=$(find feeds/nss_packages/ -name "qca-nss-drv.init")
[ -f "$NSS_DRV" ] && sed -i 's/START=.*/START=85/g' $NSS_DRV

# 修改 qca-nss-pbuf 启动顺序
NSS_PBUF="./package/kernel/mac80211/files/qca-nss-pbuf.init"
[ -f "$NSS_PBUF" ] && sed -i 's/START=.*/START=86/g' $NSS_PBUF

# 修复 TailScale 配置文件冲突
TS_FILE=$(find feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
[ -f "$TS_FILE" ] && sed -i '/\/files/d' $TS_FILE

# 修复 Rust 编译失败
RUST_FILE=$(find feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
[ -f "$RUST_FILE" ] && sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

# 修复 DiskMan 编译失败
DM_FILE="./package/diskman/applications/luci-app-diskman/Makefile"
if [ -f "$DM_FILE" ]; then
    sed -i 's/fs-ntfs/fs-ntfs3/g' $DM_FILE
    sed -i '/ntfs-3g-utils /d' $DM_FILE
fi

# =========================================================
# 3. 下载指定插件 (源码 + 界面)
# =========================================================

# 更新 Golang (MosDNS 必须)
rm -rf feeds/packages/lang/golang
git clone https://github.com/kenzok8/golang feeds/packages/lang/golang

# (1) KuCat 主题
git clone https://github.com/sirpdboy/luci-theme-kucat.git package/themes/luci-theme-kucat

# (2) MosDNS (sbwml v5 版本)
git clone https://github.com/sbwml/luci-app-mosdns.git package/mosdns

# (3) AdGuard Home (rufengsuixing 界面)
git clone https://github.com/rufengsuixing/luci-app-adguardhome.git package/luci-app-adguardhome

# =========================================================
# 4. 应用系统设置 (移植自 Settings.sh)
#    (让上面的 WRT_IP 等变量真正生效)
# =========================================================

# 修改默认 IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" package/base-files/files/bin/config_generate

# 修改主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" package/base-files/files/bin/config_generate

# 修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" feeds/luci/collections/luci/Makefile

# 修改 WiFi 名称和密码 (自动适配高通/联发科路径)
WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"

if [ -f "$WIFI_SH" ]; then
    # 脚本方式 (Settings.sh 原逻辑)
    sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
    sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
    # UC 配置文件方式
    sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
    sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
    sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
    sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

# 移除自带的 attendedsysupgrade (避免弹窗干扰)
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")

echo "DIY-Part2 All-in-One execution completed!"