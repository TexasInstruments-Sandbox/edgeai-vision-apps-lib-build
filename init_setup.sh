#!/bin/bash
# NOTE: REPO_TAG and PSDK_LINUX_VERSION should be updated for each release

SCRIPT_DIR=$PWD

# archtecture for the Docker container
# ARCH: arm64
ARCH=arm64

# base image for the target Docker container
: "${BASE_IMAGE:=ubuntu:22.04}"

: "${SOC:=j721e}"
WORKAREA=$SCRIPT_DIR/workarea

# pull the source repos
# https://git.ti.com/cgit/processor-sdk/psdk_repo_manifests/refs/?h=main
: "${REPO_TAG:=REL.PSDK.ANALYTICS.10.01.00.02}"

# targetfs and rootfs info
# http://edgeaisrv2.dhcp.ti.com/publish/prod/PROCESSOR-SDK-LINUX-${DEVICE_NAME}/${PSDK_LINUX_VERSION}
# E.g.: http://edgeaisrv2.dhcp.ti.com/publish/prod/PROCESSOR-SDK-LINUX-AM69A/10_01_00_02
: "${PSDK_LINUX_VERSION:=10_01_00_02}"

# validate ARCH
if [ "$ARCH" != "arm64" ]; then
    echo "Error: ARCH must be 'arm64'. Current ARCH = $ARCH"
    exit 1
fi

# define a function to save selected environment variables
save_env_vars() {
    output_file="sdk_variables.txt"
    env_vars=(
        "ARCH" "BASE_IMAGE" "REPO_TAG" "PSDK_LINUX_VERSION"
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

if [ ! -d $WORKAREA ]; then
    mkdir -p $WORKAREA
    cd $WORKAREA

    # save selected environment variables
    save_env_vars

    # repo sync
    repo init -u git://git.ti.com/processor-sdk/psdk_repo_manifests.git -b refs/tags/${REPO_TAG} -m vision_apps_yocto.xml
    repo sync

    cd $SCRIPT_DIR
    # add vision_apps_build_all_platforms.sh
    copy_and_backup scripts/vision_apps_build_all_platforms.sh ${WORKAREA}/sdk_builder/vision_apps_build_all_platforms.sh
    # add vision_apps_build_all_platforms.sh
    copy_and_backup scripts/vision_apps_build.sh ${WORKAREA}/sdk_builder/vision_apps_build.sh

else
    echo "$WORKAREA already exists."
fi

cd $SCRIPT_DIR
