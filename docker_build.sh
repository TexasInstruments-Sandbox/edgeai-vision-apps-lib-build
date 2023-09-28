#!/bin/bash
# ARCH: amd64 (for x86_64) or arm64 (for aarch64)
: ${ARCH=amd64}
# Ubuntu version: 20.04 or 22.04
: ${UBUNTU_VER=22.04}

: "${USE_PROXY:=0}"
: "${SOC:=j721e}"
SDK_VER=9.0.0

BASE_IMAGE=ubuntu:${UBUNTU_VER}
if [ "$ARCH" == "arm64" ]; then
    BASE_IMAGE="arm64v8/${BASE_IMAGE}"
fi
echo "BASE_IMAGE = $BASE_IMAGE"

UBUNTU_1804=0
if [ "$ARCH" == "18.04" ]; then
    UBUNTU_1804=1
fi
echo "UBUNTU_1804 = $UBUNTU_1804"

DOCKER_TAG=lib-builder-${SDK_VER}:${ARCH}-${UBUNTU_VER}-${SOC}
echo "DOCKER_TAG = $DOCKER_TAG"

set -e
# modify the server and proxy URLs as requied
if [ "${USE_PROXY}" -ne "0" ]; then
    HTTP_PROXY=http://webproxy.ext.ti.com:80
fi
echo "USE_PROXY = $USE_PROXY"

# copy files to be added while docker-build
# requirement: git-pull edgeai-ti-proxy repo and source edgeai-ti-proxy/setup_proxy.sh
DST_DIR=.
cp -p ${SOC}-workarea/sdk_builder/scripts/setup_tools_apt.sh ${DST_DIR}
mkdir -p $DST_DIR/proxy
if [ -d "$HOME/proxy" ]; then
    cp -rp $HOME/proxy/* ${DST_DIR}/proxy
fi

# docker-build
SECONDS=0
DOCKER_BUILDKIT=1 docker build \
    -t $DOCKER_TAG \
    --build-arg ARCH=$ARCH \
    --build-arg BASE_IMAGE=$BASE_IMAGE \
    --build-arg USE_PROXY=$USE_PROXY \
    --build-arg HTTP_PROXY=$HTTP_PROXY \
    --build-arg SOC=$SOC \
    --build-arg UBUNTU_1804=$UBUNTU_1804 \
    --progress=plain \
    -f Dockerfile $DST_DIR
echo "Docker build -t $DOCKER_TAG completed!"
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
# rm -rf $DST_DIR