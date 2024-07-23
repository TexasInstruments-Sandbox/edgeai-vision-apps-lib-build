#!/bin/bash
set -e

# ARCH: amd64, arm64
: "${ARCH:=arm64}"

# base image: ubuntu:22.04, ubuntu20.04, debian:12.5, ...
: "${BASE_IMAGE:=ubuntu:22.04}"

# SDK version
SDK_VER=10.0.0

# docker tag
DOCKER_TAG=vision-apps-builder:${SDK_VER}-${ARCH}-${BASE_IMAGE//:/}
echo "DOCKER_TAG = $DOCKER_TAG"

if [ "$ARCH" == "arm64" ]; then
    BASE_IMAGE="arm64v8/${BASE_IMAGE}"
fi
echo "BASE_IMAGE = $BASE_IMAGE"

# for TI proxy network settings
: "${USE_PROXY:=0}"

# modify the server and proxy URLs as requied
if [ "${USE_PROXY}" -ne "0" ]; then
    HTTP_PROXY=http://webproxy.ext.ti.com:80
fi
echo "USE_PROXY = $USE_PROXY"

# copy files to be added while docker-build
# requirement: git-pull edgeai-ti-proxy repo and source edgeai-ti-proxy/setup_proxy.sh
DST_DIR=.
mkdir -p $DST_DIR/proxy
PROXY_DIR=$HOME/proxy
if [ "`arch`" == "aarch64" ]; then
    PROXY_DIR=/opt/proxy
fi
if [ -d "$PROXY_DIR" ]; then
    cp -rp $PROXY_DIR/* ${DST_DIR}/proxy
fi

# docker-build
SECONDS=0
docker build \
    -t $DOCKER_TAG \
    --build-arg ARCH=$ARCH \
    --build-arg BASE_IMAGE=$BASE_IMAGE \
    --build-arg USE_PROXY=$USE_PROXY \
    --build-arg HTTP_PROXY=$HTTP_PROXY \
    -f Dockerfile $DST_DIR
echo "Docker build -t $DOCKER_TAG completed!"
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

rm -rf ${DST_DIR}/proxy
# rm ${DST_DIR}/setup_tools_apt.sh
