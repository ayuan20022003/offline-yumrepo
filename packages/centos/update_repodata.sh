#!/bin/bash
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir

#set -x

versions=$1

if [ -z "$versions" ];then
	versions=`ls -d */`
fi

for version in $versions
do
	version=`basename $version`
	createrepo --update ${version}/x86_64
	ls -1 ${version}/x86_64/RPMS/ > ${version}.x86_64.rpms.txt
done
