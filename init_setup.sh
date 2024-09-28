#!/bin/bash
set -e
SCRIPT_DIR=$PWD

# archtecture of the host machine
HOST_ARCH=$(arch)

# archtecture for the Docker container
# ARCH: arm64 or amd64
: "${ARCH:=arm64}"
: "${BASE_IMAGE:=ubuntu:22.04}"

: "${SOC:=j721e}"
TISDK_IMAGE=edgeai
WORKAREA=$SCRIPT_DIR/workarea

# pull the source repos
# https://git.ti.com/cgit/processor-sdk/psdk_repo_manifests/refs/?h=main
: "${REPO_TAG:=REL.PSDK.ANALYTICS.10.00.00.04}"

# targetfs and rootfs info
# http://edgeaisrv2.dhcp.ti.com/publish/prod/PROCESSOR-SDK-LINUX-${DEVICE_NAME}/
: "${PSDK_LINUX_VERSION:=10_00_00_08}"

# define a function to save selected environment variables
save_env_vars() {
    output_file="sdk_variables.txt"
    env_vars=(
        "ARCH" "BASE_IMAGE" "REPO_TAG" "PSDK_LINUX_VERSION"
        # "SOC" "DEVICE_NAME" "DEVICE_PLATFORM"
        # "PSDK_LINUX_ROOTFS" "PSDK_LINUX_BOOTFS" "PSDK_LINUX_WEBLINK"
    )
    for var in "${env_vars[@]}"; do
        echo "$var=${!var}" >> $output_file
    done
    echo "Selected environment variables have been saved to $output_file"
}

# define a function to copy a file and backup the original if it exists
copy_and_backup() {
    src_file=$1
    dest_file=$2
    if [ -f "$dest_file" ]; then
        mv $dest_file $dest_file.ORG
    fi
    cp $src_file $dest_file
}

download_targetfs() {
    DEVICE_PLATFORM=${SOC}
    if [ "${SOC}" == "j721e" ]; then
        DEVICE_NAME=TDA4VM
    elif [ "${SOC}" == "j721s2" ]; then
        DEVICE_NAME=AM68A
    elif [ "${SOC}" == "j722s" ]; then
        DEVICE_NAME=AM67A
    elif [ "${SOC}" == "j784s4" ]; then
        DEVICE_NAME=AM69A
    elif [ "${SOC}" == "am62a" ]; then
        DEVICE_NAME=AM62A
        DEVICE_PLATFORM="am62axx"
    fi

    PSDK_LINUX_ROOTFS=tisdk-${TISDK_IMAGE}-image-${DEVICE_PLATFORM}-evm.tar.xz
    PSDK_LINUX_BOOTFS=boot-${TISDK_IMAGE}-${DEVICE_PLATFORM}-evm.tar.gz
    PSDK_LINUX_WEBLINK=http://edgeaisrv2.dhcp.ti.com/publish/prod/PROCESSOR-SDK-LINUX-${DEVICE_NAME}/${PSDK_LINUX_VERSION}/exports

    cd $WORKAREA
    echo "[psdk linux ${PSDK_LINUX_ROOTFS}] Checking ..."
    if [ ! -d targetfs ]; then
        curl -O ${PSDK_LINUX_WEBLINK}/${PSDK_LINUX_ROOTFS}
        if [ -f ${PSDK_LINUX_ROOTFS} ]; then
            echo "[psdk linux ${PSDK_LINUX_ROOTFS}] Installing files ..."
            mkdir -p targetfs
            tar xf ${PSDK_LINUX_ROOTFS} -C targetfs/
            rm ${PSDK_LINUX_ROOTFS}
        fi
    fi
    echo "[psdk linux ${PSDK_LINUX_ROOTFS}] Done "
}

