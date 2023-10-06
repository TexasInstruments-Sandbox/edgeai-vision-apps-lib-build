Vision-Apps Library Build in Ubuntu Docker Container
====================================================

Support the following two cases:
1. Case 1: Cross-compiling on x86_64 build machine in Ubuntu Docker container
2. Case 2 (QEMU): Compiling with the native GCC in arm64v8 Ubuntu Docker container on x86_64 machine using QEMU

## Prerequisite

## docker-pull the base Docker image

Pull the Docker image needed. Assuming outside of a proxy network,
```
docker pull ubuntu:22.04
docker pull ubuntu:20.04
docker pull arm64v8/ubuntu:22.04
docker pull arm64v8/ubuntu:20.04
```

### repo tool

```
mkdir -p ~/bin
PATH="${HOME}/bin:${PATH}"
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+rx ~/bin/repo
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
```

## Cross-compiling on x86_64 build machine in Ubuntu Docker container

Target for lib deployment: Yocto PSDK-Linux

This has the same goal as the PSDK-RTOS workarea build system except doing in Ubuntu Docker container.

### initial setup: install source repos and compiler tools

```
SOC=j721e ./init_setup.sh
```

### Docker-build

```
ARCH=amd64 UBUNTU_VER=22.04 SOC=j721e ./docker_build.sh
```

### Docker-run

```
ARCH=amd64 UBUNTU_VER=22.04 SOC=j721e ./docker_run.sh
```
### Build in the container

```
make yocto_build
```

## Compiling with the native GCC in arm64v8 Ubuntu Docker container

Build systems:
1. In arm64v8 Ubuntu Docker container using QEMU on x86_64 machine
2. In arm64v8 Ubuntu Docker container on aarch64 target

Target for lib deployment:
1. arm64v8 Ubuntu 20.04 Docker container
2. arm64v8 Ubuntu 22.04 Docker container

### initial setup: install source repos

```
SOC=j721e ./init_setup.sh
```

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
GCC_LINUX_ARM_ROOT=/usr CROSS_COMPILE_LINARO= LINUX_SYSROOT_ARM=/ LINUX_FS_PATH=/ TREAT_WARNINGS_AS_ERROR=0 make yocto_build
```

`vision_apps.so` location:
`${SOC}-workarea/vision_apps/out/J721E/A72/LINUX/release/tivision_apps.so.9.0.0`

### Trial Results

QEMU is slower than building directly on SK-AM69A.


On the target:

| Target Ubuntu distro | Results  |
| -------------------- | -------- |
| Ubuntu 22.04         | vision_apps.so succefully built. |
| Ubuntu 20.04         | vision_apps.so succefully built. |

## Some Workarounds and Fixes

### setup_psdk_rtos.sh

From `sdk_builder/scripts/setup_psdk_rtos.sh`, following scripts are extracted. In this project a couple of the scripts are selectively executed during `init_setup.sh`.

- `setup_tools_apt.sh`: this is now integrated into the Dockerfile.
- `setup_tools_arm.sh`
- `setup_tools_cgt.sh`
- `setup_tools_misc.sh`

### AR Flags
With the default Concerto compiler settings, the following warning messages show up around every static .a library.
```
/usr/bin/ar: `u' modifier ignored since `D' is the default (see `U')
```

A workaround: https://github.com/rsyslog/rsyslog/issues/1179
Update sdk_builder/concerto/compilers/gcc_linux_arm.mak to remove 'u' flag as follows:
```
$(_MODULE)_LINK_LIB   := $(AR) -rsc $($(_MODULE)_BIN) $($(_MODULE)_OBJS)
```
