#!/bin/bash
# 优先使用源码自带插件 (Native First)

# 1. 定义基础变量 (传给 Settings.sh 使用)
export WRT_IP="192.168.6.1"
export WRT_NAME="MyRouter-0"
export WRT_THEME="argon"
export WRT_SSID="My_AP8220"
export WRT_WORD="12345678"
export WRT_TARGET="QUALCOMMAX"

# 2. 调用 Handles.sh (修复脚本)
# 注意：$GITHUB_WORKSPACE 是 Actions 的根目录，脚本通常在那里
if [ -f "$GITHUB_WORKSPACE/Handles.sh" ]; then
    chmod +x $GITHUB_WORKSPACE/Handles.sh
    source $GITHUB_WORKSPACE/Handles.sh
fi

# 3. 调用 Packages.sh (下载插件)
# 这里会去下载 AdGuardHome, KuCat, MosDNS, EasyTier 等
if [ -f "$GITHUB_WORKSPACE/Packages.sh" ]; then
    chmod +x $GITHUB_WORKSPACE/Packages.sh
    cd package
    source $GITHUB_WORKSPACE/Packages.sh
    cd ..
fi

# 4. 调用 Settings.sh (应用设置 & 删除 UU/Autoreboot)
if [ -f "$GITHUB_WORKSPACE/Settings.sh" ]; then
    chmod +x $GITHUB_WORKSPACE/Settings.sh
    source $GITHUB_WORKSPACE/Settings.sh
fi

# 补充：确保 Golang 环境 (MosDNS 需要)
rm -rf feeds/packages/lang/golang
git clone https://github.com/kenzok8/golang feeds/packages/lang/golang

echo "DIY-Part2 Execution Completed!"