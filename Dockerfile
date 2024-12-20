ARG ARCH
ARG BASE_IMAGE
ARG USE_PROXY
ARG HTTP_PROXY
ARG RPMSG_VER
ARG DEBIAN_FRONTEND=noninteractive

#=========================================================================
FROM --platform=linux/${ARCH} ${BASE_IMAGE} AS base-0

#=========================================================================
FROM base-0 AS base-1
ARG USE_PROXY
ENV USE_PROXY=${USE_PROXY}
ARG HTTP_PROXY
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTP_PROXY}

#=========================================================================
FROM base-${USE_PROXY}
ARG ARCH
ARG BASE_IMAGE
ARG RPMSG_VER
ARG DEBIAN_FRONTEND
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# setup proxy settings
ADD setup_proxy.sh /root/
ADD proxy /root/proxy
RUN /root/setup_proxy.sh

# intsall utils and miscellaneous packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    vim \
    tmux \
    gdb \
    iputils-ping \
    rsync \
    strace \
    sysstat \
    net-tools \
    dialog \
    chrony \
    nfs-common \
    corkscrew \
    sudo \
    lsb-release \
    autoconf \
    automake \
    libtool \
    openssh-client && \
    rm -rf /var/lib/apt/lists/*

# install additional dependencies from the source pack
# python3-distutils is not included in Ubuntu:24.04, instead install python3-setuptools
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    build-essential \
    git \
    curl \
    bison \
    flex \
    swig \
    u-boot-tools && \
    if echo ${BASE_IMAGE} | grep -q "ubuntu:24.04"; then \
        apt-get install -y --no-install-recommends python3-setuptools libtinfo6 libncurses6 ; \
    else \
        apt-get install -y --no-install-recommends python3-distutils libtinfo5 libncurses5 ; \
    fi && \
    if [ ! "${BASE_IMAGE}" = *18.04* ]; then \
        apt-get install -y --no-install-recommends \
        # libc6-i386 is not available on arm64v8/ubuntu
        # installing libc6-i386-amd64-cross instead
        libc6-i386-amd64-cross; \
    fi && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    mono-runtime \
    cmake \
    ninja-build \
    pkgconf \
    graphviz \
    graphviz-dev \
    python3-pyelftools && \
    if [ ! "${BASE_IMAGE}" = *18.04* ]; then \
        apt-get install -y --no-install-recommends \
        # python3-pip \
        python3-setuptools \
        libprotobuf-dev \
        protobuf-compiler \
        libprotoc-dev; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# install libGLESv2, libEGL, libgbm-dev, libglm-dev, libdrm-dev
RUN if [ "${ARCH}" = "arm64" ]; then \
        apt-get update && apt-get install -y --no-install-recommends \
        libgles2-mesa-dev \
        libegl-dev \
        libgbm-dev \
        libglm-dev \
        libdrm-dev && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# build and install ti-rpmsg-char
WORKDIR /opt
RUN if [ "${ARCH}" = "arm64" ]; then \
    git clone git://git.ti.com/rpmsg/ti-rpmsg-char.git --branch ${RPMSG_VER} --depth 1 --single-branch && \
        cd /opt/ti-rpmsg-char && \
        autoreconf -i && ./configure --host=aarch64-none-linux-gnu --prefix=/usr && \
        make && make install && \
        rm -rf /opt/ti-rpmsg-char; \
    fi

#=========================================================================
# add scripts
COPY entrypoint.sh /root/entrypoint.sh

# .profile and .bashrc
WORKDIR /root
RUN echo "if [ -n \"$BASH_VERSION\" ]; then"     >  .profile && \
    echo "    # include .bashrc if it exists"    >> .profile && \
    echo "    if [ -f \"$HOME/.bashrc\" ]; then" >> .profile && \
    echo "        . \"$HOME/.bashrc\""           >> .profile && \
    echo "    fi"                                >> .profile && \
    echo "fi"                                    >> .profile && \
    echo "#!/bin/bash"                           >  .bashrc  && \
    echo "export PS1=\"${debian_chroot:+($debian_chroot)}\u@docker:\w\$ \"" >> .bashrc

# add label
LABEL TI_IMAGE_SOURCE=${BASE_IMAGE}

ENV WORK_DIR=/opt/psdk-rtos
WORKDIR $WORK_DIR

# setup entrypoint
ENTRYPOINT ["/root/entrypoint.sh"]
