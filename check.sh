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

curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 http://$CONFIGSERVER_IP:$CONFIGSERVER_PORT/|grep 200
