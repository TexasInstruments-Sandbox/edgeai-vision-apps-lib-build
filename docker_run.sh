#!/bin/bash

# ARCH: arm64
ARCH=arm64

# base image: ubuntu:22.04, ubuntu20.04, debian:12.5, ...
: "${BASE_IMAGE:=ubuntu:22.04}"

# SDK version
: "${SDK_VER:=10.1.0}"

# docker tag
DOCKER_TAG=vision-apps-builder:${SDK_VER}-${ARCH}-${BASE_IMAGE//:/}
echo "DOCKER_TAG = $DOCKER_TAG"

# target SOC
: "${SOC:=j784s4}"

if [ "$#" -lt 1 ]; then
    CMD=/bin/bash
else
    CMD="$@"
fi

# validate ARCH
if [ "$ARCH" != "arm64" ]; then
    echo "Error: ARCH must be 'arm64'. Current ARCH = $ARCH"
    exit 1
fi

docker run -it --rm \
    -v ${PWD}/workarea:/opt/psdk-rtos/workarea \
    -v ${PWD}/patches/targetfs:/opt/psdk-rtos/patches/targetfs \
    --privileged \
    --network host \
    --env USE_PROXY=$USE_PROXY \
    --env ARCH=$ARCH \
    --env BASE_IMAGE=$BASE_IMAGE \
    --env SOC=$SOC \
      $DOCKER_TAG $CMD
