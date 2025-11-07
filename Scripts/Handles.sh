#!/bin/bash

#修改argon主题设置
ARGON_FILE="$GITHUB_WORKSPACE/wrt/feeds/luci/applications/luci-app-argon-config/root/etc/config/argon"
DIY_FILE="$GITHUB_WORKSPACE/files/etc/config/argon"
if [ -f "$ARGON_FILE" ]; then
 
    cp -f "$DIY_FILE" "$ARGON_FILE"

	echo "argon主题参数设置成功!"
fi

#修改qca-nss-drv启动顺序
NSS_DRV="../feeds/nss_packages/qca-nss-drv/files/qca-nss-drv.init"
if [ -f "$NSS_DRV" ]; then

	sed -i 's/START=.*/START=85/g' $NSS_DRV

	echo "qca-nss-drv已被修复!"
fi

#修改qca-nss-pbuf启动顺序
NSS_PBUF="./kernel/mac80211/files/qca-nss-pbuf.init"
if [ -f "$NSS_PBUF" ]; then

	sed -i 's/START=.*/START=86/g' $NSS_PBUF

	echo "qca-nss-pbuf已被修复!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then

	sed -i '/\/files/d' $TS_FILE

	echo "tailscale已被修复!"
fi

#修复Rust编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	echo "rust已被修复!"
fi

#修复DiskMan编译失败
DM_FILE="../package/luci-app-diskman/applications/luci-app-diskman/Makefile"
if [ -f "$DM_FILE" ]; then

	sed -i 's/fs-ntfs/fs-ntfs3/g' $DM_FILE
    sed -i '/ntfs-3g-utils /d' $DM_FILE
    sed -i '/config PACKAGE_$(PKG_NAME)_INCLUDE_ntfs_3g_utils/,/default y/d' "$DM_FILE"
	echo "diskman已被修复!"
fi

#设置nginx默认配置
NGINX_FILE="../feeds/packages/net/nginx-util/files/nginx.config"
NGINX_URL="https://gist.githubusercontent.com/huanchenshang/df9dc4e13c6b2cd74e05227051dca0a9/raw/nginx.default.config"

if wget -O "$NGINX_FILE" "$NGINX_URL"; then
    echo "nginx默认配置已成功替换！"
else
    echo "错误：无法下载nginx文件,请检查URL和网络连接。"
	exit 1
fi

#修复quickstart温度显示
QUICKSTART_FILE="../package/luci-app-quickstart/luasrc/controller/istore_backend.lua"
QUICKSTART_URL="https://gist.githubusercontent.com/puteulanus/1c180fae6bccd25e57eb6d30b7aa28aa/raw/istore_backend.lua"

if wget -O "$QUICKSTART_FILE" "$QUICKSTART_URL"; then
    echo "quickstart温度显示已成功修复！"
else
    echo "错误：无法下载quickstart文件,请检查URL和网络连接。"
	exit 1
fi

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
	echo "软件源修改成功!"
fi

#修改CPU 性能优化调节名称显示
cpu_path="$GITHUB_WORKSPACE/wrt/feeds/luci/applications/luci-app-cpufreq"
po_file="$cpu_path/po/zh_Hans/cpufreq.po"

if [ -d "$cpu_path" ] && [ -f "$po_file" ]; then
    sed -i 's/msgstr "CPU 性能优化调节"/msgstr "性能调节"/g' "$po_file"
    echo "cpu调节更名成功"
else
    echo "cpufreq.po文件未找到"
fi

#修改Argon 主题设置名称显示
argon_path="$GITHUB_WORKSPACE/wrt/feeds/luci/applications/luci-app-argon-config"
argonpo_file="$argon_path/po/zh_Hans/argon-config.po"

if [ -d "$argon_path" ] && [ -f "$argonpo_file" ]; then
    sed -i 's/msgstr "Argon 主题设置"/msgstr "主题设置"/g' "$argonpo_file"
    echo "主题设置更名成功"
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
	echo "quickfie添加成功!"
fi

#更换argon源
argon_url="https://github.com/ZqinKing/luci-theme-argon.git"
dst_theme_path="../feeds/luci/themes/luci-theme-argon"
tmp_dir=$(mktemp -d)

    git clone --depth 1 "$argon_url" "$tmp_dir"

    rm -rf "$dst_theme_path"
    rm -rf "$tmp_dir/.git"
    mv "$tmp_dir" "$dst_theme_path"

    echo "luci-theme-argon 更新完成"

#修改argon背景图片
theme_path="$GITHUB_WORKSPACE/wrt/feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img"
source_path="$GITHUB_WORKSPACE/images"
source_file="$source_path/bg1.jpg"
target_file="$theme_path/bg1.jpg"

if [ -f "$source_file" ]; then
    cp -f "$source_file" "$target_file"
    echo "背景图片更新成功"
else
    echo "错误：未找到源图片文件"
fi

#修改automount自动加载和修复ntfs硬盘显示中文
fstools_path="$GITHUB_WORKSPACE/wrt/package/system/fstools/patches"
automount_file="$GITHUB_WORKSPACE/files/0100-automount.patch"
ntfs_file="$GITHUB_WORKSPACE/files/0200-ntfs3-with-utf8.patch"

if [ -d "$fstools_path" ]; then
    cp -f "$automount_file" "$fstools_path"
	cp -f "$ntfs_file" "$fstools_path"
    echo "修改automount自动加载和修复ntfs硬盘显示中文成功"
else
    echo "错误：修改automount和ntfs中文失败"
fi

#添加定时清理内存
sh_dir="$GITHUB_WORKSPACE/wrt/package/base-files/files/etc/init.d"
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
    echo "添加定时清理内存成功!"
else
    echo "添加定时清理内存出错"
fi

#设置使用bbr加速
BBR_CONF_PATH="$PKG_PATH/base-files/files/etc/sysctl.d/10-bbr.conf"
if [ ! -f "$BBR_CONF_PATH" ]; then
    cat <<'EOF' >"$BBR_CONF_PATH"
net.core.default_qdisc=fq
#net.ipv4.tcp_congestion_control=bbr
EOF
    echo "BBR 配置文件创建成功！"
fi

