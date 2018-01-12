#!/bin/bash
set -ex
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir

cp offline-yumrepo.service /usr/lib/systemd/system/
systemctl enable offline-yumrepo
systemctl start offline-yumrepo