download_rootfs() {
    cd $WORKAREA
    echo "[psdk linux ${PSDK_LINUX_BOOTFS}] Checking ... "
    if [ ! -d bootfs ]; then
        curl -O ${PSDK_LINUX_WEBLINK}/${PSDK_LINUX_BOOTFS}
        if [ -f ${PSDK_LINUX_BOOTFS} ]; then
            echo "[psdk linux ${PSDK_LINUX_BOOTFS}] Installing files ..."
            mkdir -p bootfs
            tar xf ${PSDK_LINUX_BOOTFS} -C bootfs/
            rm ${PSDK_LINUX_BOOTFS}
        fi
    fi
    echo "[psdk linux ${PSDK_LINUX_BOOTFS}] Done "
}

if [ ! -d $WORKAREA ]; then
    mkdir -p $WORKAREA
    cd $WORKAREA

    # save selected environment variables
    save_env_vars

    # repo sync
    repo init -u git://git.ti.com/processor-sdk/psdk_repo_manifests.git -b refs/tags/${REPO_TAG} -m vision_apps_yocto.xml
    repo sync

    # apply fixes/workarounds. Modular scripts from setup_psdk_rtos.sh => TODO
    # Modular scripts prepared for SDK 9.0
    cd $SCRIPT_DIR
    Files=(
        # setup_psdk_rtos.sh
        # setup_tools_apt.sh
        setup_tools_arm.sh # only this is used in this build system
        # setup_tools_cgt.sh
        # setup_tools_misc.sh
    )
    for File in ${Files[@]}; do
        if [ "$ARCH" == "amd64" ]; then
            copy_and_backup patches/sdk_builder/scripts/${File} ${WORKAREA}/sdk_builder/scripts/${File}
        fi
    done
    # remove the 'u' flag for AR to avoid warning messages in aarch64 Ubuntu container
    copy_and_backup patches/sdk_builder/concerto/compilers/gcc_linux_arm.mak ${WORKAREA}/sdk_builder/concerto/compilers/gcc_linux_arm.mak
    # rule for deb packing added (exprimental)
    copy_and_backup patches/sdk_builder/makerules/makefile_ipk.mak ${WORKAREA}/sdk_builder/makerules/makefile_ipk.mak
    # updated yocto_clean malkerule: removed tidl_tiovx_kernels_scrub and scrub (both are for arm-tidl)
    copy_and_backup patches/sdk_builder/makerules/makefile_linux_arm.mak ${WORKAREA}/sdk_builder/makerules/makefile_linux_arm.mak
    # adding /usr/include/libdrm to IDIRS (for Debian container)
    copy_and_backup patches/vision_apps/utils/opengl/src/a72/concerto.mak ${WORKAREA}/vision_apps/utils/opengl/src/a72/concerto.mak
    # add vision_apps_build_all_platforms.sh
    copy_and_backup scripts/vision_apps_build_all_platforms.sh ${WORKAREA}/sdk_builder/vision_apps_build_all_platforms.sh
    # add vision_apps_build_all_platforms.sh
    copy_and_backup scripts/vision_apps_build.sh ${WORKAREA}/sdk_builder/vision_apps_build.sh

    # download and install PSDK Linux target FS and boot image
    if [ "$ARCH" == "amd64" ]; then
        download_targetfs
        download_rootfs
    fi

else
    echo "$WORKAREA already exists."
fi

# Install the ARM compile tools
if [ "$HOST_ARCH" == "x86_64" ] && [ "$ARCH" == "amd64" ]; then
    PSDK_TOOLS_PATH=${SCRIPT_DIR}/psdk-tools
    if [ ! -d $PSDK_TOOLS_PATH ]; then
        mkdir -p $PSDK_TOOLS_PATH
        cd $WORKAREA
        PSDK_TOOLS_PATH=${PSDK_TOOLS_PATH} SOC=${SOC} TISDK_IMAGE=${TISDK_IMAGE} ./sdk_builder/scripts/setup_tools_arm.sh
    else
        echo "$PSDK_TOOLS_PATH already exists."
    fi
fi
cd $SCRIPT_DIR
