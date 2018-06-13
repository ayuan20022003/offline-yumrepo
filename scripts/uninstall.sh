#!/bin/bash
# 功能: 移除node节点 
# Author: yhchen
set -e

BASE_DIR=$(cd `dirname $0` && pwd)
cd $BASE_DIR


# stop services
stopServices(){
	echo "##### stop services start #####"
	chattr -i /etc/resolv.conf
	items="openvswitch origin-node"

	for item in $items;do
		systemctl stop $item
	done
	echo "##### stop services start #####"
}

# clear config files
clearCfgFiles(){
	echo "##### clear config files start #####"
	rm -f /etc/dnsmasq.d/origin-dns.conf /etc/dnsmasq.d/origin-upstream-dns.conf /etc/NetworkManager/dispatcher.d/99-origin-dns.sh
	systemctl restart NetworkManager
	echo "##### clear config files end #####"
}

# clear network 
clearNetwork(){
	echo "##### clear network start #####"
	ovs-vsctl del-br br0 || echo 
	items="lbr0 	vlinuxbr vovsbr"
	for item in $items;do
		ip link del $item || echo 
	done
	echo "##### clear network end #####"
}

# clear virtual device
clearVirDevice(){
	echo "##### clear virtual device start #####"
	items="tun0 docker0"
	for item in $items;do
		nmcli  device delete $item || echo 
	done
	echo "##### clear virtual device end #####"
}

# clear rpm package
clearRpmPkg(){
	echo "##### clear rpm package start #####"
	yum remove -y kubernetes-client \
        	openvswitch \
        	origin \
       		origin-excluder \
        	origin-docker-excluder \
        	origin-clients \
        	origin-node \
        	origin-sdn-ovs \
        	tuned-profiles-atomic-openshift-node \
        	tuned-profiles-origin-node
	echo "##### clear rpm package end #####"
}

# umount
umountVol(){
	echo "##### umount start #####"
	find /var/lib/origin/openshift.local.volumes -type d -exec umount {} \; 2>/dev/null || true
	echo "##### umount end #####"
}

# clear docker
clearDocker(){
	echo "##### clear docker start #####"
	docker ps -a | awk '{print $1}' | xargs docker rm -f || echo 
	docker images| awk '{ print $3 }' | xargs docker rmi -f || echo 
	echo "##### clear docker end #####"
}

#  remove sdn drop files
remvoeSdn(){
	echo "##### remove sdn drop files start #####"
	rm -rf /run/openshift-sdn  /etc/sysconfig/openvswitch 
	rm -rf /etc/origin /var/lib/origin
	echo "##### remove sdn drop files end #####"
}

# reload system config 
reloadSysCfg(){
	echo "##### reload system config start #####"
	systemctl reset-failed
	systemctl daemon-reload
	echo "##### reload system config end #####"
}

# clear docker data
clearDockerData(){
	echo "##### clear docker data start #####"
	systemctl stop docker
	rm -rf /etc/ansible/facts.d/openshift.fact \
    		/etc/pki/ca-trust/source/anchors/openshift-ca.crt \
    		/etc/sysconfig/origin-node \
    		/etc/systemd/system/openvswitch.service.d \
    		/etc/systemd/system/origin-node.service \
    		/var/lib/docker/*
	echo "##### clear docker data end #####"
}

# Rebuild ca-trust
rebuildCaTrust(){
	echo "##### Rebuild ca-trust start #####"
	update-ca-trust
	items="ADD_REGISTRY BLOCK_REGISTRY INSECURE_REGISTRY NO_PROXY HTTP_PROXY HTTPS_PROXY"

	for item in $items;do
		sed -i '/^'$item'=.*/d' /etc/sysconfig/docker
	done
	echo "##### Rebuild ca-trust end #####"
}

# Wipe out Docker storage contents
resetDockerStorage(){
	echo "##### wipe docker storage start #####"
	ISOLATED=`cat /etc/sysconfig/docker-storage-setup | grep DEVS | wc -l`
	if [ "x$ISOLATED" == "x1" ]; then
		 systemctl stop docker && rm -f /etc/sysconfig/docker-storage && vgremove -f docker_vg \
		&& rm -rf /var/lib/docker/ && docker-storage-setup && systemctl start docker
	else
		systemctl stop docker && rm -f /etc/sysconfig/docker-storage && lvremove -y /dev/mapper/vg_root \
		&& docker-storage-setup && systemctl start docker
	fi
	echo "##### wipe docker storage end #####"
}

# reset /etc/resolv.conf
resetResolv(){
	echo "##### reset /etc/resolv.conf start #####"
	\cp /etc/resolv.conf.restore.bak /etc/resolv.conf
	echo "##### reset /etc/resolv.conf end #####"
}

main(){
	stopServices
	clearCfgFiles
	clearNetwork
	clearVirDevice
	clearRpmPkg
	umountVol
	clearDocker
	remvoeSdn
	reloadSysCfg
	clearDockerData
	rebuildCaTrust
	resetDockerStorage
	resetResolv	
}

main
