#
# Utility makefile to build ipk file that can be loaded in target filesystem using opkg
#
# Edit this file to suit your specific build needs
#

# 1. vision_apps should be built successfully
# 2. .so and firmware files are assumed to be already copied to targetfs folder with
#    "make linux_fs_install" or "make linux_fs_install_sd"
#
# "opkg_utils" is required for making opkg repo: git://git.yoctoproject.org/opkg-utils
#  - This can be automatically downloaded from running setup_psdk_rtos.sh

ifeq ($(SOC),j721e)
LINUX_FIRMWARE_PREFIX=j7
else
LINUX_FIRMWARE_PREFIX=$(SOC)
endif

IPK_TARGET_INC_PATH  = usr/include/processor_sdk
OPKG_UTILS_PATH     ?= $(PSDK_PATH)/opkg-utils-master
IPK_VERSION_STRING  ?= $(PSDK_VERSION)
J7_IP_ADDRESS       ?= 192.168.999.999

# Return the last word after a '/'.
# ex: <some_dir_path>/REPO/tidl_j7_xx_yy_zz_ww will give tidl_j7_xx_yy_zz_ww
TIDL_PATH=$(PSDK_PATH)/tidl_j7
tidl_dir = $(notdir $(TIDL_PATH))

# Use this to use ALL headers in the component folders
#IPK_INCLUDE_FOLDERS=imaging $(tidl_dir) ivision vision_apps perception tiadalg

# Use this to use a subset of the interface headers in the component folders
IPK_INCLUDE_FOLDERS=app_utils/utils \
					imaging/algos/dcc/include \
					imaging/algos/ae/include \
					imaging/algos/awb/include \
					imaging/itt_server_remote/include \
					imaging/kernels/include \
					imaging/ti_2a_wrapper/include \
					imaging/sensor_drv/include \
					imaging/utils \
					ivision \
					$(tidl_dir)/arm-tidl/rt/inc \
					$(tidl_dir)/arm-tidl/tiovx_kernels/include \
					tiovx/conformance_tests/test_engine \
					tiovx/include \
					tiovx/kernels/include \
					tiovx/utils/include \
					vision_apps/platform/$(SOC) \
					vision_apps/applibs \
					vision_apps/kernels \
					vision_apps/modules \
					vision_apps/utils \
					video_io/kernels/include \
					vxlib/packages/ti/vxlib/src/common

ifeq ($(BUILD_PTK),yes)
IPK_INCLUDE_FOLDERS += ti-perception-toolkit/include
endif

ifeq ($(SOC), $(filter $(SOC),j721e j721s2 j784s4))
IPK_INCLUDE_FOLDERS += tiadalg
endif

ifeq ($(PROFILE), $(filter $(PROFILE),debug all))
LINUX_APP_PROFILE=debug
IPK_PGK_SUFFIX=_debug
endif
ifeq ($(PROFILE), $(filter $(PROFILE),release all))
LINUX_APP_PROFILE=release
IPK_PGK_SUFFIX=
endif

VISION_APPS_TMP_PATH = /tmp/tivision_apps
IPK_TMP_PATH = $(VISION_APPS_TMP_PATH)/ipk
IPK_OUT_PATH = $(VISION_APPS_PATH)/out/$(TARGET_SOC)/$(MPU_CPU)/LINUX/$(LINUX_APP_PROFILE)
OPKG_REPO_OUT_PATH = $(VISION_APPS_PATH)/out/$(TARGET_SOC)/$(MPU_CPU)/LINUX/$(LINUX_APP_PROFILE)/opkg_repo

.PHONY: ipk ipk_package ipk_prepare_repo ip_addr_check ipk_deploy ipk_clean deb_package deb_clean

ipk: ipk_package ipk_prepare_repo

