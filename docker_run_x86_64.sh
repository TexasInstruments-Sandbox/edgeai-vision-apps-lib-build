#!/bin/bash
: "${USE_PROXY:=0}"
: "${SOC:=j721e}"
TISDK_IMAGE=edgeai
ARCH=x86_64
SDK_VER=9.0.0
DOCKER_TAG=psdk-rtos-builder-${TISDK_IMAGE}-${SOC}-${ARCH}:$SDK_VER
if [ "$#" -lt 1 ]; then
    CMD=/bin/bash
else
    CMD="$@"
fi

docker run -it --rm \
    -v ${PWD}/${SOC}-workarea:/opt/psdk-rtos/${SOC}-workarea \
    -v ${PWD}/psdk-tools:/root/ti \
    --privileged \
    --network host \
    --env USE_PROXY=$USE_PROXY \
    --env SOC=$SOC \
    --env TISDK_IMAGE=$TISDK_IMAGE \
      $DOCKER_TAG $CMD
