#!/bin/bash

# =========================================================
# 1. 系统默认设置
# =========================================================
# 移除 attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# 修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# 修改 IP 和 主机名
CFG_FILE="./package/base-files/files/bin/config_generate"
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

# =========================================================
# 2. WiFi 分离设置 (逻辑强制修正版)
# =========================================================
mkdir -p package/base-files/files/etc/uci-defaults
cat <<EOF > package/base-files/files/etc/uci-defaults/99-custom-wifi
#!/bin/sh
. /lib/functions.sh

# 第一步：把所有 WiFi 接口全部先设为 5G 的配置 (作为默认值)
# 这样可以防止 5G 漏网
for radio in \$(uci show wireless | grep "=wifi-device" | cut -d. -f2 | cut -d= -f1); do
    uci set wireless.default_\$radio.ssid='$WRT_SSID_5G'
    uci set wireless.default_\$radio.key='$WRT_WORD_5G'
    uci set wireless.default_\$radio.encryption='psk2+ccmp'
    uci set wireless.\$radio.disabled='0'
done

# 第二步：专门把 2.4G 的找出来，改回 2.4G 的配置
for radio in \$(uci show wireless | grep "=wifi-device" | cut -d. -f2 | cut -d= -f1); do
    hwmode=\$(uci -q get wireless.\$radio.hwmode)
    htmode=\$(uci -q get wireless.\$radio.htmode)
    
    # 只要 hwmode 或 htmode 里带有 'g' (11g, 11ng, 11axg)，它就是 2.4G
    case "\$hwmode\$htmode" in
        *g*) 
            uci set wireless.default_\$radio.ssid='$WRT_SSID_2G'
            uci set wireless.default_\$radio.key='$WRT_WORD_2G'
            uci set wireless.default_\$radio.encryption='psk2+ccmp'
            ;;
    esac
done

uci commit wireless
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-custom-wifi

# =========================================================
# 3. 配置文件注入 (.config)
# =========================================================
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

# 手动调整的插件变量注入
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

# 高通平台调整 (AP8220 必备)
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	echo "CONFIG_FEED_nss_packages=y" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
	echo "CONFIG_PACKAGE_luci-app-sqm=y" >> ./.config
	echo "CONFIG_PACKAGE_sqm-scripts-nss=y" >> ./.config
	echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> ./.config
	echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
fi
