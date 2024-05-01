#!/bin/bash
# ARCH: amd64 (for x86_64) or arm64 (for aarch64)
: "${ARCH:=amd64}"
# Ubuntu version: 20.04 or 22.04
: "${UBUNTU_VER:=22.04}"

: "${USE_PROXY:=0}"
: "${SOC:=j721e}"
SDK_VER=9.2.0

DOCKER_TAG=lib-builder-${SDK_VER}:${ARCH}-${UBUNTU_VER}-${SOC}
echo "DOCKER_TAG = $DOCKER_TAG"

if [ "$#" -lt 1 ]; then
    CMD=/bin/bash
else
    CMD="$@"
fi

if [ "$ARCH" == "amd64" ]; then
docker run -it --rm \
    -v ${PWD}/${SOC}-workarea:/opt/psdk-rtos/${SOC}-workarea \
    -v ${PWD}/psdk-tools:/root/ti \
    --privileged \
    --network host \
    --env USE_PROXY=$USE_PROXY \
    --env SOC=$SOC \
    $DOCKER_TAG $CMD
fi

if [ "$ARCH" == "arm64" ]; then
docker run -it --rm \
    -v ${PWD}/${SOC}-workarea:/opt/psdk-rtos/${SOC}-workarea \
    -v ${PWD}/patches/targetfs:/opt/psdk-rtos/patches/targetfs \
    --privileged \
    --network host \
    --env USE_PROXY=$USE_PROXY \
    --env SOC=$SOC \
    --env ARCH=$ARCH \
      $DOCKER_TAG $CMD
fi