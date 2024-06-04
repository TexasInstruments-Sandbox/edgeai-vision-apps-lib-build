#!/bin/bash

# ARCH: amd64, arm64
: "${ARCH:=arm64}"

# base image: ubuntu:22.04, ubuntu20.04, debian:12.5, ...
: "${BASE_IMAGE:=ubuntu:22.04}"

# SDK version
SDK_VER=9.2.0

# docker tag
DOCKER_TAG=vision-apps-builder:${SDK_VER}-${ARCH}-${BASE_IMAGE//:/}
echo "DOCKER_TAG = $DOCKER_TAG"

if [ "$#" -lt 1 ]; then
    CMD=/bin/bash
else
    CMD="$@"
fi

if [ "$ARCH" == "amd64" ]; then
docker run -it --rm \
    -v ${PWD}/workarea:/opt/psdk-rtos/workarea \
    -v ${PWD}/psdk-tools:/root/ti \
    --privileged \
    --network host \
    --env USE_PROXY=$USE_PROXY \
    --env BASE_IMAGE=$BASE_IMAGE \
    $DOCKER_TAG $CMD
fi

if [ "$ARCH" == "arm64" ]; then
docker run -it --rm \
    -v ${PWD}/workarea:/opt/psdk-rtos/workarea \
    -v ${PWD}/patches/targetfs:/opt/psdk-rtos/patches/targetfs \
    --privileged \
    --network host \
    --env USE_PROXY=$USE_PROXY \
    --env ARCH=$ARCH \
    --env BASE_IMAGE=$BASE_IMAGE \
      $DOCKER_TAG $CMD
fi