# package tivision_apps into .ipk (creates in $TARGET_OUT path)
ipk_package: linux_fs_install
	@rm -rf $(VISION_APPS_TMP_PATH)

	# Get .so libs for ipk package
	@mkdir -p $(IPK_TMP_PATH)/usr/lib
	cp -p $(LINUX_FS_PATH)/usr/lib/libtivision_apps.so.$(PSDK_VERSION) $(IPK_TMP_PATH)/usr/lib

	# Get firmware images for ipk package
	@mkdir -p $(IPK_TMP_PATH)/lib/firmware
	cp -pr $(LINUX_FS_PATH)/lib/firmware/vision_apps* $(IPK_TMP_PATH)/lib/firmware
	cp -pP $(LINUX_FS_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-*-fw $(IPK_TMP_PATH)/lib/firmware

	# Get header files for ipk package
	@# copy all the .h files under folders in IPK_INCLUDE_FOLDERS
	@# https://stackoverflow.com/questions/10176849/how-can-i-copy-only-header-files-in-an-entire-nested-directory-to-another-direct
	for folder in $(IPK_INCLUDE_FOLDERS); do \
		mkdir -p $(IPK_TMP_PATH)/$(IPK_TARGET_INC_PATH)/$$folder; \
		(cd $(PSDK_PATH)/$$folder && find . -name '*.h' -print | tar --create --files-from -) | (cd $(IPK_TMP_PATH)/$(IPK_TARGET_INC_PATH)/$$folder && tar xfp -); \
	done

	# form data.tar
	tar czf $(VISION_APPS_TMP_PATH)/data.tar.gz -C $(IPK_TMP_PATH) .

	# form control.tar
	@printf "Package: tivision_apps\n\
	Version: $(PSDK_VERSION)\n\
	Description: TI vision_apps lib $(PSDK_VERSION)\n\
	Section: extras\n\
	Priority: optional\n\
	Maintainer: TBD\n\
	License: TBD\n\
	Architecture: all\n\
	OE: tivision_apps\n\
	Homepage: unknown\n\
	Depends:\n\
	Source: N/A\n\
	"  > $(VISION_APPS_TMP_PATH)/control

	tar czf $(VISION_APPS_TMP_PATH)/control.tar.gz -C $(VISION_APPS_TMP_PATH) control

	# form debian-binary
	echo 2.0 > $(VISION_APPS_TMP_PATH)/debian-binary

	# package into .ipk
	ar r $(IPK_OUT_PATH)/tivision-apps_$(IPK_VERSION_STRING)$(IPK_PGK_SUFFIX).ipk \
		 $(VISION_APPS_TMP_PATH)/control.tar.gz \
		 $(VISION_APPS_TMP_PATH)/data.tar.gz \
		 $(VISION_APPS_TMP_PATH)/debian-binary

	@# clean-up temporary files
	@rm -rf $(VISION_APPS_TMP_PATH)

# prepare a local opkg repository that is to be copied to the target fs
# place any other .ipk package files in the $TARGET_OUT directory for including in the opkg repository
ipk_prepare_repo:
	rm -rf $(OPKG_REPO_OUT_PATH)
	mkdir -p $(OPKG_REPO_OUT_PATH)
	cp $(IPK_OUT_PATH)/*.ipk $(OPKG_REPO_OUT_PATH)/.
	cd $(OPKG_REPO_OUT_PATH); $(OPKG_UTILS_PATH)/opkg-make-index -a . > ./Packages; \
		gzip ./Packages; cd $(VISION_APPS_PATH)
	tar czf $(IPK_OUT_PATH)/opkg-repo_$(PSDK_VERSION).tar.gz -C $(IPK_OUT_PATH) ./opkg_repo

# check to make sure J7_IP_ADDRESS is set
ip_addr_check:
	@ping $(J7_IP_ADDRESS) -c 1 -W 2 >/dev/null || (echo 'ERROR: J7_IP_ADDRESS=$(J7_IP_ADDRESS) not valid, set variable to correct J7 ip address!!!'; exit 1)

# deploy the opkg repository to the target fs using scp (be sure to update J7_IP_ADDRESS
ipk_deploy: ip_addr_check
	ssh root@$(J7_IP_ADDRESS) "mkdir -p /opkg_repo"
	ssh root@$(J7_IP_ADDRESS) "rm -r /opkg_repo"
	scp -pr $(OPKG_REPO_OUT_PATH) root@$(J7_IP_ADDRESS):/opkg_repo

# clean-up intermediate files/folder and previous output ipk
ipk_clean:
	rm -rf $(VISION_APPS_TMP_PATH)
	rm -f $(IPK_OUT_PATH)/tivision-apps_$(VERSION_STRING).ipk

##### Exprimental
# PKG_DIST can be 'yocto4.0', 'ubuntu22.04', 'debian12.5'...
PKG_DIST ?= yocto4.0
PKG_NAME=libti-vision-apps-$(SOC)_$(PSDK_VERSION)-$(PKG_DIST)
DEB_TMP_PATH = $(VISION_APPS_TMP_PATH)/$(PKG_NAME)
DEB_OUT_PATH = $(VISION_APPS_PATH)/out/$(TARGET_SOC)/$(MPU_CPU)/LINUX/$(LINUX_APP_PROFILE)

# package tivision_apps into .deb (creates in $TARGET_OUT path)
deb_package:
	@rm -rf $(VISION_APPS_TMP_PATH)

	# Get .so libs for deb package
	@mkdir -p $(DEB_TMP_PATH)/usr/lib
	cp -p $(DEB_OUT_PATH)/libtivision_apps.so.$(PSDK_VERSION) $(DEB_TMP_PATH)/usr/lib

	# Get header files for ipk package
	@# copy all the .h files under folders in IPK_INCLUDE_FOLDERS
	@# https://stackoverflow.com/questions/10176849/how-can-i-copy-only-header-files-in-an-entire-nested-directory-to-another-direct
	for folder in $(IPK_INCLUDE_FOLDERS); do \
		mkdir -p $(DEB_TMP_PATH)/$(IPK_TARGET_INC_PATH)/$$folder; \
		(cd $(PSDK_PATH)/$$folder && find . -name '*.h' -print | tar --create --files-from -) | (cd $(DEB_TMP_PATH)/$(IPK_TARGET_INC_PATH)/$$folder && tar xfp -); \
	done

	# form control file
	@mkdir -p $(DEB_TMP_PATH)/DEBIAN
	@printf "Package: libti-vision-apps-$(SOC)\n\
	Version: $(PSDK_VERSION)-$(PKG_DIST)\n\
	Section: base\n\
	Priority: optional\n\
	Architecture: arm64\n\
	Depends:\n\
	Maintainer: TBD\n\
	Description: TI vision-apps library $(SOC) $(PSDK_VERSION)-$(PKG_DIST)\n\
	"  > $(DEB_TMP_PATH)/DEBIAN/control

	# form postinst file
	@printf "#!/bin/bash\n\
	set -e\n\
	# Create symbolic link\n\
	ln -sf /usr/lib/libtivision_apps.so.$(PSDK_VERSION) /usr/lib/libtivision_apps.so\n\
	#DEBHELPER#\n\
	exit 0" > $(DEB_TMP_PATH)/DEBIAN/postinst
	chmod +x $(DEB_TMP_PATH)/DEBIAN/postinst

	# package into .deb
	dpkg-deb --build $(DEB_TMP_PATH)
	cp $(VISION_APPS_TMP_PATH)/$(PKG_NAME).deb $(DEB_OUT_PATH)

	@# clean-up temporary files
	@rm -rf $(VISION_APPS_TMP_PATH)

# clean-up intermediate files/folder and previous output ipk
deb_clean:
	rm -f $(DEB_OUT_PATH)/$(PKG_NAME).deb
