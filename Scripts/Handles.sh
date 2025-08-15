#!/bin/bash

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

#预置HomeProxy数据
if [ -d *"homeproxy"* ]; then

	HP_RULE="surge"
	HP_PATH="../feeds/luci/applications/luci-app-homeproxy/root/etc/homeproxy"

	rm -rf ./$HP_PATH/resources/*

	git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
	cd ./$HP_RULE/ && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")

	echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
	awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
	sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
	mv -f ./{china_*,gfw_list}.{ver,txt} ../$HP_PATH/resources/

	cd .. && rm -rf ./$HP_RULE/

	cd $PKG_PATH && echo "homeproxy数据更新成功"
fi

#修改argon主题设置
ARGON_FILE="$GITHUB_WORKSPACE/wrt/feeds/luci/applications/luci-app-argon-config/root/etc/config/argon"
DIY_FILE="$GITHUB_WORKSPACE/files/etc/config/argon"
if [ -f "$ARGON_FILE" ]; then
 
    cp -f "$DIY_FILE" "$ARGON_FILE"

	cd $PKG_PATH && echo "argon主题参数设置成功!"
fi

#修改qca-nss-drv启动顺序
NSS_DRV="../feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
if [ -f "$NSS_DRV" ]; then

	sed -i 's/START=.*/START=85/g' $NSS_DRV

	cd $PKG_PATH && echo "qca-nss-drv已被修复!"
fi

#修改qca-nss-pbuf启动顺序
NSS_PBUF="./kernel/mac80211/files/qca-nss-pbuf.init"
if [ -f "$NSS_PBUF" ]; then

	sed -i 's/START=.*/START=86/g' $NSS_PBUF

	cd $PKG_PATH && echo "qca-nss-pbuf已被修复!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then

	sed -i '/\/files/d' $TS_FILE

	cd $PKG_PATH && echo "tailscale已被修复!"
fi

#修复Rust编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	cd $PKG_PATH && echo "rust已被修复!"
fi

#修复DiskMan编译失败
DM_FILE="../package/luci-app-diskman/applications/luci-app-diskman/Makefile"
if [ -f "$DM_FILE" ]; then

	sed -i 's/fs-ntfs/fs-ntfs3/g' $DM_FILE
    sed -i '/ntfs-3g-utils /d' $DM_FILE

	cd $PKG_PATH && echo "diskman已被修复!"
fi

# 自定义v2ray-geodata下载
V2RAY_FILE="../feeds/packages/net/v2ray-geodata"
MF_FILE="$GITHUB_WORKSPACE/package/v2ray-geodata/Makefile"
SH_FILE="$GITHUB_WORKSPACE/package/v2ray-geodata/init.sh"
UP_FILE="$GITHUB_WORKSPACE/package/v2ray-geodata/v2ray-geodata-updater"
if [ -d "$V2RAY_FILE" ]; then

	cp -f "$MF_FILE" "$V2RAY_FILE/Makefile"
	cp -f "$SH_FILE" "$V2RAY_FILE/init.sh"
	cp -f "$UP_FILE" "$V2RAY_FILE/v2ray-geodata-updater"

	cd $PKG_PATH && echo "v2ray-geodata自定义成功!"
fi

#设置nginx默认配置和修复quickstart温度显示
wget "https://gist.githubusercontent.com/huanchenshang/df9dc4e13c6b2cd74e05227051dca0a9/raw/nginx.default.config" -O ../feeds/packages/net/nginx-util/files/nginx.config
wget "https://gist.githubusercontent.com/puteulanus/1c180fae6bccd25e57eb6d30b7aa28aa/raw/istore_backend.lua" -O ../package/luci-app-quickstart/luasrc/controller/istore_backend.lua

# 安装opkg distfeeds
emortal_def_dir="$GITHUB_WORKSPACE/wrt/package/emortal/default-settings"
distfeeds_conf="$emortal_def_dir/files/99-distfeeds.conf"

if [ -d "$emortal_def_dir" ] && [ ! -f "$distfeeds_conf" ]; then
    cat <<'EOF' >"$distfeeds_conf"
src/gz openwrt_base https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/base/
src/gz openwrt_luci https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/luci/
src/gz openwrt_packages https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/packages/
src/gz openwrt_routing https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/routing/
src/gz openwrt_telephony https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/telephony/
EOF
    sed -i "/define Package\/default-settings\/install/a\\
\\t\$(INSTALL_DIR) \$(1)/etc\\n\
\t\$(INSTALL_DATA) ./files/99-distfeeds.conf \$(1)/etc/99-distfeeds.conf\n" $emortal_def_dir/Makefile

    sed -i "/exit 0/i\\
