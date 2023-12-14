#!/bin/bash
set -e

warning() { echo -e "\033[31m\033[01m$*\033[0m"; }         # 红色
error() { echo -e "\033[31m\033[01m$*\033[0m" && exit 1; } # 红色
info() { echo -e "\033[32m\033[01m$*\033[0m"; }            # 绿色
hint() { echo -e "\033[33m\033[01m$*\033[0m"; }            # 黄色

####

DOWNLOAD_HOST="https://api.candypath.eu.org"

PRODUCT="$1"
TYPE="$1"
PRODUCT_ARGUMENTS="$2"

if [ -z "$PRODUCT" ]; then
    error "输入有误"
fi

if [ -z "$PRODUCT_ARGUMENTS" ]; then
    error "输入有误"
fi

#### 判断处理器架构

case $(uname -m) in
aarch64 | arm64) ARCH=arm64 ;;
x86_64 | amd64) [[ "$(awk -F ':' '/flags/{print $2; exit}' /proc/cpuinfo)" =~ avx2 ]] && ARCH=amd64v3 || ARCH=amd64 ;;
*) error "cpu not supported" ;;
esac
PRODUCT="$PRODUCT"_linux_"$ARCH"

####

mkdir -p ~/.configs
mkdir -p /opt/nyanpass1
cd /opt/nyanpass1

# shellcheck disable=SC2015
systemctl stop nyanpass1 && info "暂停旧服务" || true

#### Download & unzip product

curl -fLSsO "$DOWNLOAD_HOST"/download/download.sh
bash download.sh "$DOWNLOAD_HOST" "$PRODUCT"

#### Install

rm -f start.sh
echo 'source ./env.sh || true' >>start.sh

if [ "$TYPE" == "rel_nodeclient" ]; then
    echo './rel_nodeclient' "$PRODUCT_ARGUMENTS" >>start.sh
fi

echo '[Unit]
Description=nyanpass1
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
WorkingDirectory=/opt/nyanpass1
ExecStart=bash /opt/nyanpass1/start.sh
[Install]
WantedBy=multi-user.target
' >/etc/systemd/system/nyanpass1.service

systemctl daemon-reload
systemctl enable --now nyanpass1

info "安装成功"
info "如需卸载，请运行以下命令："
echo "systemctl disable --now nyanpass1 ; rm -rf /opt/nyanpass1"
