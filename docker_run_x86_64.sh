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

xhost +local:$USER
docker run -it --rm \
    -v ./${SOC}-workarea:/opt/psdk-rtos/${SOC}-workarea \
    -v ./psdk-tools:/root/ti \
    --privileged \
    --network host \
    --env USE_PROXY=$USE_PROXY \
    --env SOC=$SOC \
    --env TISDK_IMAGE=$TISDK_IMAGE \
    --gpus all \
    --env=NVIDIA_VISIBLE_DEVICES=all \
    --env=NVIDIA_DRIVER_CAPABILITIES=all \
    --env='DISPLAY' \
    --env='QT_X11_NO_MITSHM=1' \
    --volume='/tmp/.X11-unix:/tmp/.X11-unix:rw' \
      $DOCKER_TAG $CMD
xhost -local:$USER
