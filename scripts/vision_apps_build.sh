#!/bin/bash
set -e
if [ -z "$SOC" ]; then
    echo "Error: SOC should be defined as an env variable."
    exit 1
fi
if [ -z "$BASE_IMAGE" ]; then
    echo "Error: BASE_IMAGE should be defined as an env variable."
    exit 1
fi

# build
GCC_LINUX_ARM_ROOT=/usr CROSS_COMPILE_LINARO= LINUX_SYSROOT_ARM=/ LINUX_FS_PATH=/ TREAT_WARNINGS_AS_ERROR=0 make yocto_build

# package
PKG_DIST=${BASE_IMAGE//:/} TIDL_PATH=/opt/psdk-rtos/workarea/tidl_j7 make deb_package
