#!/bin/bash
THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source ${THIS_SCRIPT_DIR}/board_env.sh
if [ $? -ne 0 ]
then
    exit 1
fi

ATF_TAG=2fcd408bb3a6756767a43c073c597cef06e7f2d5
OPTEE_TAG=8e74d47616a20eaa23ca692f4bbbf917a236ed94

: ${PSDK_TOOLS_PATH:=${HOME}/ti}
: ${skip_atf_optee:=0}
: ${pc_emulation=0}

# core secdev check ( This is used to sign the firmware when using HS devices )
echo "[core secdev] Checking ..."
if [ ! -d ./core-secdev-k3 ]
then
    git clone git://git.ti.com/security-development-tools/core-secdev-k3.git
fi
if [ ! -d ./core-secdev-k3 ]
then
    echo "ERROR: Could not clone git://git.ti.com/security-development-tools/core-secdev-k3.git"
fi
echo "[core secdev] Checking ... Done"

if [ $skip_atf_optee -eq 0 ]
then
    # ATF check ( This is only used by RTOS SBL today "make sbl_atf_optee" )
    echo "[ATF] Checking ..."
    if [ ! -d ./trusted-firmware-a ]
    then
        git clone https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git
    fi
    if [ ! -d ./trusted-firmware-a ]
    then
        echo "ERROR: Could not clone https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git"
    else
        cd trusted-firmware-a
        git fetch origin
        git checkout $ATF_TAG
        git describe
        cd ..
    fi
    echo "[ATF] Checking ... Done"

    # OPTEE check ( This is only used by RTOS SBL today "make sbl_atf_optee" )
    echo "[OPTEE] Checking ..."
    if [ ! -d ./optee_os ]
    then
        git clone https://github.com/OP-TEE/optee_os.git
    fi
    if [ ! -d ./optee_os ]
    then
        echo "ERROR: Could not clone https://github.com/OP-TEE/optee_os.git"
    else
        cd optee_os
        git fetch origin
        git checkout $OPTEE_TAG
        git describe
        cd ..
    fi
    echo "[OPTEE] Checking ... Done"
fi

echo "[opkg-utils] Checking ..." # opkg is needed for running rule in vision_apps: make ipk
if [ ! -d opkg-utils-master ]
then
    wget https://git.yoctoproject.org/cgit/cgit.cgi/opkg-utils/snapshot/opkg-utils-master.tar.gz --no-check-certificate
    tar -xf opkg-utils-master.tar.gz
    rm opkg-utils-master.tar.gz
fi
echo "[opkg-utils] Done"

# If we are needing to support PC emulation mode
if [ $pc_emulation -eq 1 ]
then
    echo "[glm] Checking ..." # GLM needed for SRV PC emulation demo
    if [ ! -d glm ]
    then
        wget https://github.com/g-truc/glm/releases/download/0.9.8.0/glm-0.9.8.0.zip --no-check-certificate
        unzip glm-0.9.8.0.zip > /dev/null
        rm glm-0.9.8.0.zip
    fi
    echo "[glm] Done"
fi
