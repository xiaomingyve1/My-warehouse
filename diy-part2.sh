#!/bin/bash
# Description: OpenWrt DIY script part 2 (After Update feeds)

# =========================================================
# 1. 基础设置 (变量定义)
# =========================================================
export WRT_IP="192.168.6.1"
export WRT_NAME="MyRouter-0"
export WRT_THEME="argon"

# --- WiFi 2.4G 设置 ---
export WRT_SSID_2G="My_AP8220_2.4G"
export WRT_WORD_2G="12345678"

# --- WiFi 5G 设置 ---
export WRT_SSID_5G="My_AP8220_5G"
export WRT_WORD_5G="12345678"

# --- 关键系统标识 ---
export WRT_TARGET="QUALCOMMAX"

# =========================================================
# 2. 补充环境 (解决编译报错)
# =========================================================
# 必须先执行这个，确保后续插件能编译
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# =========================================================
# 3. 调用外部脚本 (注意路径！)
# =========================================================

# (1) Packages.sh: 必须进入 package 目录下载，这样才会生成 apk
if [ -f "$GITHUB_WORKSPACE/Packages.sh" ]; then
    chmod +x $GITHUB_WORKSPACE/Packages.sh
    echo "Running Packages.sh in package/ directory..."
    cd package
    source $GITHUB_WORKSPACE/Packages.sh
    cd ..
fi

# (2) Handles.sh: 必须在 根目录 执行，否则找不到 ../feeds 文件
if [ -f "$GITHUB_WORKSPACE/Handles.sh" ]; then
    chmod +x $GITHUB_WORKSPACE/Handles.sh
    echo "Running Handles.sh in root directory..."
    source $GITHUB_WORKSPACE/Handles.sh
fi

# (3) Settings.sh: 必须在 根目录 执行
if [ -f "$GITHUB_WORKSPACE/Settings.sh" ]; then
    chmod +x $GITHUB_WORKSPACE/Settings.sh
    echo "Running Settings.sh in root directory..."
    source $GITHUB_WORKSPACE/Settings.sh
fi

echo "DIY-Part2 Done!"
