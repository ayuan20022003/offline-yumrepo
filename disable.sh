#!/bin/bash
set -ex

systemctl disable offline-yumrepo
systemctl stop offline-yumrepo
rm -f /usr/lib/systemd/system/offline-yumrepo.service
