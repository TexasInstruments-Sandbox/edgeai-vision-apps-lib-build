#!/bin/bash
set -e

# setup proxy as required
source /root/setup_proxy.sh

# arch
echo "$(arch)"

# Linux distro version
DISTRO_VER=$(lsb_release -r | cut -f2)
echo "DISTRO_VER=${DISTRO_VER}"
echo "$BASE_IMAGE"

# workaround: copy headers from targetfs
# TODO: eleminate this step
if [ "${ARCH}" == "arm64" ]; then
    cd /opt/psdk-rtos/patches
    # install libglm-dev, libdrm-dev in the Dockerfile
    # cp -r targetfs/usr/include/KHR/ /usr/include
    # cp -r targetfs/usr/include/glm/ /usr/include
    # cp targetfs/usr/include/xf86drm.h /usr/include
    cp targetfs/usr/include/linux/dma-heap.h /usr/include/linux
    echo "Some headers copied from targetfs."
fi

# working dir
cd $WORK_DIR/workarea/sdk_builder

exec "$@"
