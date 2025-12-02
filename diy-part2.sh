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
# 3. 关键修复：清理冲突的 WiFi 驱动
# =========================================================
# 必须删除 feeds 里的 hostapd/wpad，强制使用源码自带版本
rm -rf package/feeds/packages/net/hostapd
rm -rf package/feeds/packages/net/wpad
rm -rf package/feeds/network/services/hostapd
rm -rf package/feeds/network/services/wpad

# =========================================================
# 4. 关键修复：原生修改 Golang 为官方最新版
# =========================================================

# 直接定位系统自带的 Makefile (不再下载第三方的)
GO_MAKEFILE="feeds/packages/lang/golang/Makefile"

if [ -f "$GO_MAKEFILE" ]; then
    echo "Querying official latest Go version..."
    
    # 从 Go 官网获取最新版本号 (如 go1.25.4)
    LATEST_GO=$(curl -sL https://go.dev/VERSION?m=text | head -n1)
    
    # 如果获取失败，给个保底 1.25.3 (AdGuardHome 要求的最低版本)
    if [ -z "$LATEST_GO" ]; then
        LATEST_GO="go1.25.3"
    fi
    
    # 去掉前缀 (go1.25.4 -> 1.25.4)
    GO_VERSION="${LATEST_GO#go}"
    
    echo "Updating System Golang to Official $GO_VERSION..."
    
    # 1. 修改版本号
    sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=$GO_VERSION/" "$GO_MAKEFILE"
    
    # 2. 强制跳过 Hash 校验 (因为是动态版本)
    sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/' "$GO_MAKEFILE"
    
    echo "Done. Compiler will download $GO_VERSION from Official Source."
else
    echo "Warning: System Golang Makefile not found at $GO_MAKEFILE"
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
