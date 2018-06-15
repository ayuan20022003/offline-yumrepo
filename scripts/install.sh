#!/bin/bash
set -e
BASE_DIR=$(cd `dirname $0` && pwd)
cd $BASE_DIR

# Usage: curl -Ls http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/scripts/install.sh | sh  -s ${CONFIGSERVER_IP} ${CONFIGSERVER_PORT} ${DEVS}

CONFIGSERVER_IP=$1
CONFIGSERVER_PORT=$2
DEVS=$3

CONFIGSERVER_IP=${CONFIGSERVER_IP:-192.168.1.216}
CONFIGSERVER_PORT=${CONFIGSERVER_PORT:-8081}

DOCKER_VG_NAME=${DOCKER_VG_NAME:-docker_vg}

if [ ! -z "$DEVS" ];then
        DOCKER_STORAGE_MODE=yes
else
	DOCKER_STORAGE_MODE=no
fi

check_var(){
	echo "------------------- check yum repo and check raw device -------------------"
	YUM_STATUS=`curl -s -o /dev/null -w "%{http_code}" http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT} || echo $?`
	if [ "x$YUM_STATUS" != "x200" ]; then
		echo "please check yum repo service whether ok or yum repo addr error !!!"
		exit 1
	fi
	RAW_DEVICE_DISK=`lsblk -l | grep "^${DEVS}" | grep disk | wc -l`
	RAW_DEVICE_PART=`lsblk -l | grep "^${DEVS}" | grep part | wc -l`
	if [ "$RAW_DEVICE_DISK" == 0 -o "$RAW_DEVICE_PART" != 0 ]; then
		echo "/dev/${DEVS} not exist or is not raw device !!!"
		exit 1
	fi
}

install_offline_yumrepo(){
	echo "------------------- install offline yumrepo -------------------"
	# backup old yumrepo
	mkdir -p /etc/yum.repos.d/repobak && mv -f /etc/yum.repos.d/*.repo /etc/yum.repos.d/repobak/ || echo $?

	# install offline yumrepo
	repos=`curl -s http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/packages/centos/ |grep -wo '>.*.x86_64.rpms.txt<'|tr -d '>|<'|awk -F. '{print $1}'`
	for item in $repos;do
	    curl -Ls http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/packages/centos/get_repo.sh|bash -s ${CONFIGSERVER_IP}:${CONFIGSERVER_PORT} $item
	done

	# yum clean cache
	yum clean all && yum-complete-transaction --cleanup-only || echo $?
}

install_base_tools(){
	echo "------------------- install base tools ------------------- "
	yum install -y wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct java-1.8.0-openjdk-headless \
	PyYAML python-ipaddress yum-utils telnet curl lrzsz jq perf strace vim iotop python-passlib NetworkManager dnsmasq origin-node-3.9.0 origin-sdn-ovs-3.9.0  \
	conntrack-tools nfs-utils  glusterfs-fuse ceph-common iscsi-initiator-utils origin-docker-excluder origin-excluder device-mapper-multipath
}

optimize_journald(){
	echo "------------------- optimize journald -------------------"
	curl -Ls -o /etc/systemd/journald.conf  http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/config/system/journald.conf
	systemctl restart systemd-journald.service
}

disable_firewalld(){
	echo "------------------- disable firewalld  -------------------"
	systemctl disable firewalld
	systemctl stop firewalld
}

enable_selinux(){
	echo "------------------- enable selinux -------------------"
	sed -i 's/^SELINUX=.*/SELINUX=enforcing/g' /etc/selinux/config
}

optimize_ulimit(){
	echo "------------------- optimize ulimit -------------------"
	curl -Ls -o /etc/security/limits.d/30-nproc.conf http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/config/system/30-nproc.conf
}

optimize_sysctl(){
	echo "------------------- optimize sysctl -------------------"
	curl -Ls -o /etc/sysctl.conf  http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/config/system/sysctl.conf
}

swap_off(){
	echo "------------------- swap off -------------------"
	swapoff -a && sed -i 's/^[^#].*[[:space:]]swap[[:space:]]/#&/g' /etc/fstab
}

optimize_ssh(){
	echo "------------------- optimize ssh -------------------"
	sed -i 's/.*UseDNS no/UseDNS no/g' /etc/ssh/sshd_config
}

time_sync(){
	echo "------------------- time sync -------------------"
	timedatectl set-timezone Asia/Shanghai
	systemctl disable ntpd &>/dev/null || echo
	yum install -y chrony
	curl -Ls -o /etc/chrony.conf http://${CONFIGSERVER_IP}:${CONFIGSERVER_PORT}/config/system/chrony.conf
	sed -i 's/--CONFIGSERVER_IP--/'${CONFIGSERVER_IP}'/g'  /etc/chrony.conf
	systemctl restart chronyd
	systemctl enable chronyd
}

update_system(){
	echo "------------------- update system -------------------"
	yum update -y
	ls  /etc/yum.repos.d/CentOS-* &>/dev/null && mv -f /etc/yum.repos.d/CentOS-* /etc/yum.repos.d/repobak/ || echo
}

install_docker(){
	echo "------------------- install docker -------------------"
	yum install docker -y
        docker version || echo $?
        #  本机配置docker 存储（下面两种选一种配置）
        # 无独立存储，docker存储使用根目录的vg剩余的磁盘空间，使用该配置
        if [ "$DOCKER_STORAGE_MODE" == "no" ]; then
                cat <<EOF > /etc/sysconfig/docker-storage-setup
CONTAINER_THINPOOL=docker-pool
DATA_SIZE=99%FREE
EOF
        # 有独立docker使用的裸盘存储，使用此配置
        elif [ "$DOCKER_STORAGE_MODE" == "yes" ]; then
                cat <<EOF > /etc/sysconfig/docker-storage-setup
DEVS=${DEVS}
VG=${DOCKER_VG_NAME}
DATA_SIZE=99%FREE
WIPE_SIGNATURES=true
EOF
        fi

	# 生成docker 存储
	docker-storage-setup
	cat /etc/sysconfig/docker-storage
	lvs
	systemctl enable docker
	systemctl start docker
	docker info
}

config_resolv(){
	echo "------------------- config resolv -------------------"
	chattr -i /etc/resolv.conf
        cat <<EOF > /etc/resolv.conf
# Generated by NetworkManager
nameserver ${CONFIGSERVER_IP}
EOF
	chattr +i /etc/resolv.conf
}

main(){
	check_var
	install_offline_yumrepo
	install_base_tools
	optimize_journald
	disable_firewalld
	enable_selinux	
	optimize_ulimit
	optimize_sysctl
	swap_off
	optimize_ssh
	time_sync
	config_resolv
	update_system
	install_docker
	reboot
}

main
