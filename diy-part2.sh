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
# 3. 核弹级清理：WiFi 驱动冲突 (彻底根除 he_mu_edca 报错)
# =========================================================
# 之前的命令没删干净，这次使用通配符强制删除所有 feeds 里的相关包
# 不管它叫 hostapd, hostapd-openssl, wpad, wpad-mini... 统统删掉
# 确保编译器只能看到 package/network/services/ 下的源码自带版本

echo "Executing NUCLEAR cleanup for hostapd/wpad..."
rm -rf package/feeds/*/hostapd*
rm -rf package/feeds/*/wpad*

# 二次检查：防止漏网之鱼 (如果还有残留，find 会再次补刀)
find package/feeds -type d -name "*hostapd*" -exec rm -rf {} +
find package/feeds -type d -name "*wpad*" -exec rm -rf {} +

echo "Conflicting WiFi drivers annihilated."

# =========================================================
# 4. Golang 官方版自动对接 (解决 Go >= 1.25.3)
# =========================================================

# 1. 找到系统自带的 Golang Makefile
GO_MAKEFILE=$(find feeds/packages/lang/ -name "Makefile" | grep "/golang/")

if [ -f "$GO_MAKEFILE" ]; then
    echo "Querying Go Official Latest Version..."
    
    # 1. 从 Go 官网接口获取最新版本 (例如返回 go1.25.4)
    # 增加超时设置防止卡死
    LATEST_GO=$(curl -sL --connect-timeout 5 https://go.dev/VERSION?m=text | head -n1)
    
    # 2. 如果官网抽风没获取到，强制使用 1.25.3 (AdGuardHome 的最低要求)
    if [[ -z "$LATEST_GO" || "$LATEST_GO" != go* ]]; then
        echo "Network Error or Invalid Response. Fallback to 1.25.3"
        LATEST_GO="go1.25.3"
    fi
    
    # 3. 提取纯数字版本号 (go1.25.4 -> 1.25.4)
    GO_VERSION="${LATEST_GO#go}"
    
    echo "Detected Target Go Version: $GO_VERSION"
    
    # 4. 修改 Makefile
    # 修改版本号
    sed -i "s/^PKG_VERSION:=.*/PKG_VERSION:=$GO_VERSION/" "$GO_MAKEFILE"
    # 强制修改 Hash 为 skip (因为我们用的是动态最新版，无法预知 Hash)
    sed -i 's/^PKG_HASH:=.*/PKG_HASH:=skip/' "$GO_MAKEFILE"
    
    echo "Golang Makefile updated. Will download $GO_VERSION from Official Source."
else
    echo "CRITICAL WARNING: Golang Makefile not found! AdGuardHome might fail."
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
