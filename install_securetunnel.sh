#!/bin/sh
clear
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

mirror="https://pkg.zeroteam.top"
service_name="SecureTunnel1"
ver=""

echo -e "${Font_SkyBlue}SecureTunnel installation script${Font_Suffix}"

while [ $# -gt 0 ]; do
    case $1 in
    --api)
        api=$2
        shift
        ;;
    --id)
        id=$2
        shift
        ;;
    --secret)
        secret=$2
        shift
        ;;
    --service)
        service_name=$2
        shift
        ;;
    --mirror)
        mirror=$2
        shift
        ;;
    --version)
        ver=$2
        shift
        ;;
    *)
        echo -e "${Font_Red} Unknown param: $1 ${Font_Suffix}"
        exit
        ;;
    esac
    shift
done

if [ -z "${api}" ]; then
    echo -e "${Font_Red}param 'api' not found${Font_Suffix}"
    exit 1
fi

if [ -z "${id}" ]; then
    echo -e "${Font_Red}param 'id' not found${Font_Suffix}"
    exit 1
fi

if [ -z "${secret}" ]; then
    echo -e "${Font_Red}param 'secret' not found${Font_Suffix}"
    exit 1
fi

if [ -z "${service_name}" ]; then
    echo -e "${Font_Red}param 'service' not found${Font_Suffix}"
    exit 1
fi

if [ -z "${mirror}" ]; then
    echo -e "${Font_Red}param 'mirror' not found${Font_Suffix}"
    exit 1
fi

echo -e "${Font_Yellow} ** Checking system info...${Font_Suffix}"
case $(uname -m) in
x86)
    arch="386"
    ;;
i386)
    arch="386"
    ;;
x86_64)
    cpu_flags=$(cat /proc/cpuinfo | grep flags | head -n 1 | awk -F ':' '{print $2}')
    if [[ ${cpu_flags} == *avx512* ]]; then
        arch="amd64v4"
    elif [[ ${cpu_flags} == *avx2* ]]; then
        arch="amd64v3"
    elif [[ ${cpu_flags} == *sse3* ]]; then
        arch="amd64v2"
    else
        arch="amd64v1"
    fi
    ;;
armv7*)
    arch="armv7"
    ;;
aarch64)
    arch="arm64"
    ;;
s390x)
    arch="s390x"
    ;;
*)
    echo -e "${Font_Red}Unsupport architecture${Font_Suffix}"
    exit 1
    ;;
esac

if [[ ! -e "/usr/bin/systemctl" ]] && [[ ! -e "/bin/systemctl" ]]; then
    echo -e "${Font_Red}Not found systemd${Font_Suffix}"
    exit 1
fi

while [ -f "/etc/systemd/system/${service_name}.service" ]; do
    read -p "Service ${service_name} is exists, please input a new service name: " service_name
done

dir="/opt/${service_name}"
while [ -d "${dir}" ]; do
    read -p "${dir} is exists, please input a new dir: " dir
done

echo -e "${Font_Yellow} ** Checking release info...${Font_Suffix}"
if [[ -z "$ver" ]]; then
    ver=$(curl -sL "${mirror}/api/latest?repo=PortForwardGo")
    if [ -z "${ver}" ]; then
        echo -e "${Font_Red}Unable to get releases info${Font_Suffix}"
        exit 1
    fi
    echo -e " Detected lastet verion: " ${ver}
else
    echo -e " Use specified manually verion: " ${ver}
fi

echo -e "${Font_Yellow} ** Download release info...${Font_Suffix}"

curl -L -o /tmp/SecureTunnel.tar.gz "${mirror}/PortForwardGo/${ver}/SecureTunnel_${ver}_linux_${arch}.tar.gz"
if [ ! -f "/tmp/SecureTunnel.tar.gz" ]; then
    echo -e "${Font_Red}Download failed${Font_Suffix}"
    exit 1
fi

tar -xvzf /tmp/SecureTunnel.tar.gz -C /tmp/
if [ ! -f "/tmp/SecureTunnel" ]; then
    echo -e "${Font_Red}Decompression failed${Font_Suffix}"
    exit 1
fi

if [ ! -f "/tmp/systemd/SecureTunnel.service" ]; then
    echo -e "${Font_Red}Decompression failed${Font_Suffix}"
    exit 1
fi

mkdir -p ${dir}
chmod 777 /tmp/SecureTunnel
mv /tmp/SecureTunnel ${dir}

mv /tmp/systemd/SecureTunnel.service /etc/systemd/system/${service_name}.service
sed -i "s#{dir}#${dir}#g" /etc/systemd/system/${service_name}.service
sed -i "s#{api}#${api}#g" /etc/systemd/system/${service_name}.service
sed -i "s#{id}#${id}#g" /etc/systemd/system/${service_name}.service
sed -i "s#{secret}#${secret}#g" /etc/systemd/system/${service_name}.service

rm -rf /tmp/*

echo -e "${Font_Yellow} ** Optimize system config...${Font_Suffix}"

echo "net.ipv4.ip_local_port_range = 1024 65535" >/etc/sysctl.d/97-system-port-range.conf
echo -e "${Font_Green}已修改系统对外连接占用端口为 1024-65535, 配置文件 /etc/sysctl.d/97-system-port-range.conf${Font_Suffix}"

echo "fs.file-max = 1000000
fs.inotify.max_user_instances = 8192
fs.pipe-max-size = 1048576
fs.pipe-user-pages-hard = 0
fs.pipe-user-pages-soft = 0

net.ipv4.somaxconn = 3276800
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_retries1 = 5
net.ipv4.tcp_retries2 = 5
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_max_tw_buckets = 4096
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_abort_on_overflow = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_stdurg = 0
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_frto = 2
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_ecn_fallback = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_reordering = 300
net.ipv4.tcp_retrans_collapse = 0
net.ipv4.tcp_autocorking = 1
net.ipv4.tcp_low_latency = 0
net.ipv4.tcp_slow_start_after_idle = 1
net.ipv4.tcp_no_metrics_save = 0
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_tso_win_divisor = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_congestion_control = bbr

net.ipv4.ip_forward = 1
net.ipv4.route.gc_timeout = 100
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

net.core.netdev_max_backlog = 16384
net.core.netdev_budget = 600
net.core.somaxconn = 3276800
net.core.default_qdisc = fq
" > /etc/sysctl.d/98-optimize.conf
echo -e "${Font_Green}已开启BBR和系统调优, 配置文件 /etc/sysctl.d/98-optimize.conf${Font_Suffix}"

echo "* soft nofile 1048576
* hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
* soft core 1048576
* hard core 1048576
* hard memlock unlimited
* soft memlock unlimited" > /etc/security/limits.conf
echo -e "${Font_Green}已解除系统ulimit限制, 配置文件 /etc/security/limits.conf${Font_Suffix}"

echo -e "${Font_Green}应用新的系统配置...${Font_Suffix}"
sysctl -p > /dev/null 2>&1
sysctl --system > /dev/null 2>&1
echo -e "${Font_Green}优化完成, 部分优化可能需要重启系统才能生效${Font_Suffix}"

echo -e "${Font_Yellow} ** Starting program...${Font_Suffix}"
systemctl daemon-reload
systemctl enable --now ${service_name}

echo -e "${Font_Green} [Success] Completed installation${Font_Suffix}"
