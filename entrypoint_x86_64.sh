#!/bin/bash
set -e

# setup proxy as required
source /root/setup_proxy.sh

# Ubuntu version
UBUNTU_VER=$(lsb_release -r | cut -f2)
echo "Ubuntu $UBUNTU_VER"

# working dir
cd /opt/psdk-rtos/${SOC}-workarea

exec "$@"
