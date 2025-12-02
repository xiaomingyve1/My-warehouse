#!/bin/bash
# Description: OpenWrt DIY script part 2 (After Update feeds)

# =========================================================
# 1. 基础变量定义
# =========================================================
export WRT_IP="192.168.6.1"
export WRT_NAME="MyRouter-0"
export WRT_THEME="argon"

# WiFi 设置
export WRT_SSID_2G="My_AP8220_2.4G"
export WRT_WORD_2G="12345678"
export WRT_SSID_5G="My_AP8220_5G"
export WRT_WORD_5G="12345678"

# 系统标识 (NSS加速必须)
export WRT_TARGET="QUALCOMMAX"

# =========================================================
# 2. 定义脚本存放的真实路径 (你的新目录)
# =========================================================
# 脚本都在这里：My-warehouse/Scripts/
MY_SCRIPTS="$GITHUB_WORKSPACE/My-warehouse/Scripts"

# =========================================================
# 3. 补充 Golang 环境 (解决 AdGuardHome 报错)
# =========================================================
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# =========================================================
# 4. 执行脚本 (严格对应你的目录结构)
# =========================================================

# [阶段一] 进入 package 目录执行
# ---------------------------------------------------------
cd package
    echo "Current Dir: $(pwd)"
    
    # 1. 下载插件 (Packages.sh)
    if [ -f "$MY_SCRIPTS/Packages.sh" ]; then
        chmod +x "$MY_SCRIPTS/Packages.sh"
        echo "Running Packages.sh from $MY_SCRIPTS..."
        source "$MY_SCRIPTS/Packages.sh"
    else
        echo "Error: Packages.sh not found in $MY_SCRIPTS"
    fi

    # 2. 修复插件 (Handles.sh) - 必须在 package 目录跑，因为它用 ../feeds
    if [ -f "$MY_SCRIPTS/Handles.sh" ]; then
        chmod +x "$MY_SCRIPTS/Handles.sh"
        echo "Running Handles.sh from $MY_SCRIPTS..."
        source "$MY_SCRIPTS/Handles.sh"
    else
        echo "Error: Handles.sh not found in $MY_SCRIPTS"
    fi
cd ..

# [阶段二] 退回 根目录 执行
# ---------------------------------------------------------
echo "Current Dir: $(pwd)"

# 3. 应用设置 (Settings.sh) - 必须在根目录跑，因为它用 ./feeds
if [ -f "$MY_SCRIPTS/Settings.sh" ]; then
    chmod +x "$MY_SCRIPTS/Settings.sh"
    echo "Running Settings.sh from $MY_SCRIPTS..."
    source "$MY_SCRIPTS/Settings.sh"
else
    echo "Error: Settings.sh not found in $MY_SCRIPTS"
fi

echo "DIY-Part2 Done!"
