#!/bin/bash
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${THIS_SCRIPT_DIR}/board_env.sh
if [ $? -ne 0 ]
then
    exit 1
fi

# Specify outside of the script if necessary
: ${PSDK_TOOLS_PATH:=${HOME}/ti}
: ${firmware_only:=0}

# # Call makefile to import component versions from PDK Rules.make.  Environment
# # setup is stored for debug purposes.
# THIS_DIR=$(dirname $(realpath $0))
# make --no-print-directory -C ${THIS_DIR} SOC=${SOC} BOARD=${SOC}_evm get_component_versions > .component_versions_${SOC}_env
# cat .component_versions_${SOC}_env
# source .component_versions_${SOC}_env

CGT_ARMLLVM_VERSION_WEB=$(echo ${CGT_ARMLLVM_VERSION} | sed -r 's:\.:_:g')
PROTOBUF_VERSION=3.11.3
OPENCV_VERSION=4.1.0
FLATBUFF_VERSION=1.12.0
TVM_VERSION=9.0.0
GCC_ARCH64_LINUX_VERSION=11.3.rel1

#==> Update as by checking by checking <SDK_BUILD_WORKAREA>/pdk/packages/ti/build/pdk_tools_path.mk
GCC_ARCH64_VERSION=9.2-2019.12

# Create ${PSDK_TOOLS_PATH} folder if not present
if [ ! -d ${PSDK_TOOLS_PATH} ]
then
    echo "Creating ${PSDK_TOOLS_PATH} folder"
    mkdir -p ${PSDK_TOOLS_PATH}
fi

echo "[gcc-arm-${GCC_ARCH64_VERSION}-x86_64-aarch64-none-elf] Checking ..."
if [ ! -d ${PSDK_TOOLS_PATH}/gcc-arm-${GCC_ARCH64_VERSION}-x86_64-aarch64-none-elf ]
then
    wget https://developer.arm.com/-/media/Files/downloads/gnu-a/${GCC_ARCH64_VERSION}/binrel/gcc-arm-${GCC_ARCH64_VERSION}-x86_64-aarch64-none-elf.tar.xz -P ${PSDK_TOOLS_PATH} --no-check-certificate
    tar xf ${PSDK_TOOLS_PATH}/gcc-arm-${GCC_ARCH64_VERSION}-x86_64-aarch64-none-elf.tar.xz -C ${PSDK_TOOLS_PATH} > /dev/null
    rm ${PSDK_TOOLS_PATH}/gcc-arm-${GCC_ARCH64_VERSION}-x86_64-aarch64-none-elf.tar.xz
fi
echo "[gcc-arm-${GCC_ARCH64_VERSION}-x86_64-aarch64-none-elf] Done"

echo "[arm-gnu-toolchain-${GCC_ARCH64_LINUX_VERSION}-x86_64-aarch64-none-linux-gnu] Checking ..."
if [ ! -d ${PSDK_TOOLS_PATH}/arm-gnu-toolchain-${GCC_ARCH64_LINUX_VERSION}-x86_64-aarch64-none-linux-gnu ]
then
    wget https://developer.arm.com/-/media/Files/downloads/gnu/${GCC_ARCH64_LINUX_VERSION}/binrel/arm-gnu-toolchain-${GCC_ARCH64_LINUX_VERSION}-x86_64-aarch64-none-linux-gnu.tar.xz -P ${PSDK_TOOLS_PATH} --no-check-certificate
    tar xf ${PSDK_TOOLS_PATH}/arm-gnu-toolchain-${GCC_ARCH64_LINUX_VERSION}-x86_64-aarch64-none-linux-gnu.tar.xz -C ${PSDK_TOOLS_PATH} > /dev/null
    rm ${PSDK_TOOLS_PATH}/arm-gnu-toolchain-${GCC_ARCH64_LINUX_VERSION}-x86_64-aarch64-none-linux-gnu.tar.xz
fi
echo "[arm-gnu-toolchain-${GCC_ARCH64_LINUX_VERSION}-x86_64-aarch64-none-linux-gnu] Done"

echo "[gcc-arm-${GCC_ARCH64_VERSION}-x86_64-arm-none-linux-gnueabihf] Checking ..."
if [ ! -d ${PSDK_TOOLS_PATH}/gcc-arm-${GCC_ARCH64_VERSION}-x86_64-arm-none-linux-gnueabihf ]
then
    wget https://developer.arm.com/-/media/Files/downloads/gnu-a/${GCC_ARCH64_VERSION}/binrel/gcc-arm-${GCC_ARCH64_VERSION}-x86_64-arm-none-linux-gnueabihf.tar.xz -P ${PSDK_TOOLS_PATH} --no-check-certificate
    tar xf ${PSDK_TOOLS_PATH}/gcc-arm-${GCC_ARCH64_VERSION}-x86_64-arm-none-linux-gnueabihf.tar.xz -C ${PSDK_TOOLS_PATH} > /dev/null
    rm ${PSDK_TOOLS_PATH}/gcc-arm-${GCC_ARCH64_VERSION}-x86_64-arm-none-linux-gnueabihf.tar.xz
fi
echo "[gcc-arm-${GCC_ARCH64_VERSION}-x86_64-arm-none-linux-gnueabihf] Done"
