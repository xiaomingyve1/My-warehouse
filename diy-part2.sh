#!/bin/bash
# Description: OpenWrt DIY script part 2 (After Update feeds)

# =========================================================
# 1. 基础变量定义 (会传递给 Settings.sh)
# =========================================================
export WRT_IP="192.168.6.1"
export WRT_NAME="MyRouter-0"
export WRT_THEME="argon"

# WiFi 参数
export WRT_SSID_2G="My_AP8220_2.4G"
export WRT_WORD_2G="12345678"
export WRT_SSID_5G="My_AP8220_5G"
export WRT_WORD_5G="12345678"

# 系统标识 (触发 Settings.sh 中的高通 NSS 优化)
export WRT_TARGET="QUALCOMMAX"

# =========================================================
# 2. 定义脚本仓库路径 (根据你的实际结构)
# =========================================================
MY_SCRIPTS="$GITHUB_WORKSPACE/My-warehouse/Scripts"

# =========================================================
# 3. 修复 Golang 环境 (解决 AdGuardHome 编译报错)
# =========================================================
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# =========================================================
# 4. 执行外部脚本 (严格的路径逻辑)
# =========================================================

# --- 阶段一：进入 package 目录 ---
# Handles.sh 里的路径是 "../feeds"，所以必须在这里跑
# Packages.sh 下载源码也必须在这里
cd package
    echo "Current Dir: $(pwd)"

    # 1. 下载插件
    if [ -f "$MY_SCRIPTS/Packages.sh" ]; then
        chmod +x "$MY_SCRIPTS/Packages.sh"
        source "$MY_SCRIPTS/Packages.sh"
    else
        echo "Error: Packages.sh not found!"
    fi

    # 2. 执行修复 (Argon/NSS/Rust修复等)
    if [ -f "$MY_SCRIPTS/Handles.sh" ]; then
        chmod +x "$MY_SCRIPTS/Handles.sh"
        source "$MY_SCRIPTS/Handles.sh"
    else
        echo "Error: Handles.sh not found!"
    fi
cd ..

# --- 阶段二：退回 根目录 ---
# Settings.sh 里的路径是 "./feeds"，必须在根目录跑
echo "Current Dir: $(pwd)"

# 3. 应用系统设置 (IP/WiFi/NSS)
if [ -f "$MY_SCRIPTS/Settings.sh" ]; then
    chmod +x "$MY_SCRIPTS/Settings.sh"
    source "$MY_SCRIPTS/Settings.sh"
else
    echo "Error: Settings.sh not found!"
fi

echo "DIY-Part2 Done!"
