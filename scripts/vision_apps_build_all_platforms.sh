#!/bin/bash
set -e
current_dir=$(pwd)

distro="ubuntu22.04"
platforms=(
    j784s4
    j721s2
    j721e
    j722s
    am62a
)

cd $WORK_DIR/workarea/sdk_builder

# iterate over the platforms
for platform in ${platforms[@]}; do

    echo "Building for $platform ..."

    # clean up (to clean up any residual)
    SOC=$platform make yocto_clean

    # build
    SOC=$platform GCC_LINUX_ARM_ROOT=/usr CROSS_COMPILE_LINARO= LINUX_SYSROOT_ARM=/ LINUX_FS_PATH=/ TREAT_WARNINGS_AS_ERROR=0 make yocto_build

    # package
    SOC=$platform PKG_DIST=$distro TIDL_PATH=/opt/psdk-rtos/workarea/tidl_j7 make deb_package

    # clean up
    SOC=$platform make yocto_clean

done

# chmod
chmod -R a+w $WORK_DIR/workarea

cd $current_dir
