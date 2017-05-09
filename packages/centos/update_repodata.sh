#!/bin/bash
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir
version=$1

if [ -z "$version" ];then
	echo "Usage: ./$0 version,version value is 7.2 or 7.3"
	exit 1
fi
createrepo --update $version/x86_64/ 
