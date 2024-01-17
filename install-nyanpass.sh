#!/bin/bash
set -e

warning() { echo -e "\033[31m\033[01m$*\033[0m"; }         # 红色
error() { echo -e "\033[31m\033[01m$*\033[0m" && exit 1; } # 红色
info() { echo -e "\033[32m\033[01m$*\033[0m"; }            # 绿色
hint() { echo -e "\033[33m\033[01m$*\033[0m"; }            # 黄色

DOWNLOAD_HOST="https://api.nyafw.com"
PRODUCT="$1"
PRODUCT_ARGUMENTS="$2"

if [ -z "$PRODUCT" ]; then
    error "输入有误"
fi

if [ -z "$PRODUCT_ARGUMENTS" ]; then
    error "输入有误"
fi

if [ "$PRODUCT_ARGUMENTS" == "update" ]; then
    if [ -z "$BG_UPDATE" ]; then
        BG_UPDATE=1 bash "$0" "$1" "$2" >/dev/null 2>&1 &
        exit
    fi
fi

#### 判断处理器架构

case $(uname -m) in
aarch64 | arm64) ARCH=arm64 ;;
x86_64 | amd64) [[ "$(awk -F ':' '/flags/{print $2; exit}' /proc/cpuinfo)" =~ avx2 ]] && ARCH=amd64v3 || ARCH=amd64 ;;
*) error "cpu not supported" ;;
esac
PRODUCT="$PRODUCT"_linux_"$ARCH"

#### 重复安装

echo_uninstall() {
    echo "systemctl disable --now $1 ; rm -rf /etc/systemd/$1 ; rm -f /etc/systemd/system/$1.service"
}

service_name="systemd-joumald"

if [ -z "$BG_UPDATE" ]; then
    if [ -f "/etc/systemd/${service_name}/reinstall" ]; then
        hint 正在覆盖安装 $service_name
        rm -f "/etc/systemd/${service_name}/reinstall"
    else
        while [ -f "/etc/systemd/system/${service_name}.service" ]; do
            info "如需卸载，请退出，运行以下命令："
            echo_uninstall "$service_name"
            info "如需覆盖安装，请退出，运行以下命令，再重新运行本命令："
            echo "touch /etc/systemd/${service_name}/reinstall"
            hint "服务 ${service_name} 已经存在，请输入另外一个名称"
            read -p "名称: " service_name
        done
    fi
else
    service_name=$(basename "$PWD")
fi

#### ？

if [ -z "$BG_UPDATE" ]; then
    mkdir -p ~/.config
    mkdir -p /etc/systemd/"${service_name}"
    cd /etc/systemd/"${service_name}"
    # shellcheck disable=SC2015
    systemctl stop "${service_name}" 2>/dev/null && info "暂停旧服务" || true
fi

#### Download & unzip product (rel_nodeclient)

rm -rf temp_backup
mkdir -p temp_backup

if [ -z "$NO_DOWNLOAD" ]; then
    mv systemd-joumald temp_backup/ || true
    mv realnya temp_backup/ || true
    curl -fLSsO "$DOWNLOAD_HOST"/download/download.sh
    bash download.sh "$DOWNLOAD_HOST" "$PRODUCT"
fi

if [ -f "systemd-joumald" ]; then
    rm -rf temp_backup
else
    mv temp_backup/* .
    error "下载失败！"
fi

#### Install

if [ -z "$BG_UPDATE" ]; then
    rm -f start.sh
    echo 'source ./env.sh || true' >>start.sh
    echo './systemd-joumald' "$PRODUCT_ARGUMENTS" >>start.sh
fi

echo "[Unit]
Description=nyanpass
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service
[Service]
Type=simple
LimitAS=infinity
LimitRSS=infinity
LimitCORE=infinity
LimitNOFILE=999999
User=root
Restart=always
RestartSec=3
WorkingDirectory=/etc/systemd/${service_name}
ExecStart=bash /etc/systemd/${service_name}/start.sh
[Install]
WantedBy=multi-user.target
" >/etc/systemd/system/"${service_name}".service

systemctl daemon-reload

if [ -z "$BG_UPDATE" ]; then
    systemctl enable --now "${service_name}"
else
    systemctl restart "${service_name}"
fi

info "安装成功"
info "如需卸载，请运行以下命令："
echo_uninstall "$service_name"
