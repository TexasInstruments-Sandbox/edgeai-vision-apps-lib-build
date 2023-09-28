Vision-Apps Library Build in Ubuntu Docker Container
====================================================

Support the following two cases:
1. Case 1: Cross-compiling on x86_64 build machine in Ubuntu Docker container
2. Case 2 (QEMU): Compiling with the native GCC in arm64v8 Ubuntu Docker container on x86_64 machine using QEMU

## Prerequisite

### repo tool

```
mkdir -p ~/bin
PATH="${HOME}/bin:${PATH}"
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+rx ~/bin/repo
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
```

### initial setup: install source repos and compiler tools

```
SOC=j721e ./init_setup.sh
```
## CASE 1: Cross-compiling on x86_64 build machine in Ubuntu Docker container

### Docker-build

```
ARCH=amd64 UBUNTU_VER=22.04 SOC=j721e ./docker_build.sh
ARCH=amd64 UBUNTU_VER=20.04 SOC=j721e ./docker_build.sh
```

### Docker-run

```
ARCH=amd64 UBUNTU_VER=22.04 SOC=j721e ./docker_run.sh
ARCH=amd64 UBUNTU_VER=20.04 SOC=j721e ./docker_run.sh
```
### Build in the container

```
cd sdk_builder
make yocto_build
```

## CASE 2 (QEMU): Compiling with the native GCC in arm64v8 Ubuntu Docker container using QEMU on x86_64 machine

### Docker-build

First, to use the QEMU (one-time after boot the build machine):
```
./qemu_init.sh
```

```
ARCH=arm64 UBUNTU_VER=22.04 SOC=j721e ./docker_build.sh
ARCH=arm64 UBUNTU_VER=20.04 SOC=j721e ./docker_build.sh
```

### Docker-run

Compiling with the native GCC in arm64v8 Ubuntu Docker container on x86_64 machine with QEMU:
```
ARCH=arm64 UBUNTU_VER=22.04 SOC=j721e ./docker_run.sh
ARCH=arm64 UBUNTU_VER=20.04 SOC=j721e ./docker_run.sh
```

### Build in the container

```
cd sdk_builder
GCC_LINUX_ARM_ROOT=/usr CROSS_COMPILE_LINARO="" TREAT_WARNINGS_AS_ERROR=0 make yocto_build
```
