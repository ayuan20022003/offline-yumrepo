#!/bin/bash
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir
version=$1

if [ -z "$version" ];then
	echo "Usage: ./$0 version,version value is 7.2|7.3|7.2ee|7.3ee"
	exit 1
fi
createrepo --update $version/x86_64/ 
