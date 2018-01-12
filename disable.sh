#!/bin/bash
set -ex
base_dir=$(cd `dirname $0` && pwd)
cd $base_dir

systemctl disable offline-yumrepo
systemctl stop offline-yumrepo
rm -f /usr/lib/systemd/system/offline-yumrepo.service
