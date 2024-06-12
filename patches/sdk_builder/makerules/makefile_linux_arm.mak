#
# Utility makefile to build linux components and load updated file system
#
# Edit this file to suit your specific build needs
#

ifeq ($(PROFILE), $(filter $(PROFILE),debug all))
LINUX_APP_PROFILE=debug
endif
ifeq ($(PROFILE), $(filter $(PROFILE),release all))
LINUX_APP_PROFILE=release
endif

ifeq ($(SOC),j721e)
LINUX_FIRMWARE_PREFIX=j7
else
LINUX_FIRMWARE_PREFIX=$(SOC)
endif

FIRMWARE_SUBFOLDER?=vision_apps_evm
UENV_NAME?=uEnv_$(SOC)_vision_apps.txt
LINUX_FS_STAGE_PATH?=/tmp/tivision_apps_targetfs_stage
# The bootfs stage path is used to keep the default bootfs dir unaltered.
# EX: When enabaling "BUILD_CPU_MCU1_0", we copy over the tispl.bin and u-boot.img
#	  files to the bootfs stage folder to avoid overwriting the default
#	  tispl.bin and u-boot.img files.
LINUX_BOOTFS_STAGE_PATH?=/tmp/tivision_apps_bootfs_stage

linux_fs_stage:
ifeq ($(YOCTO_STAGE),)
	@rm -rf $(LINUX_FS_STAGE_PATH)
	@rm -rf $(LINUX_BOOTFS_STAGE_PATH)
	install -m 775 -d $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)
	install -m 775 -d $(LINUX_BOOTFS_STAGE_PATH)
	if [ -f $(LINUX_FS_BOOT_PATH)/version ]; then cp -rf $(LINUX_FS_BOOT_PATH)/* $(LINUX_BOOTFS_STAGE_PATH)/; fi
endif
	install -m 775 -d $(LINUX_FS_STAGE_PATH)/usr/lib

ifeq ($(BUILD_CPU_MPU1),yes)
	# copy application binaries and scripts
	install -m 775 -d $(LINUX_FS_STAGE_PATH)/opt/vision_apps
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/$(MPU_CPU)/LINUX/$(LINUX_APP_PROFILE)/*.out $(LINUX_FS_STAGE_PATH)/opt/vision_apps || true
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/$(MPU_CPU)/LINUX/$(LINUX_APP_PROFILE)/vx_app_arm_remote_log.out $(LINUX_FS_STAGE_PATH)/opt || true
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/$(MPU_CPU)/LINUX/$(LINUX_APP_PROFILE)/libtivision_apps.so.$(PSDK_VERSION) $(LINUX_FS_STAGE_PATH)/usr/lib
	cp -P $(VISION_APPS_PATH)/out/$(TARGET_SOC)/$(MPU_CPU)/LINUX/$(LINUX_APP_PROFILE)/libtivision_apps.so $(LINUX_FS_STAGE_PATH)/usr/lib
	cp $(VISION_APPS_PATH)/apps/basic_demos/app_linux_fs_files/vision_apps_init.sh $(LINUX_FS_STAGE_PATH)/opt/vision_apps/.
	cp -r $(VISION_APPS_PATH)/apps/basic_demos/app_linux_fs_files/vision_apps_all/* $(LINUX_FS_STAGE_PATH)/opt/vision_apps/.
ifeq ($(YOCTO_STAGE),)
ifeq ($(SOC), $(filter $(SOC), am62a j722s))
	cp -r $(VISION_APPS_PATH)/apps/basic_demos/app_linux_fs_files/vision_apps_lite/* $(LINUX_FS_STAGE_PATH)/opt/vision_apps/.
else
	cp -r $(VISION_APPS_PATH)/apps/basic_demos/app_linux_fs_files/vision_apps_evm/* $(LINUX_FS_STAGE_PATH)/opt/vision_apps/.
endif
	chmod +x $(LINUX_FS_STAGE_PATH)/opt/vision_apps/*.sh

	cp -r $(TIDL_PATH)/ti_dl/test/testvecs/ $(LINUX_FS_STAGE_PATH)/opt/tidl_test/

ifeq ($(BUILD_ENABLE_TIDL_RT),yes)
	#Copying OSRT components
	cp -P $(TIDL_PATH)/arm-tidl/tfl_delegate/out/$(TARGET_SOC)/$(MPU_CPU)/LINUX/$(LINUX_APP_PROFILE)/*.so*  $(LINUX_FS_STAGE_PATH)/usr/lib
	cp -P $(TIDL_PATH)/arm-tidl/onnxrt_ep/out/$(TARGET_SOC)/$(MPU_CPU)/LINUX/$(LINUX_APP_PROFILE)/*.so*  $(LINUX_FS_STAGE_PATH)/usr/lib
	cp -P $(TIDL_PATH)/arm-tidl/rt/out/$(TARGET_SOC)/$(MPU_CPU)/LINUX/$(LINUX_APP_PROFILE)/*.so*  $(LINUX_FS_STAGE_PATH)/usr/lib
	cp $(TIDL_PATH)/arm-tidl/rt/out/$(TARGET_SOC)/$(MPU_CPU)/LINUX/$(LINUX_APP_PROFILE)/*.out     $(LINUX_FS_STAGE_PATH)/opt/tidl_test/
endif

	# COPY the imported models for conformance
	if [ -f ${TIDL_PATH}/ti_dl/test/testvecs/config/tidl_models/caffe/tidl_net_mobilenet_v1.bin ]; \
	then mkdir -p $(LINUX_FS_STAGE_PATH)/opt/vision_apps/test_data/tivx/tidl_models/; \
	cp ${TIDL_PATH}/ti_dl/test/testvecs/config/tidl_models/caffe/tidl_net_mobilenet_v1* $(LINUX_FS_STAGE_PATH)/opt/vision_apps/test_data/tivx/tidl_models/;	\
	fi
endif

	# copy imaging sensor dcc binaries
	install -m 775 -d $(LINUX_FS_STAGE_PATH)/opt/imaging/imx390/linear
	install -m 775 -d $(LINUX_FS_STAGE_PATH)/opt/imaging/imx390/wdr

	install -m 775 -d $(LINUX_FS_STAGE_PATH)/opt/imaging/ar0820/linear
	install -m 775 -d $(LINUX_FS_STAGE_PATH)/opt/imaging/ar0820/wdr

	install -m 775 -d $(LINUX_FS_STAGE_PATH)/opt/imaging/ar0233/linear
	install -m 775 -d $(LINUX_FS_STAGE_PATH)/opt/imaging/ar0233/wdr

	install -m 775 -d $(LINUX_FS_STAGE_PATH)/opt/imaging/imx219/linear
ifeq ($(SOC), $(filter $(SOC), am62a j722s))
	install -m 775 -d $(LINUX_FS_STAGE_PATH)/opt/imaging/ov2312/linear
	install -m 775 -d $(LINUX_FS_STAGE_PATH)/opt/imaging/ox05b1s/linear
endif

	cp $(IMAGING_PATH)/sensor_drv/src/imx390/dcc_bins/linear/*.bin $(LINUX_FS_STAGE_PATH)/opt/imaging/imx390/linear/
	cp $(IMAGING_PATH)/sensor_drv/src/imx390/dcc_bins/wdr/*.bin $(LINUX_FS_STAGE_PATH)/opt/imaging/imx390/wdr/

	cp $(IMAGING_PATH)/sensor_drv/src/ar0820/dcc_bins/linear/*.bin $(LINUX_FS_STAGE_PATH)/opt/imaging/ar0820/linear
	cp $(IMAGING_PATH)/sensor_drv/src/ar0820/dcc_bins/wdr/*.bin $(LINUX_FS_STAGE_PATH)/opt/imaging/ar0820/wdr

	cp $(IMAGING_PATH)/sensor_drv/src/ar0233/dcc_bins/linear/*.bin $(LINUX_FS_STAGE_PATH)/opt/imaging/ar0233/linear
	cp $(IMAGING_PATH)/sensor_drv/src/ar0233/dcc_bins/wdr/*.bin $(LINUX_FS_STAGE_PATH)/opt/imaging/ar0233/wdr

	cp $(IMAGING_PATH)/sensor_drv/src/imx219/dcc_bins/linear/*.bin $(LINUX_FS_STAGE_PATH)/opt/imaging/imx219/linear
ifeq ($(SOC), $(filter $(SOC), am62a j722s))
	cp $(IMAGING_PATH)/sensor_drv/src/ov2312/dcc_bins/linear/*.bin $(LINUX_FS_STAGE_PATH)/opt/imaging/ov2312/linear
	cp $(IMAGING_PATH)/sensor_drv/src/ox05b1s/dcc_bins/linear/*.bin $(LINUX_FS_STAGE_PATH)/opt/imaging/ox05b1s/linear
endif

	# Copy header files (variables used in this section are defined in makefile_ipk.mak)
	@# copy all the .h files under folders in IPK_INCLUDE_FOLDERS
	@# https://stackoverflow.com/questions/10176849/how-can-i-copy-only-header-files-in-an-entire-nested-directory-to-another-direct
	for folder in $(IPK_INCLUDE_FOLDERS); do \
		install -m 775 -d $(LINUX_FS_STAGE_PATH)/$(IPK_TARGET_INC_PATH)/$$folder; \
		(cd $(PSDK_PATH)/$$folder && find . -name '*.h' -print | tar --create --files-from -) | (cd $(LINUX_FS_STAGE_PATH)/$(IPK_TARGET_INC_PATH)/$$folder && tar xfp -); \
	done

ifeq ($(YOCTO_STAGE),)
	ln -sr $(LINUX_FS_STAGE_PATH)/$(IPK_TARGET_INC_PATH)/$(tidl_dir) $(LINUX_FS_STAGE_PATH)/$(IPK_TARGET_INC_PATH)/tidl_j7
	$(MAKE) EDGEAI_INSTALL_PATH=$(LINUX_FS_STAGE_PATH) edgeai_install
endif

endif

ifeq ($(YOCTO_STAGE),)
ifeq ($(BUILD_CPU_MCU1_0),yes)
	# copy remote firmware files for mcu1_0
	$(eval IMAGE_NAME := vx_app_rtos_linux_mcu1_0.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/R5F/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(TIARMCGT_LLVM_ROOT)/bin/tiarmstrip -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
ifneq ($(SOC), am62a)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-mcu-r5f0_0-fw
endif
else
ifeq ($(RTOS_SDK),pdk)
	# Copy MCU1_0 firmware which is used in the default uboot
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/pdk-ipc/ipc_echo_testb_mcu1_0_release_strip.xer5f $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-mcu-r5f0_0-fw
endif
endif
ifeq ($(BUILD_CPU_MCU1_1),yes)
	# copy remote firmware files for mcu1_1
	$(eval IMAGE_NAME := vx_app_rtos_linux_mcu1_1.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/R5F/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(TIARMCGT_LLVM_ROOT)/bin/tiarmstrip -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-mcu-r5f0_1-fw
endif
ifeq ($(BUILD_CPU_MCU2_0),yes)
	# copy remote firmware files for mcu2_0
	$(eval IMAGE_NAME := vx_app_rtos_linux_mcu2_0.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/R5F/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(TIARMCGT_LLVM_ROOT)/bin/tiarmstrip -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-main-r5f0_0-fw
ifeq ($(HS),1)
	$(TI_SECURE_DEV_PKG)/scripts/secure-binary-image.sh $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-main-r5f0_0-fw-sec
endif
endif
ifeq ($(BUILD_CPU_MCU2_1),yes)
	# copy remote firmware files for mcu2_1
	$(eval IMAGE_NAME := vx_app_rtos_linux_mcu2_1.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/R5F/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(TIARMCGT_LLVM_ROOT)/bin/tiarmstrip -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-main-r5f0_1-fw
ifeq ($(HS),1)
	$(TI_SECURE_DEV_PKG)/scripts/secure-binary-image.sh $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-main-r5f0_1-fw-sec
endif
endif
ifeq ($(BUILD_CPU_MCU3_0),yes)
	# copy remote firmware files for mcu3_0
	$(eval IMAGE_NAME := vx_app_rtos_linux_mcu3_0.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/R5F/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(TIARMCGT_LLVM_ROOT)/bin/tiarmstrip -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-main-r5f1_0-fw
ifeq ($(HS),1)
	$(TI_SECURE_DEV_PKG)/scripts/secure-binary-image.sh $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-main-r5f1_0-fw-sec
endif
endif
ifeq ($(BUILD_CPU_MCU3_1),yes)
	# copy remote firmware files for mcu3_1
	$(eval IMAGE_NAME := vx_app_rtos_linux_mcu3_1.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/R5F/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(TIARMCGT_LLVM_ROOT)/bin/tiarmstrip -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-main-r5f1_1-fw
ifeq ($(HS),1)
	$(TI_SECURE_DEV_PKG)/scripts/secure-binary-image.sh $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-main-r5f1_1-fw-sec
endif
endif
ifeq ($(BUILD_CPU_MCU4_0),yes)
	# copy remote firmware files for mcu4_0
	$(eval IMAGE_NAME := vx_app_rtos_linux_mcu4_0.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/R5F/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(TIARMCGT_LLVM_ROOT)/bin/tiarmstrip -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-main-r5f2_0-fw
ifeq ($(HS),1)
	$(TI_SECURE_DEV_PKG)/scripts/secure-binary-image.sh $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-main-r5f2_0-fw-sec
endif
endif
ifeq ($(BUILD_CPU_MCU4_1),yes)
	# copy remote firmware files for mcu4_1
	$(eval IMAGE_NAME := vx_app_rtos_linux_mcu4_1.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/R5F/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(TIARMCGT_LLVM_ROOT)/bin/tiarmstrip -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-main-r5f2_1-fw
ifeq ($(HS),1)
	$(TI_SECURE_DEV_PKG)/scripts/secure-binary-image.sh $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-main-r5f2_1-fw-sec
endif
endif
ifeq ($(BUILD_CPU_C6x_1),yes)
	# copy remote firmware files for c6x_1
	$(eval IMAGE_NAME := vx_app_rtos_linux_c6x_1.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/C66/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(CGT6X_ROOT)/bin/strip6x -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-c66_0-fw
ifeq ($(HS),1)
	$(TI_SECURE_DEV_PKG)/scripts/secure-binary-image.sh $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-c66_0-fw-sec
endif
endif
ifeq ($(BUILD_CPU_C6x_2),yes)
	# copy remote firmware files for c6x_2
	$(eval IMAGE_NAME := vx_app_rtos_linux_c6x_2.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/C66/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(CGT6X_ROOT)/bin/strip6x -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-c66_1-fw
ifeq ($(HS),1)
	$(TI_SECURE_DEV_PKG)/scripts/secure-binary-image.sh $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-c66_1-fw-sec
endif
endif
ifeq ($(BUILD_CPU_C7x_1),yes)
	# copy remote firmware files for c7x_1
	$(eval IMAGE_NAME := vx_app_rtos_linux_c7x_1.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/$(C7X_TARGET)/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(CGT7X_ROOT)/bin/strip7x -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-c71_0-fw
ifeq ($(HS),1)
	$(TI_SECURE_DEV_PKG)/scripts/secure-binary-image.sh $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-c71_0-fw-sec
endif
endif
ifeq ($(BUILD_CPU_C7x_2),yes)
	# copy remote firmware files for c7x_2
	$(eval IMAGE_NAME := vx_app_rtos_linux_c7x_2.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/$(C7X_TARGET)/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(CGT7X_ROOT)/bin/strip7x -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-c71_1-fw
ifeq ($(HS),1)
	$(TI_SECURE_DEV_PKG)/scripts/secure-binary-image.sh $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-c71_1-fw-sec
endif
endif
ifeq ($(BUILD_CPU_C7x_3),yes)
	# copy remote firmware files for c7x_3
	$(eval IMAGE_NAME := vx_app_rtos_linux_c7x_3.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/$(C7X_TARGET)/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(CGT7X_ROOT)/bin/strip7x -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-c71_2-fw
ifeq ($(HS),1)
	$(TI_SECURE_DEV_PKG)/scripts/secure-binary-image.sh $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-c71_2-fw-sec
endif
endif
ifeq ($(BUILD_CPU_C7x_4),yes)
	# copy remote firmware files for c7x_4
	$(eval IMAGE_NAME := vx_app_rtos_linux_c7x_4.out)
	cp $(VISION_APPS_PATH)/out/$(TARGET_SOC)/$(C7X_TARGET)/$(RTOS)/$(LINUX_APP_PROFILE)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/.
	$(CGT7X_ROOT)/bin/strip7x -p $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME)
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-c71_3-fw
ifeq ($(HS),1)
	$(TI_SECURE_DEV_PKG)/scripts/secure-binary-image.sh $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME) $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed
	ln -sr $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/$(IMAGE_NAME).signed $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-c71_3-fw-sec
endif
endif
	sync
endif

# MODIFY_FS macro for making PSDK RTOS modifications to the PSDK Linux to file system
# $1 : rootfs path
# $2 : bootfs path
ifneq ($(SOC), am62a)
define MODIFY_FS =
	# copy uEnv.txt for PSDK RTOS
	cp $(VISION_APPS_PATH)/apps/basic_demos/app_linux_fs_files/uEnv_$(SOC)_vision_apps.txt $(2)/
	cp $(VISION_APPS_PATH)/apps/basic_demos/app_linux_fs_files/uEnv_$(SOC)_edgeai_apps.txt $(2)/
	cp $(2)/$(UENV_NAME) $(2)/uEnv.txt
	# update any additional files specific to PSDK RTOS in the filesystem
	-cp $(VISION_APPS_PATH)/apps/basic_demos/app_linux_fs_files/limits.conf $(1)/etc/security/limits.conf 2> /dev/null
	sync
endef
else
define MODIFY_FS =
	# update any additional files specific to PSDK RTOS in the filesystem
	-cp $(VISION_APPS_PATH)/apps/basic_demos/app_linux_fs_files/limits.conf $(1)/etc/security/limits.conf 2> /dev/null
	sync
endef
endif

ifeq ($(SOC), am62a)
	FIRMWARE_PREFIX_TO_DELETE=c7*-fw
else
	FIRMWARE_PREFIX_TO_DELETE=*-fw
endif
# CLEAN_COPY_FROM_STAGE macro for updating a file system from the stage fs
# $1 : destination rootfs path
define CLEAN_COPY_FROM_STAGE =
	# remove old remote files from filesystem
	-rm -f $(1)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-$(FIRMWARE_PREFIX_TO_DELETE)
	-rm -f $(1)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-*-fw-sec
	-rm -rf $(1)/lib/firmware/$(FIRMWARE_SUBFOLDER)
	-rm -rf $(1)/opt/tidl_test/*
	-rm -rf $(1)/opt/notebooks/*
	-rm -rf $(1)/$(IPK_TARGET_INC_PATH)/*

	# create new directories
	-mkdir -p $(1)/$(IPK_TARGET_INC_PATH)

	# copy full vision apps linux fs stage directory into linux fs
	cp -r $(LINUX_FS_STAGE_PATH)/* $(1)/.
	sync
endef

# CLEAN_COPY_FROM_STAGE_FAST macro for updating a file system from the stage fs
# - Assumes that FULL copy has been done before
# - Only updates vision_apps exe and firmware
# $1 : destination rootfs path
define CLEAN_COPY_FROM_STAGE_FAST =
	# remove old remote files from filesystem
	-rm -f $(1)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-*-fw
	-rm -f $(1)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-*-fw-sec
	-rm -rf $(1)/lib/firmware/$(FIRMWARE_SUBFOLDER)

	# copy partial vision apps linux fs stage directory into linux fs
	cp -r $(LINUX_FS_STAGE_PATH)/lib/firmware/$(LINUX_FIRMWARE_PREFIX)-*-fw $(1)/lib/firmware/.
	cp -r $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER) $(1)/lib/firmware/.
	cp -r $(LINUX_FS_STAGE_PATH)/opt/vision_apps/* $(1)/opt/vision_apps/.
	cp -r $(LINUX_FS_STAGE_PATH)/usr/lib/* $(1)/usr/lib/.
	sync
endef

###### USED FOR YOCTO BUILD #########

include $(CONCERTO_ROOT)/shell.mak

YOCTO_VARS = PROFILE=release \
	BUILD_EMULATION_MODE=no \
	TARGET_CPU=$(MPU_CPU) \
	TARGET_OS=LINUX \
	TIDL_PATH=$(PSDK_PATH)/tidl_j7

yocto_build:
	$(COPYDIR) $(PSDK_PATH)/psdk_include/* $(PSDK_PATH)/.
	$(YOCTO_VARS) $(MAKE) app_utils
	$(YOCTO_VARS) $(MAKE) imaging
	$(YOCTO_VARS) BUILD_CSITX=no $(MAKE) video_io
	$(YOCTO_VARS) $(MAKE) tiovx
	$(YOCTO_VARS) $(MAKE) tidl_tiovx_kernels
	$(YOCTO_VARS) $(MAKE) ptk
	$(YOCTO_VARS) $(MAKE) -C $(VISION_APPS_PATH) tivision_apps
	$(YOCTO_VARS) $(MAKE) -C $(VISION_APPS_PATH) vx_app_conformance \
		vx_app_conformance_core vx_app_conformance_hwa vx_app_conformance_tidl \
		vx_app_arm_remote_log vx_app_arm_ipc vx_app_arm_mem \
		vx_app_arm_fd_exchange_consumer vx_app_arm_fd_exchange_producer \
		vx_app_c7x_kernel vx_app_heap_stats vx_app_load_test vx_app_viss
# ifneq ($(SOC),am62a)
# 	$(YOCTO_VARS) $(MAKE) -C $(VISION_APPS_PATH) vx_app_conformance_video_io
# endif

yocto_clean: app_utils_scrub imaging_scrub video_io_scrub tiovx_scrub tidl_tiovx_kernels_scrub ptk_scrub scrub
	$(CLEANDIR) $(PSDK_PATH)/tidl_j7
	$(CLEANDIR) $(VXLIB_PATH)
	$(CLEANDIR) $(IVISION_PATH)
	$(CLEANDIR) $(TIADALG_PATH)

yocto_install:
	$(YOCTO_VARS) YOCTO_STAGE=1 $(MAKE) linux_fs_stage

#### USED FOR FIRMWARE ONLY BUILD ####

FIRMWARE_VARS = PROFILE=release \
	BUILD_EMULATION_MODE=no \
	BUILD_CPU_MPU1=no \
	BUILD_LINUX_MPU=no \
	BUILD_QNX_MPU=no \
	BUILD_APP_RTOS_LINUX=yes \
	BUILD_EDGEAI=yes

firmware:
	$(FIRMWARE_VARS) $(MAKE) sdk
	$(FIRMWARE_VARS) $(MAKE) update_fw

firmware_scrub:
	$(FIRMWARE_VARS) $(MAKE) sdk_scrub

update_fw: linux_fs_stage
	mkdir -p $(PSDK_PATH)/psdk_fw/$(SOC)/$(FIRMWARE_SUBFOLDER)/
	cp $(LINUX_FS_STAGE_PATH)/lib/firmware/$(FIRMWARE_SUBFOLDER)/* $(PSDK_PATH)/psdk_fw/$(SOC)/$(FIRMWARE_SUBFOLDER)/.

######################################

linux_host_libs_includes:
	BUILD_EMULATION_MODE=no TARGET_CPU=$(MPU_CPU) TARGET_OS=LINUX $(MAKE) imaging
	BUILD_EMULATION_MODE=no TARGET_CPU=$(MPU_CPU) TARGET_OS=LINUX $(MAKE) tiovx
	BUILD_EMULATION_MODE=no TARGET_CPU=$(MPU_CPU) TARGET_OS=LINUX $(MAKE) ptk
	BUILD_EMULATION_MODE=no TARGET_CPU=$(MPU_CPU) TARGET_OS=LINUX \
		BUILD_CPU_MPU1=yes BUILD_CPU_MCU1_0=no BUILD_CPU_MCU2_0=no BUILD_CPU_MCU2_1=no \
		BUILD_CPU_MCU3_0=no BUILD_CPU_MCU3_1=no BUILD_CPU_C6x_1=no BUILD_CPU_C6x_2=no \
		BUILD_CPU_C7x_1=no $(MAKE) tivision_apps
	BUILD_EMULATION_MODE=no TARGET_CPU=$(MPU_CPU) TARGET_OS=LINUX \
		BUILD_CPU_MPU1=yes BUILD_CPU_MCU1_0=no BUILD_CPU_MCU2_0=no BUILD_CPU_MCU2_1=no \
		BUILD_CPU_MCU3_0=no BUILD_CPU_MCU3_1=no BUILD_CPU_C6x_1=no BUILD_CPU_C6x_2=no \
		BUILD_CPU_C7x_1=no $(MAKE) linux_fs_install
	rm -Rf $(LINUX_FS_STAGE_PATH)/lib $(LINUX_FS_STAGE_PATH)/opt

linux_fs_install: linux_fs_stage
	$(call CLEAN_COPY_FROM_STAGE,$(LINUX_FS_PATH))

linux_fs_install_sd: linux_fs_install
	$(call CLEAN_COPY_FROM_STAGE,$(LINUX_SD_FS_ROOT_PATH))
ifneq ($(HS),1)
	cp -rf $(LINUX_BOOTFS_STAGE_PATH)/* $(LINUX_SD_FS_BOOT_PATH)/
endif
	$(call MODIFY_FS,$(LINUX_SD_FS_ROOT_PATH),$(LINUX_SD_FS_BOOT_PATH))

ifeq ($(BUILD_CPU_MCU1_0),yes)
ifeq ($(BUILD_TARGET_MODE),yes)
	$(call UBOOT_INSTALL,linux,$(LINUX_SD_FS_BOOT_PATH))
endif
endif
	sync

linux_fs_install_nfs: linux_fs_install
	$(call MODIFY_FS,$(LINUX_FS_PATH),$(LINUX_BOOTFS_STAGE_PATH))

ifeq ($(BUILD_CPU_MCU1_0),yes)
ifeq ($(BUILD_TARGET_MODE),yes)
	$(call UBOOT_INSTALL,linux,$(LINUX_BOOTFS_STAGE_PATH))
endif
endif

linux_fs_install_sd_ip: ip_addr_check linux_fs_install
	mkdir -p /tmp/j7-evm
	sshfs -o nonempty root@$(J7_IP_ADDRESS):/ /tmp/j7-evm
	#(call CLEAN_COPY_FROM_STAGE,/tmp/j7-evm)
	$(call CLEAN_COPY_FROM_STAGE_FAST,/tmp/j7-evm)
	$(MAKE) EDGEAI_INSTALL_PATH=/tmp/j7-evm edgeai_install
	chmod 777 -R /tmp/j7-evm/lib/firmware/$(FIRMWARE_SUBFOLDER)
	fusermount -u /tmp/j7-evm/

linux_fs_install_sd_test_data:
	$(call INSTALL_TEST_DATA,$(LINUX_SD_FS_ROOT_PATH),opt/vision_apps)

linux_fs_install_nfs_test_data:
	$(call INSTALL_TEST_DATA,$(LINUX_FS_PATH),opt/vision_apps)

linux_fs_install_tar: linux_fs_install_nfs linux_fs_install_nfs_test_data
	# Creating bootfs tar - zipping with gzip (-z option in tar)
	cd $(LINUX_BOOTFS_STAGE_PATH) && tar czf $(VISION_APPS_PATH)/bootfs.tar.gz .
	# Creating rootfs tar - using lzma compression, but parallelized to increase performance (-I 'xz -T0')
	# (-J would do lzma compression, but without parallelization)
	cd $(LINUX_FS_PATH) && sudo tar -I 'xz -T0' -cpf $(VISION_APPS_PATH)/rootfs.tar.xz .

linux_fs_install_from_custom_stage:
	# Internal Testing
	# Set LINUX_FS_PATH=destination dir
	# Set LINUX_FS_STAGE_PATH=source dir
	$(call CLEAN_COPY_FROM_STAGE,$(LINUX_FS_PATH))

