#!/bin/bash
# Description: OpenWrt DIY script part 2

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
# 3. 真正的终极修复：使用官方卸载命令
# =========================================================
# 解决 hostapd-2025.08.26 报错
# 之前的 rm 可能没清理掉 feed 索引，这次用 uninstall 命令正规卸载
echo "Uninstalling conflicting official WiFi packages..."

# 卸载所有可能冲突的包名
./scripts/feeds uninstall hostapd
./scripts/feeds uninstall wpad
./scripts/feeds uninstall hostapd-openssl
./scripts/feeds uninstall wpad-openssl
./scripts/feeds uninstall wpad-basic
./scripts/feeds uninstall wpad-mini
./scripts/feeds uninstall wpad-wolfssl

# 物理粉碎：防止卸载后还有残留文件夹
echo "Physically removing feed sources..."
rm -rf feeds/packages/net/hostapd
rm -rf feeds/packages/net/wpad
# 双重保险：扫描 package/feeds 下的残留
find package/feeds -type d -name "hostapd*" -exec rm -rf {} +
find package/feeds -type d -name "wpad*" -exec rm -rf {} +

echo "Conflicting drivers fully removed. Using internal source."

# =========================================================
# 4. Golang 官方最新版自动对接 (修复 AdGuardHome)
# =========================================================

# 1. 找到系统自带的 Golang Makefile
# 使用 find 确保路径正确，兼容不同源码结构
GO_MAKEFILE=$(find feeds/packages/lang/ -name "Makefile" | grep "/golang/")

if [ -f "$GO_MAKEFILE" ]; then
    echo "Querying Go Official Latest Version..."
    
    # 1. 从 Go 官网接口获取最新版本 (增加超时防止卡死)
    LATEST_GO=$(curl -sL --connect-timeout 5 https://go.dev/VERSION?m=text | head -n1)
    
    # 2. 保底机制
    if [[ -z "$LATEST_GO" || "$LATEST_GO" != go* ]]; then
        echo "Network Error. Fallback to 1.25.3"
        LATEST_GO="go1.25.3"
    fi
    
    # 3. 提取纯数字 (go1.25.5 -> 1.25.5)
    GO_VERSION="${LATEST_GO#go}"
    
    echo "Detected Target Go Version: $GO_VERSION"
    
    # 4. 修改 Makefile
    sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=$GO_VERSION/" "$GO_MAKEFILE"
    sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/' "$GO_MAKEFILE"
    
    echo "Golang Makefile updated."
else
    echo "Warning: Golang Makefile not found."
fi

# =========================================================
# 5. 执行外部脚本
# =========================================================

# --- 进入 package 目录 ---
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

# --- 回到根目录 ---
if [ -f "$MY_SCRIPTS/Settings.sh" ]; then
    chmod +x "$MY_SCRIPTS/Settings.sh"
    source "$MY_SCRIPTS/Settings.sh"
fi

echo "DIY-Part2 Done!"
