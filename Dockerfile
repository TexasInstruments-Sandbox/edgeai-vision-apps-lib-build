ARG ARCH
ARG BASE_IMAGE
ARG USE_PROXY
ARG HTTP_PROXY
ARG SOC
ARG DEBIAN_FRONTEND=noninteractive
ARG UBUNTU_1804

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
ARG DEBIAN_FRONTEND
ARG UBUNTU_1804
ARG FIRMWARE_ONLY
ARG SOC
ENV SOC=${SOC}
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# setup proxy settings
ADD setup_proxy.sh /root/
ADD proxy /root/proxy
RUN /root/setup_proxy.sh

# install python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip && \
    python3 -m pip install --upgrade pip && \
    rm -rf /var/lib/apt/lists/*

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
# below work well with Docker 24.0, but not work with Docker 20.10
# WORKDIR /opt/psdk-rtos
# RUN --mount=type=bind,source=./${SOC}-workarea,target=/opt/psdk-rtos/${SOC}-workarea \
#     cd ${SOC}-workarea && \
#     bash ./sdk_builder/scripts/setup_tools_apt.sh

# WORKDIR /opt/psdk-rtos
# ADD setup_tools_apt.sh /opt/psdk-rtos
# RUN ./setup_tools_apt.sh

RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    build-essential \
    git \
    curl \
    python3-distutils \
    libtinfo5 \
    bison \
    flex \
    swig \
    u-boot-tools && \
    if [ ${UBUNTU_1804} -eq 0 ]; then \
        apt-get update && apt-get install -y --no-install-recommends \
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
    if [ ${UBUNTU_1804} -eq 0 ]; then \
        apt-get install -y --no-install-recommends \
        # python3-pip \
        python3-setuptools \
        libprotobuf-dev \
        protobuf-compiler \
        libprotoc-dev; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# Somehow keep retrying to connect pypi.python.org in TI network then time out
RUN python3 -m pip install \
    pycryptodomex \
    meson \
    jsonschema

# install libGLESv2, libEGL, libgbm
RUN if [ "${ARCH}" = "arm64" ]; then \
        apt-get update && apt-get install -y --no-install-recommends \
        libgles2-mesa-dev \
        libegl-dev \
        libgbm-dev; \
    fi

# build and install ti-rpmsg-char
# TODO: package .so and headers
WORKDIR /opt
RUN if [ "${ARCH}" = "arm64" ]; then \
        git clone git://git.ti.com/rpmsg/ti-rpmsg-char.git && \
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
    echo "export PS1=\"${debian_chroot:+($debian_chroot)}\u@pc-docker:\w\$ \"" >> .bashrc

WORKDIR /opt/psdk-rtos

# setup entrypoint
ENTRYPOINT ["/root/entrypoint.sh"]
