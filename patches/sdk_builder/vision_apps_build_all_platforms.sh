#!/bin/bash

distro="ubuntu22.04"
platforms=(
    j784s4
    j721s2
    j721e
    j722s
    am62a
)

# iterate over the platforms
for platform in ${platforms[@]}; do

    echo "Building for $platform ..."

    # clean up (to clean up any residual)
    SOC=$platform make yocto_clean

    # build
    SOC=$platform GCC_LINUX_ARM_ROOT=/usr CROSS_COMPILE_LINARO= LINUX_SYSROOT_ARM=/ LINUX_FS_PATH=/ TREAT_WARNINGS_AS_ERROR=0 make yocto_build

    # package
    SOC=$platform PKG_DIST=$distro make deb_package

    # clean up
    SOC=$platform make yocto_clean

done
