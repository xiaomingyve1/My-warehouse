#!/bin/bash
# Description: OpenWrt DIY script part 2 (After Update feeds)

# =========================================================
# 1. 基础变量
# =========================================================
export WRT_IP="192.168.6.1"
export WRT_NAME="MyRouter-0"
export WRT_THEME="argon"
export WRT_SSID_2G="My_AP8220_2.4G"
export WRT_WORD_2G="12345678"
export WRT_SSID_5G="My_AP8220_5G"
export WRT_WORD_5G="12345678"
export WRT_TARGET="QUALCOMMAX"

# =========================================================
# 2. 脚本路径
# =========================================================
MY_SCRIPTS="$GITHUB_WORKSPACE/My-warehouse/Scripts"

# =========================================================
# 3. 关键修复：清理官方 WiFi 驱动 (解决 hostapd 报错)
# =========================================================
# 这一步至关重要！IPQ807x 必须使用源码自带的 hostapd，不能用 feeds 里的。
# 删除 feeds 里的 hostapd 和 wpad，强制回滚到源码版本。
echo "Removing conflicting hostapd/wpad from feeds..."
rm -rf feeds/packages/net/hostapd
rm -rf feeds/packages/net/wpad
rm -rf feeds/network/services/hostapd
rm -rf feeds/network/services/wpad

# =========================================================
# 4. 关键修复：升级 Golang (解决 AdGuardHome 报错)
# =========================================================
# AdGuardHome 现在要求 Go >= 1.25.3。
# 我们必须清理旧的 golang，并拉取 sbwml 的最新代码。
echo "Updating Golang environment..."
rm -rf feeds/packages/lang/golang
# 使用 sbwml 的库，通常更新最快
git clone https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# =========================================================
# 5. 执行外部脚本
# =========================================================

# --- 进入 package 目录执行下载 ---
cd package
    if [ -f "$MY_SCRIPTS/Packages.sh" ]; then
        chmod +x "$MY_SCRIPTS/Packages.sh"
        source "$MY_SCRIPTS/Packages.sh"
    fi

    if [ -f "$MY_SCRIPTS/Handles.sh" ]; then
        chmod +x "$MY_SCRIPTS/Handles.sh"
        source "$MY_SCRIPTS/Handles.sh"
    fi
cd ..

# --- 回到根目录执行设置 ---
if [ -f "$MY_SCRIPTS/Settings.sh" ]; then
    chmod +x "$MY_SCRIPTS/Settings.sh"
    source "$MY_SCRIPTS/Settings.sh"
fi

echo "DIY-Part2 Done!"
