#!/bin/bash

# =========================================================
# 1. 系统/默认设置修改
# =========================================================

# 移除自带的 attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# 修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# 修改 immotalwrt.lan 关联 IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")

# 添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

# 修改 config_generate 里的 IP 和 主机名
CFG_FILE="./package/base-files/files/bin/config_generate"
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

# =========================================================
# 2. WiFi 分离设置 (修复版)
# =========================================================
mkdir -p package/base-files/files/etc/uci-defaults
cat <<EOF > package/base-files/files/etc/uci-defaults/99-custom-wifi
#!/bin/sh
. /lib/functions.sh

# 遍历 WiFi 设备
for radio in \$(uci show wireless | grep "=wifi-device" | cut -d. -f2 | cut -d= -f1); do
    hwmode=\$(uci -q get wireless.\$radio.hwmode)
    htmode=\$(uci -q get wireless.\$radio.htmode)
    
    # 严格判断 5G: 必须包含 'a' 且不能包含 'g'
    is_5g=0
    case "\$hwmode\$htmode" in
        *g*) is_5g=0 ;; 
        *a*) is_5g=1 ;;
    esac

    if [ "\$is_5g" -eq 1 ]; then
        # 5G 设置
        uci set wireless.default_\$radio.ssid='$WRT_SSID_5G'
        uci set wireless.default_\$radio.key='$WRT_WORD_5G'
        uci set wireless.default_\$radio.encryption='psk2+ccmp'
    else
        # 2.4G 设置
        uci set wireless.default_\$radio.ssid='$WRT_SSID_2G'
        uci set wireless.default_\$radio.key='$WRT_WORD_2G'
        uci set wireless.default_\$radio.encryption='psk2+ccmp'
    fi
    
    uci set wireless.\$radio.disabled='0'
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
DTS_PATH="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
	echo "CONFIG_PACKAGE_luci-app-sqm=y" >> ./.config
	echo "CONFIG_PACKAGE_sqm-scripts-nss=y" >> ./.config
	echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> ./.config
	if [[ "${WRT_CONFIG,,}" == *"ipq50"* ]]; then
		echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> ./.config
	else
		echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
	fi
	if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
fi
