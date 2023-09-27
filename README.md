Vision-Apps Library Build for aarch64 Ubuntu using QEMU
=======================================================

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

## docker-build
```
SOC=j721e ./docker_build_aarch64.sh
```

### docker-run
```
SOC=j721e ./docker_run_aarch64.sh
```

### lib build in the container
```
GCC_LINUX_ARM_ROOT=/usr CROSS_COMPILE_LINARO="" TREAT_WARNINGS_AS_ERROR=0 make yocto_build
```