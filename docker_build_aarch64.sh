#!/bin/bash
: "${USE_PROXY:=0}"
: "${SOC:=j721e}"
TISDK_IMAGE=edgeai
ARCH=aarch64
SDK_VER=9.0.0
DOCKER_TAG=psdk-rtos-builder-${TISDK_IMAGE}-${SOC}-${ARCH}:$SDK_VER

set -e
# modify the server and proxy URLs as requied
if [ "${USE_PROXY}" -ne "0" ]; then
    REPO_LOCATION=
    HTTP_PROXY=http://webproxy.ext.ti.com:80
else
    REPO_LOCATION=
fi
echo "USE_PROXY = $USE_PROXY"
echo "REPO_LOCATION = $REPO_LOCATION"

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
    --build-arg USE_PROXY=$USE_PROXY \
    --build-arg REPO_LOCATION=$REPO_LOCATION \
    --build-arg HTTP_PROXY=$HTTP_PROXY \
    --build-arg SOC=$SOC \
    --progress=plain \
    -f Dockerfile.${ARCH} $DST_DIR
echo "Docker build -t $DOCKER_TAG completed!"
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
# rm -rf $DST_DIR