#!/bin/bash
set -e

# setup proxy as required
source /root/setup_proxy.sh

# arch
echo "`arch`"

# Ubuntu version
UBUNTU_VER=$(lsb_release -r | cut -f2)
echo "Ubuntu $UBUNTU_VER"

# copy headers from targetfs
# TODO: how to eleminate this step
if [ "${ARCH}" == "arm64" ]; then
    cd /opt/psdk-rtos/${SOC}-workarea
    cp -r targetfs/usr/include/KHR/ /usr/include
    cp -r targetfs/usr/include/glm/ /usr/include
    cp targetfs/usr/include/xf86drm.h /usr/include
    mkdir -p /usr/include/linux
    cp targetfs/usr/include/linux/dma-heap.h /usr/include/linux
    echo "Some headers copied from targetfs."
fi

# working dir
cd /opt/psdk-rtos/${SOC}-workarea/sdk_builder

exec "$@"
