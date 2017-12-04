#!/bin/bash
# get shurenyun centos repo
# Author: Liujinye
# Date: 2015-3-9
#
set -e 

# Usage: curl -Ls http://ADDR/packages/centos/get_repo.sh|bash -s ADDR

export DEBIAN_FRONTEND=noninteractive
ADDR=$1
ITEM=$2

if [ -z "$ADDR" ] || [ -z "$ITEM" ] ;then
	echo "Usage: ./$0 <ADDR> <ITEM> ; item value is base|update|openshift-origin|ansible|docker "
	exit 1
fi

cat > /etc/yum.repos.d/offlineshurenyun.$ITEM.repo << EOF
[offlineshurenyun_${ITEM}_repo]
name=Shurenyun CentOS Repo
baseurl=http://$ADDR/packages/centos/$ITEM/x86_64
gpgcheck=0
EOF


