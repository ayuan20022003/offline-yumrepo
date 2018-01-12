#!/bin/bash
set -ex

cp offline-yumrepo.service /usr/lib/systemd/system/
systemctl enable offline-yumrepo
systemctl start offline-yumrepo
