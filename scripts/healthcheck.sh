#!/bin/bash

let errcode=0

error(){
	echo "ERROR: $1"
	errcode+=1
}

getenforce|grep Enforcing 1>/dev/null || error "Selinux is not Enforcing !"

ip route show |grep 'default via' 1>/dev/null || error "ip route not found default gateway !"

docker info 1>/dev/null || error "docker daemon is error !" 


if [ $errcode -ne 0 ];then
	exit $errcode
fi
