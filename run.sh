#!/bin/bash
set -e
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir
if [  -f "../offlinesry/config.cfg" ];then
	. ../offlinesry/config.cfg
elif [ -f "../offline-dmos/config.cfg" ]; then
        . ../offline-dmos/config.cfg
elif [ -f "../config.cfg" ];then
	. ../config.cfg
else
	. ./config.cfg
fi

ps aux|grep "ForkStaticServer"|grep -v grep|wc -l|grep 1 || nohup ./ForkStaticServer.py $CONFIGSERVER_IP:$CONFIGSERVER_PORT 1>/tmp/sry_yumrepo.log 2>&1 &

sleep 2

rm -f yum_repo_readme.txt
echo "please look yum_repo_readme.txt"
echo "install repo command:"|tee -a yum_repo_readme.txt

items=`ls -d packages/centos/*/`
for i in $items;do
	item=`basename $i`	
	curl -Ls http://$CONFIGSERVER_IP:$CONFIGSERVER_PORT/packages/centos/get_repo.sh|bash -s $CONFIGSERVER_IP:$CONFIGSERVER_PORT $item
	echo "curl -Ls http://$CONFIGSERVER_IP:$CONFIGSERVER_PORT/packages/centos/get_repo.sh|bash -s $CONFIGSERVER_IP:$CONFIGSERVER_PORT $item"|tee -a yum_repo_readme.txt
done

echo "" | tee -a yum_repo_readme.txt 
echo "yum install command:" | tee -a yum_repo_readme.txt
echo "yum --disablerepo=\* --enablerepo=offlineshurenyun* install -y <PACKAGE_NAME>" | tee -a yum_repo_readme.txt
echo "" | tee -a yum_repo_readme.txt
echo "install docker-compose:" | tee -a yum_repo_readme.txt
echo "curl -o /usr/bin/docker-compose http://$CONFIGSERVER_IP:$CONFIGSERVER_PORT/config/docker-compose-1.8.0/docker-compose"| tee -a yum_repo_readme.txt
echo

