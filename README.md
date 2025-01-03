Vision-Apps Library Build for Target Ubuntu/Debian
==================================================

This build system covers building the Vision-Apps Linux library for Ubuntu/Debian systems running on TI's EdgeAI processors (TDA4VM, AM62A, AM67A, AM68A, and AM69A).

Supported use cases include:

- **Case 1**: Compiling with the native GCC in arm64v8 Ubuntu Docker container directly on aarch64 build machine
- **Case 2**: Compiling with the native GCC in arm64v8 Ubuntu Docker container on x86_64 machine using QEMU

<table>
  <tr>
    <td>
    <img src="docs/diagram_aarch64_container.png" alt="Image 2" style="width: 403px;"/>
    </td>
  </tr>
</table>
<figcaption>Figure 1. Build the libraries in aarch64 Ubuntu/Debian Container</figcaption>

## Prerequisite

### docker-pull the base Docker image

Pull the baseline Docker image needed. Assuming outside of a proxy network,
```bash
docker pull --platform linux/arm64 arm64v8/ubuntu:22.04
docker pull --platform linux/arm64 arm64v8/ubuntu:20.04
docker pull --platform linux/arm64 arm64v8/debian:12.5
```

### repo tool

```bash
mkdir -p ~/bin
PATH="${HOME}/bin:${PATH}"
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+rx ~/bin/repo
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
```

Ensure that the following basic git configuration is complete, particularly for `repo init` to function as part of `init_setup.sh`.
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

### edgeai-ti-proxy (only required to make the build system work in TI proxy network)

Set up `edgeai-ti-proxy` git repository (TI-internal only).

Before docker-build or docker-run, please make sure sourcing `edgeai-ti-proxy/setup_proxy.sh`, which will define the `USE_PROXY` env variable and all the proxy settings for the TI network.

## CASE 1 & 2: Compiling with the native GCC in arm64v8 Ubuntu Docker container

### initial setup: install source repos

Depending on the Ubuntu distro for the target docker container, run one of these:
```bash
BASE_IMAGE=ubuntu:22.04 ./init_setup.sh
BASE_IMAGE=ubuntu:20.04 ./init_setup.sh
BASE_IMAGE=debian:12.5 ./init_setup.sh
```

### Docker-build

(Only for CASE 2 - QEMU on x86_64 machine) to set up the QEMU (one-time after boot the build machine):
```bash
./qemu_init.sh
```

Depending on the Ubuntu distro for the target docker container, run one of these:
```bash
BASE_IMAGE=ubuntu:22.04 ./docker_build.sh
BASE_IMAGE=ubuntu:20.04 ./docker_build.sh
BASE_IMAGE=debian:12.5 ./docker_build.sh
```

### Docker-run

Depending on the Ubuntu distro for the target docker container, run one of these:
```bash
BASE_IMAGE=ubuntu:22.04 ./docker_run.sh
BASE_IMAGE=ubuntu:20.04 ./docker_run.sh
BASE_IMAGE=debian:12.5 ./docker_run.sh
```

### Build the vision-apps library in the container

If need to clean up any previous build, run `SOC=<platform_name> make yocto_clean` or `SOC=<platform_name> make vision_apps_clean`.

To build the vision-apps library in the container, run the following:
```bash
SOC=<platform_name> GCC_LINUX_ARM_ROOT=/usr CROSS_COMPILE_LINARO= LINUX_SYSROOT_ARM=/ LINUX_FS_PATH=/ TREAT_WARNINGS_AS_ERROR=0 make yocto_build
```

where `platform_name=[j721e|j721s2|j722s|j784s4|am62a]`.


`vision_apps.so` location:
`workarea/vision_apps/out/${SOC}/A72/LINUX/release/libtivision_apps.so.${PSDK_VERSION}`

### Debian packaging (Experimental) in the container

```bash
SOC=<platform_name> PKG_DIST=ubuntu22.04 TIDL_PATH=/opt/psdk-rtos/workarea/tidl_j7 make deb_package
SOC=<platform_name> PKG_DIST=ubuntu20.04 TIDL_PATH=/opt/psdk-rtos/workarea/tidl_j7 make deb_package
SOC=<platform_name> PKG_DIST=debian12.5 TIDL_PATH=/opt/psdk-rtos/workarea/tidl_j7make deb_package
```

The resulting Debian package is located:
`workarea/vision_apps/out/${SOC}/A72/LINUX/release/libti-vision-apps-${SOC}_${PSDK_VERSION}-${PKG_DIST}.deb`

## Workarounds

### Configuration for aarch64 Ubuntu container

- Following env variables are passed during docker-run:
    ```bash
    GCC_LINUX_ARM_ROOT=/usr CROSS_COMPILE_LINARO= LINUX_SYSROOT_ARM=/ LINUX_FS_PATH=/ TREAT_WARNINGS_AS_ERROR=0
    ```
- During docker-build:
    - `ti-rpmsg-char` is built and installed
    - apt-get install `libGLESv2`, `libEGL`, `libgbm`
- Additional library and include paths are added. Please see [`patches/sdk_builder/concerto/compilers/gcc_linux_arm.mak`](patches/sdk_builder/concerto/compilers/gcc_linux_arm.mak)
- A few missing header files are copied from targetfs right after docker-run. Please see [`entrypoint.sh`](entrypoint.sh).
