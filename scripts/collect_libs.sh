#! /bin/bash
# This script should be run on the host Linux / PSDK-Linux.
# This script is for ubuntu:22.04, update as needed.
set -e
current_dir=$(pwd)

# Get the full path of the script
SCRIPT_DIR=$(dirname "$(realpath "$0")")
WORKAREA=$(dirname "$SCRIPT_DIR")/workarea

if [ -f /.dockerenv ]; then
    echo "You're inside a Docker container. This script should be run on the host Linux / PSDK-Linux"
    exit 1
fi

TARGET_DIR=$HOME/vision-apps-libs

# rm -rf $TARGET_DIR
mkdir -p $TARGET_DIR

lib_files=(
    # Vision-apps libs for all the platforms
    ${WORKAREA}/vision_apps/out/J784S4/A72/LINUX/release/libti-vision-apps-j784s4_10.1.0-ubuntu22.04.deb
    ${WORKAREA}/vision_apps/out/J721S2/A72/LINUX/release/libti-vision-apps-j721s2_10.1.0-ubuntu22.04.deb
    ${WORKAREA}/vision_apps/out/J721E/A72/LINUX/release/libti-vision-apps-j721e_10.1.0-ubuntu22.04.deb
    ${WORKAREA}/vision_apps/out/J722S/A53/LINUX/release/libti-vision-apps-j722s_10.1.0-ubuntu22.04.deb
    ${WORKAREA}/vision_apps/out/AM62A/A53/LINUX/release/libti-vision-apps-am62a_10.1.0-ubuntu22.04.deb
)

for lib_file in "${lib_files[@]}"; do
    if [ -f "$lib_file" ]; then
        cp "$lib_file" "$TARGET_DIR"
    else
        echo "Error: File $lib_file does not exist."
        exit 1
    fi
done

echo "collect_libs.sh: all the lib files available on $TARGET_DIR"
find $TARGET_DIR -type f

# cd $HOME
cd $current_dir
