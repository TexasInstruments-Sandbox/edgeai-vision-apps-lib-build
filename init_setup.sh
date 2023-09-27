#!/bin/bash
SCRIPT_DIR=$PWD

: "${SOC:=j721e}"
TISDK_IMAGE=edgeai
WORKAREA=$SCRIPT_DIR/${SOC}-workarea

# pull the source repos
REPO_TAG=REL.PSDK.ANALYTICS.09.00.00.01
PDK_TAG=REL.PSDK.09.00.00.45
PSDKL_VER=09.00.00.08
# below seems changing in each release
if [ "$TISDK_IMAGE" == "edgeai" ]; then
    URL_TAG=MD-4K6R4tqhZI
else
    echo "URL_TAG noe defined for TISDK_IMAGE=$TISDK_IMAGE"
fi

if [ ! -d $WORKAREA ]; then
    mkdir -p $WORKAREA
    cd $WORKAREA
    repo init -u git://git.ti.com/processor-sdk/psdk_repo_manifests.git -b refs/tags/${REPO_TAG} -m vision_apps_yocto.xml
    repo sync

    # pull PDK repo => TODO
    git clone --single-branch --branch ${PDK_TAG} git://git.ti.com/processor-sdk/pdk.git pdk

    # apply fixes to setup_psdk_rtos.sh => TODO
    cd $SCRIPT_DIR
    cp patches/sdk_builder/makerules/makefile_linux_arm.mak ${WORKAREA}/sdk_builder/makerules/makefile_linux_arm.mak
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

    # download and install PSDK Linux target FS and boot image
    # edgeai: https://www.ti.com/tool/download/PROCESSOR-SDK-LINUX-SK-TDA4VM/09.00.00.08
    PSDK_LINUX_ROOTFS=tisdk-${TISDK_IMAGE}-image-${SOC}-evm.tar.xz
    PSDK_LINUX_BOOTFS=boot-${TISDK_IMAGE}-${SOC}-evm.tar.gz
    URL_HEAD=https://dr-download.ti.com/software-development/software-development-kit-sdk

    cd $WORKAREA
    echo "[psdk linux ${PSDK_LINUX_ROOTFS}] Checking ..."
    if [ ! -d targetfs ]; then
        wget ${URL_HEAD}/${URL_TAG}/${PSDKL_VER}/${PSDK_LINUX_ROOTFS}
        if [ -f ${PSDK_LINUX_ROOTFS} ]; then
            echo "[psdk linux ${PSDK_LINUX_ROOTFS}] Installing files ..."
            mkdir targetfs
            tar xf ${PSDK_LINUX_ROOTFS} -C targetfs/
            rm ${PSDK_LINUX_ROOTFS}
        fi
    fi
    echo "[psdk linux ${PSDK_LINUX_ROOTFS}] Done "

    echo "[psdk linux ${PSDK_LINUX_BOOTFS}] Checking ... "
    if [ ! -d bootfs ]; then
        wget ${URL_HEAD}/${URL_TAG}/${PSDKL_VER}/${PSDK_LINUX_BOOTFS}
        if [ -f ${PSDK_LINUX_BOOTFS} ]; then
            echo "[psdk linux ${PSDK_LINUX_BOOTFS}] Installing files ..."
            mkdir bootfs
            tar xf ${PSDK_LINUX_BOOTFS} -C bootfs/
            rm ${PSDK_LINUX_BOOTFS}
        fi
    fi
    echo "[psdk linux ${PSDK_LINUX_BOOTFS}] Done "

else
    echo "$WORKAREA already exists."
fi

ARCH=`arch`
if [ "$ARCH" == "x86_64" ]; then
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
