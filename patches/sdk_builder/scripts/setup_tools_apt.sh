#!/bin/bash

ubuntu_1804=0
VERSION_ID=`cat /etc/os-release | grep VERSION_ID= | sed -e "s|VERSION_ID=\"||" | sed -e "s|\"||"`
if [ ${VERSION_ID} = "18.04" ]
then
    ubuntu_1804=1
fi

# Track which packages didn't install then print out at the end
declare -a err_packages

sudo apt-get update
declare -a arr=()

# This section lists packages to be installed on the host machine (including comments for what it is needed for)
arr+=("unzip")                      # for unzipping zip tools
arr+=("build-essential")            # for gnu make utilities
arr+=("git")                        # for cloning open source repos (later in this script)
arr+=("curl" "python3-distutils")   # for installing pip (later in this script)
arr+=("libtinfo5")                  # for TI ARM compiler dependency (22.04 needs this, 18.04 is pre-installed)
arr+=("bison")                      # for rebuilding the dtb, dtbo from PSDK Linux install directory (make linux-dtbs) after memory map updates
arr+=("flex")                       # for building linux uboot with PSDK Linux top-level makefile using the "make uboot" rule (HS and enabling MCU1_0)
arr+=("swig")                       # for building linux uboot with PSDK Linux top-level makefile using the "make uboot" rule (HS and enabling MCU1_0)
arr+=("u-boot-tools")               # for building linux sysfw with PSDK Linux top-level makefile using the "make sysfw" rule (HS and enabling MCU1_0)

if [ $ubuntu_1804 -eq 0 ]
then
    arr+=("libc6-i386")  # for running the ti-cgt-c6000 installer (only on 22.04, since not preinstalled)
fi

# If we are doing more than just building RTOS firmware for yocto, there may be more packages we need
if [ $firmware_only -eq 0 ]
then

    arr+=("mono-runtime")           # for building sbl bootimage (uses Win32 executable on linux)
    arr+=("cmake")                  # for building all edgeai repos
    arr+=("ninja-build" "pkgconf")  # for building edgeai-gst-plugins repo
    arr+=("graphviz")               # for 'dot' tool when running PyTIOVX tool on PC, and tivxExportGraphToDot() in PC emulation
    arr+=("graphviz-dev")           # for tidl model visualization build dependencies
    arr+=("python3-pyelftools")     # for building ATF (for QNX SBL "make sbl_atf_optee")

    if [ $ubuntu_1804 -eq 0 ]
    then
        arr+=("python3-pip")         # for TIDL OSRT- ONNX
        arr+=("python3-setuptools")  # for TIDL OSRT- ONNX
        arr+=("libprotobuf-dev")     # for TIDL OSRT- ONNX
        arr+=("protobuf-compiler")   # for TIDL OSRT- ONNX
        arr+=("libprotoc-dev")       # for TIDL OSRT- ONNX
    fi

    # If we are needing to support PC emulation mode
    if [ $pc_emulation -eq 1 ]
    then
        echo "[dof] Creating/Updating system link to libDOF.so ..."
        sudo ln -sf $PWD/j7_c_models/lib/PC/x86_64/LINUX/release/libDOF.so /usr/lib/x86_64-linux-gnu/libDOF.so
        sudo ln -sf $PWD/j7_c_models/lib/PC/x86_64/LINUX/release/libglbce.so /usr/lib/x86_64-linux-gnu/libApicalSIM.so.1

        if [ $ubuntu_1804 -eq 1 ]
        then
            arr+=("gcc-5" "g++-5")  # for pc emulation compiler (only on 18.04, since not preinstalled)
        fi

        arr+=("libpng-dev")         # for building tiovx/utils/source/tivx_utils_png_rd_wr.c
        arr+=("libgles2-mesa-dev")  # for building vision_apps/utils/opengl/include/app_gl_egl_utils.h
    fi
fi

#    Prior to 9.00.00 SDK release, the following additional packages were also installed but are no longer needed in
#    9.00.00.  The list is kept here as a reference in case something stops working on a new machine installation, this list
#    can be referred in case a missing package is in this list and not called in the script.
#
#    arr+=("zlib1g-dev" "libtiff-dev" "libsdl2-dev" "libsdl2-image-dev" \
#            "libxmu-dev" "libxi-dev" "libgl-dev" "libosmesa-dev" "python3" "python3-pip" \
#            "libz1:i386" "libc6-dev-i386" "libc6:i386" "libstdc++6:i386" "g++-multilib" "diffstat" "texinfo"\
#            "gawk" "chrpath" "libfreetype6-dev" "libssl-dev" "libdevil-dev"  \
#            "python3-dev" "libx11-dev" "pxz" "libglew-dev" "xz-utils" "python3-bs4")

if ! sudo apt-get install -y "${arr[@]}"; then
    for i in "${arr[@]}"
    do
        if ! sudo apt-get install -y "$i"; then
            err_packages+=("$i")
        fi
    done
fi

# check if there is a err_packages
if [ -z "$err_packages" ]; then
    echo "Packages installed successfully"
else
    echo "ERROR: The following packages were not installed:"
    for i in "${err_packages[@]}"
    do
       echo "$i"
    done
fi

# Python environment
echo "[pip] Checking ..."
if [ ! -f ~/.local/bin/pip ]
then
    PYTHON3_VERSION=`python3 -c 'import sys; version=sys.version_info[:2]; print("{1}".format(*version))'`
    if [ ${PYTHON3_VERSION} = '3' ]
    then
        curl "https://bootstrap.pypa.io/pip/3.3/get-pip.py" -o "get-pip.py"
    elif [ ${PYTHON3_VERSION} = '4' ]
    then
        curl "https://bootstrap.pypa.io/pip/3.4/get-pip.py" -o "get-pip.py"
    elif [ ${PYTHON3_VERSION} = '5' ]
    then
        curl "https://bootstrap.pypa.io/pip/3.5/get-pip.py" -o "get-pip.py"
    elif [ ${PYTHON3_VERSION} = '6' ]
    then
        curl "https://bootstrap.pypa.io/pip/3.6/get-pip.py" -o "get-pip.py"
    else
        curl "https://bootstrap.pypa.io/pip/get-pip.py" -o "get-pip.py"
    fi
    python3 get-pip.py --user
    rm get-pip.py
fi

python3 -m pip install --upgrade pip

echo "[pip] Checking ... Done"

echo "[pip] Installing dependant python packages ..."
if ! command -v pip3 &> /dev/null
then
    export PATH=${HOME}/.local/bin:$PATH
fi
pip3 install pycryptodomex --user  # for building ATF, OPTEE (built for qnx sbl)
pip3 install meson --user          # for building edegai-gst-plugins
pip3 install jsonschema --user     # for building linux uboot with PSDK Linux top-level makefile using the "make uboot" rule (HS and enabling MCU1_0)
echo "[pip] Installing dependant python packages ... Done"