[ -f \'/etc/99-distfeeds.conf\' ] && mv \'/etc/99-distfeeds.conf\' \'/etc/opkg/distfeeds.conf\'\n\
sed -ri \'/check_signature/s@^[^#]@#&@\' /etc/opkg.conf\n" $emortal_def_dir/files/99-default-settings
	cd $PKG_PATH && echo "软件源修改成功!"
fi

#修改CPU 性能优化调节名称显示
cpu_path="$GITHUB_WORKSPACE/wrt/feeds/luci/applications/luci-app-cpufreq"
po_file="$cpu_path/po/zh_Hans/cpufreq.po"

if [ -d "$cpu_path" ] && [ -f "$po_file" ]; then
    sed -i 's/msgstr "CPU 性能优化调节"/msgstr "性能调节"/g' "$po_file"
    cd $PKG_PATH && echo "cpu调节更名成功"
else
    echo "cpufreq.po文件未找到"
fi

#修改Argon 主题设置名称显示
argon_path="$GITHUB_WORKSPACE/wrt/feeds/luci/applications/luci-app-argon-config"
argonpo_file="$argon_path/po/zh_Hans/argon-config.po"

if [ -d "$argon_path" ] && [ -f "$argonpo_file" ]; then
    sed -i 's/msgstr "Argon 主题设置"/msgstr "主题设置"/g' "$argonpo_file"
    cd $PKG_PATH && echo "主题设置更名成功"
else
    echo "argon-config.po文件没有找到"
fi

#添加quickfile文件管理
quickfile_url="https://github.com/sbwml/luci-app-quickfile.git"
quickfile_dir="$GITHUB_WORKSPACE/wrt/package/emortal/quickfile"
if [ -d "$quickfile_dir" ]; then
    rm -rf "$quickfile_dir"
fi
git clone --depth 1 "$quickfile_url" "$quickfile_dir"

makefile_path="$quickfile_dir/quickfile/Makefile"
if [ -f "$makefile_path" ]; then
    sed -i '/\t\$(INSTALL_BIN) \$(PKG_BUILD_DIR)\/quickfile-\$(ARCH_PACKAGES)/c\
\tif [ "\$(ARCH_PACKAGES)" = "x86_64" ]; then \\\
\t\t\$(INSTALL_BIN) \$(PKG_BUILD_DIR)\/quickfile-x86_64 \$(1)\/usr\/bin\/quickfile; \\\
\telse \\\
\t\t\$(INSTALL_BIN) \$(PKG_BUILD_DIR)\/quickfile-aarch64_generic \$(1)\/usr\/bin\/quickfile; \\\
\tfi' "$makefile_path"
	cd $PKG_PATH && echo "quickfie添加成功!"
fi

#更换argon源
argon_url="https://github.com/huanchenshang/luci-theme-argon.git"
dst_theme_path="../feeds/luci/themes/luci-theme-argon"
tmp_dir=$(mktemp -d)

    git clone --depth 1 "$argon_url" "$tmp_dir"

    rm -rf "$dst_theme_path"
    rm -rf "$tmp_dir/.git"
    mv "$tmp_dir" "$dst_theme_path"

    cd $PKG_PATH && echo "luci-theme-argon 更新完成"

#修改argon背景图片
theme_path="$GITHUB_WORKSPACE/wrt/feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/background"
source_path="$GITHUB_WORKSPACE/images"
source_file="$source_path/bg1.jpg"
target_file="$theme_path/bg1.jpg"

if [ -f "$source_file" ]; then
    cp -f "$source_file" "$target_file"
    cd $PKG_PATH && echo "背景图片更新成功：$target_file"
else
    echo "错误：未找到源图片文件：$source_file"
fi

#添加定时清理内存
sh_dir="$PKG_PATH/base-files/files/etc/init.d"
if [ -d "$sh_dir" ]; then
    cat <<'EOF' >"$sh_dir/custom_task"
#!/bin/sh /etc/rc.common
# 设置启动优先级
START=99

boot() {
    # 重新添加缓存请求定时任务
    sed -i '/drop_caches/d' /etc/crontabs/root
    echo "15 3 * * * sync && echo 3 > /proc/sys/vm/drop_caches" >>/etc/crontabs/root
    # 应用新的 crontab 配置
    crontab /etc/crontabs/root
}
EOF
    chmod +x "$sh_dir/custom_task"
    cd $PKG_PATH && echo "添加定时清理内存成功!"
else
    echo "添加定时清理内存出错"
fi
