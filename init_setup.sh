#!/bin/bash
SCRIPT_DIR=$PWD

: "${SOC:=j721e}"
TISDK_IMAGE=edgeai
WORKAREA=$SCRIPT_DIR/${SOC}-workarea

# pull the source repos
# https://git.ti.com/cgit/processor-sdk/psdk_repo_manifests/refs/?h=main
REPO_TAG=REL.PSDK.ANALYTICS.09.00.01.01
# PDK_TAG=REL.PSDK.09.00.00.45

# targetfs and rootfs info
# http://edgeaisrv2.dhcp.ti.com/publish/prod/PROCESSOR-SDK-LINUX-${DEVICE_NAME}/
PSDK_LINUX_VERSION=09_00_01_03

DEVICE_PLATFORM=${SOC}
if [ ${SOC} = "j721e" ]; then
    DEVICE_NAME=TDA4VM
elif [ ${SOC} = "j721s2" ]; then
    DEVICE_NAME=AM68A
elif [ ${SOC} = "j722s" ]; then
    DEVICE_NAME=AM67A
elif [ ${SOC} = "j784s4" ]; then
    DEVICE_NAME=AM69A
elif [ ${SOC} = "am62a" ]; then
    DEVICE_NAME=AM62A
    DEVICE_PLATFORM="am62axx"
fi

PSDK_LINUX_ROOTFS=tisdk-${TISDK_IMAGE}-image-${DEVICE_PLATFORM}-evm.tar.xz
PSDK_LINUX_BOOTFS=boot-${TISDK_IMAGE}-${DEVICE_PLATFORM}-evm.tar.gz
PSDK_LINUX_WEBLINK=http://edgeaisrv2.dhcp.ti.com/publish/prod/PROCESSOR-SDK-LINUX-${DEVICE_NAME}/${PSDK_LINUX_VERSION}/exports

if [ ! -d $WORKAREA ]; then
    mkdir -p $WORKAREA
    cd $WORKAREA
    repo init -u git://git.ti.com/processor-sdk/psdk_repo_manifests.git -b refs/tags/${REPO_TAG} -m vision_apps_yocto.xml
    repo sync

    # pull PDK repo: only required to set env variables
    # git clone --single-branch --branch ${PDK_TAG} git://git.ti.com/processor-sdk/pdk.git pdk

    # apply fixes/workarounds. Modular scripts from setup_psdk_rtos.sh => TODO
    cd $SCRIPT_DIR
    cp patches/sdk_builder/concerto/compilers/gcc_linux_arm.mak ${WORKAREA}/sdk_builder/concerto/compilers/gcc_linux_arm.mak
    Files=(
        setup_psdk_rtos.sh
        setup_tools_apt.sh
        setup_tools_arm.sh
        setup_tools_cgt.sh
        setup_tools_misc.sh
    )
    for File in ${Files[@]}; do
	    cp patches/sdk_builder/scripts/${File} ${WORKAREA}/sdk_builder/scripts/${File}
    done
    # remove the 'u' flag for AR to avoid warning messages in aarch64 Ubuntu container
    cp patches/sdk_builder/concerto/compilers/gcc_linux_arm.mak ${WORKAREA}/sdk_builder/concerto/compilers/gcc_linux_arm.mak

    # download and install PSDK Linux target FS and boot image
    cd $WORKAREA
    echo "[psdk linux ${PSDK_LINUX_ROOTFS}] Checking ..."
    if [ ! -d targetfs ]; then
        wget ${PSDK_LINUX_WEBLINK}/${PSDK_LINUX_ROOTFS}
        if [ -f ${PSDK_LINUX_ROOTFS} ]; then
            echo "[psdk linux ${PSDK_LINUX_ROOTFS}] Installing files ..."
            mkdir -p targetfs
            tar xf ${PSDK_LINUX_ROOTFS} -C targetfs/
            # rm ${PSDK_LINUX_ROOTFS}
        fi
    fi
    echo "[psdk linux ${PSDK_LINUX_ROOTFS}] Done "

    echo "[psdk linux ${PSDK_LINUX_BOOTFS}] Checking ... "
    if [ ! -d bootfs ]; then
        wget ${PSDK_LINUX_WEBLINK}/${PSDK_LINUX_BOOTFS}
        if [ -f ${PSDK_LINUX_BOOTFS} ]; then
            echo "[psdk linux ${PSDK_LINUX_BOOTFS}] Installing files ..."
            mkdir -p bootfs
            tar xf ${PSDK_LINUX_BOOTFS} -C bootfs/
            # rm ${PSDK_LINUX_BOOTFS}
        fi
    fi
    echo "[psdk linux ${PSDK_LINUX_BOOTFS}] Done "

else
    echo "$WORKAREA already exists."
fi

HOST_ARCH=`arch`
if [ "$HOST_ARCH" == "x86_64" ]; then
    # Install the ARM compile tools
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
