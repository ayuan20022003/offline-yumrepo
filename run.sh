#!/bin/bash
set -e
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir
. ../offlinesry/config.cfg

grep offline-yumrepo /etc/rc.local || echo "/bin/bash /data/offline-yumrepo/run.sh" >> /etc/rc.local
chmod +x /etc/rc.local
ps aux|grep "ForkStaticServer"|grep -v grep|wc -l|grep 1 || nohup ./ForkStaticServer.py $CONFIGSERVER_LOCAL_IP:$CONFIGSERVER_PORT 1>/tmp/sry_yumrepo.log 2>&1 &

sleep 2
curl -Ls http://$CONFIGSERVER_IP:$CONFIGSERVER_PORT/packages/centos/get_repo.sh|bash -s $CONFIGSERVER_IP:$CONFIGSERVER_PORT

rm -f yum_repo_readme.txt
echo "please look yum_repo_readme.txt"
echo "install repo command:"|tee -a yum_repo_readme.txt
echo "curl -Ls http://$CONFIGSERVER_IP:$CONFIGSERVER_PORT/packages/centos/get_repo.sh|bash -s $CONFIGSERVER_IP:$CONFIGSERVER_PORT"|tee -a yum_repo_readme.txt
echo "" | tee -a yum_repo_readme.txt 
echo "yum install command:" | tee -a yum_repo_readme.txt
echo "yum --disablerepo=\* --enablerepo=offlineshurenyunrepo install -y <PACKAGE_NAME>" | tee -a yum_repo_readme.txt
echo "" | tee -a yum_repo_readme.txt
echo "install docker-compose:" | tee -a yum_repo_readme.txt
echo "curl -o /usr/bin/docker-compose http://$CONFIGSERVER_IP:$CONFIGSERVER_PORT/config/docker-compose-1.8.0/docker-compose"
echo


