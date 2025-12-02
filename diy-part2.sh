#!/bin/bash
# Description: OpenWrt DIY script part 2

# =========================================================
# 1. 基础变量
# =========================================================
export WRT_IP="192.168.6.1"
export WRT_NAME="MyRouter-0"
export WRT_THEME="argon"

# WiFi 2.4G
export WRT_SSID_2G="My_AP8220_2.4G"
export WRT_WORD_2G="12345678"
# WiFi 5G
export WRT_SSID_5G="My_AP8220_5G"
export WRT_WORD_5G="12345678"

# 高通标识 (保留)
export WRT_TARGET="QUALCOMMAX"

# =========================================================
# 2. 脚本路径
# =========================================================
MY_SCRIPTS="$GITHUB_WORKSPACE/My-warehouse/Scripts"

# =========================================================
# 3. 补充 Golang 环境 (解决报错)
# =========================================================
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# =========================================================
# 4. 执行脚本 (路径逻辑)
# =========================================================

# --- 进入 package 目录 (给 Packages.sh 和 Handles.sh 用) ---
cd package
    if [ -f "$MY_SCRIPTS/Packages.sh" ]; then
        chmod +x "$MY_SCRIPTS/Packages.sh"
        source "$MY_SCRIPTS/Packages.sh"
    else
        echo "Error: Packages.sh missing in $MY_SCRIPTS"
    fi

    if [ -f "$MY_SCRIPTS/Handles.sh" ]; then
        chmod +x "$MY_SCRIPTS/Handles.sh"
        source "$MY_SCRIPTS/Handles.sh"
    else
        echo "Error: Handles.sh missing in $MY_SCRIPTS"
    fi
cd ..

# --- 回到 根目录 (给 Settings.sh 用) ---
if [ -f "$MY_SCRIPTS/Settings.sh" ]; then
    chmod +x "$MY_SCRIPTS/Settings.sh"
    source "$MY_SCRIPTS/Settings.sh"
else
    echo "Error: Settings.sh missing in $MY_SCRIPTS"
fi

echo "DIY-Part2 Done!"
