#!/bin/bash
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${THIS_SCRIPT_DIR}/board_env.sh
if [ $? -ne 0 ]
then
    exit 1
fi

# Specify outside of the script if necessary
: ${PSDK_TOOLS_PATH:=${HOME}/ti}

# Call makefile to import component versions from PDK Rules.make.  Environment
# setup is stored for debug purposes.
THIS_DIR=$(dirname $(realpath $0))
make --no-print-directory -C ${THIS_DIR} SOC=${SOC} BOARD=${SOC}_evm get_component_versions > .component_versions_${SOC}_env
cat .component_versions_${SOC}_env
source .component_versions_${SOC}_env

CGT_ARMLLVM_VERSION_WEB=$(echo ${CGT_ARMLLVM_VERSION} | sed -r 's:\.:_:g')
PROTOBUF_VERSION=3.11.3
OPENCV_VERSION=4.1.0
FLATBUFF_VERSION=1.12.0
TVM_VERSION=9.0.0
GCC_ARCH64_LINUX_VERSION=11.3.rel1

# Create ${PSDK_TOOLS_PATH} folder if not present
if [ ! -d ${PSDK_TOOLS_PATH} ]
then
    echo "Creating ${PSDK_TOOLS_PATH} folder"
    mkdir -p ${PSDK_TOOLS_PATH}
fi

# Install TI ARM LLVM tools for building on R cores
echo "[ti-cgt-armllvm_${CGT_ARMLLVM_VERSION}] Checking ..."
if [ ! -d ${PSDK_TOOLS_PATH}/ti-cgt-armllvm_${CGT_ARMLLVM_VERSION} ]
then
    wget https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-ayxs93eZNN/${CGT_ARMLLVM_VERSION}/ti_cgt_armllvm_${CGT_ARMLLVM_VERSION}_linux-x64_installer.bin -P ${PSDK_TOOLS_PATH} --no-check-certificate
    chmod +x ${PSDK_TOOLS_PATH}/ti_cgt_armllvm_${CGT_ARMLLVM_VERSION}_linux-x64_installer.bin
    ${PSDK_TOOLS_PATH}/ti_cgt_armllvm_${CGT_ARMLLVM_VERSION}_linux-x64_installer.bin --mode unattended --prefix ${PSDK_TOOLS_PATH}
    rm ${PSDK_TOOLS_PATH}/ti_cgt_armllvm_${CGT_ARMLLVM_VERSION}_linux-x64_installer.bin
fi
echo "[ti-cgt-armllvm_${CGT_ARMLLVM_VERSION}] Done"

# Install TI CGT tools for building on C6x DSP cores
if [ ${SOC} = "j721e" ]
then
    echo "[ti-cgt-c6000_${CGT_C6X_VERSION}] Checking ..."
    if [ ! -d ${PSDK_TOOLS_PATH}/ti-cgt-c6000_${CGT_C6X_VERSION} ]
    then
        wget https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-vqU2jj6ibH/${CGT_C6X_VERSION}/ti_cgt_c6000_${CGT_C6X_VERSION}_linux_installer_x86.bin -P ${PSDK_TOOLS_PATH} --no-check-certificate
        chmod +x ${PSDK_TOOLS_PATH}/ti_cgt_c6000_${CGT_C6X_VERSION}_linux_installer_x86.bin
        ${PSDK_TOOLS_PATH}/ti_cgt_c6000_${CGT_C6X_VERSION}_linux_installer_x86.bin --mode unattended --prefix ${PSDK_TOOLS_PATH}
        rm ${PSDK_TOOLS_PATH}/ti_cgt_c6000_${CGT_C6X_VERSION}_linux_installer_x86.bin
    fi
    echo "[ti-cgt-c6000_${CGT_C6X_VERSION}] Done"
fi

# Install TI CGT tools for building on C7x DSP cores
if [ ${SOC} != "j7200" ]
then
    echo "[ti-cgt-c7000_${CGT_C7X_VERSION}] Checking ..."
    if [ ! -d ${PSDK_TOOLS_PATH}/ti-cgt-c7000_${CGT_C7X_VERSION} ]
    then
        wget https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-707zYe3Rik/${CGT_C7X_VERSION}/ti_cgt_c7000_${CGT_C7X_VERSION}_linux-x64_installer.bin -P ${PSDK_TOOLS_PATH} --no-check-certificate
        chmod +x ${PSDK_TOOLS_PATH}/ti_cgt_c7000_${CGT_C7X_VERSION}_linux-x64_installer.bin
        ${PSDK_TOOLS_PATH}/ti_cgt_c7000_${CGT_C7X_VERSION}_linux-x64_installer.bin --mode unattended --prefix ${PSDK_TOOLS_PATH}
        rm ${PSDK_TOOLS_PATH}/ti_cgt_c7000_${CGT_C7X_VERSION}_linux-x64_installer.bin
    fi
    echo "[ti-cgt-c7000_${CGT_C7X_VERSION}] Done"
fi

# Install sysconfig tool for MCU+SDK build
if [ ${SOC} = "am62a" ]
then
    echo "[sysconfig_${SYSCONFIG_VERSION}] Checking ..."
    if [ ! -d ${PSDK_TOOLS_PATH}/sysconfig_${SYSCONFIG_VERSION} ]
    then
        wget https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-nsUM6f7Vvb/${SYSCONFIG_VERSION}.${SYSCONFIG_BUILD}/sysconfig-${SYSCONFIG_VERSION}_${SYSCONFIG_BUILD}-setup.run -P ${PSDK_TOOLS_PATH} --no-check-certificate
        chmod +x ${PSDK_TOOLS_PATH}/sysconfig-${SYSCONFIG_VERSION}_${SYSCONFIG_BUILD}-setup.run
        ${PSDK_TOOLS_PATH}/sysconfig-${SYSCONFIG_VERSION}_${SYSCONFIG_BUILD}-setup.run --mode unattended --prefix ${PSDK_TOOLS_PATH}/sysconfig_${SYSCONFIG_VERSION}
        rm ${PSDK_TOOLS_PATH}/sysconfig-${SYSCONFIG_VERSION}_${SYSCONFIG_BUILD}-setup.run
    fi
    echo "[sysconfig_${SYSCONFIG_VERSION}] Done"
fi
