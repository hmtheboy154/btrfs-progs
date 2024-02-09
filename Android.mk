LOCAL_PATH:= $(call my-dir)

#include $(call all-subdir-makefiles)

CFLAGS := -g -O1 -Wall -D_FORTIFY_SOURCE=2 -include config.h \
	-DBTRFS_FLAT_INCLUDES -D_XOPEN_SOURCE=700 -fno-strict-aliasing -fPIC \
	-DCOMPRESSION_LZO=1 -DCOMPRESSION_ZSTD=1 -DCRYPTOPROVIDER_BUILTIN=1 \
	-Wno-unused-variable -Wno-unused-parameter -Wno-sign-compare -Wno-pointer-arith

LDFLAGS := -static -rdynamic

LIBS := -luuid   -lblkid   -lz   -llzo2 -L. -lpthread -lzstd
LIBBTRFS_LIBS := $(LIBS)

STATIC_CFLAGS := $(CFLAGS) -ffunction-sections -fdata-sections
STATIC_LDFLAGS := -static -Wl,--gc-sections
STATIC_LIBS := -luuid   -lblkid -luuid -lz   -llzo2 -L. -pthread -lzstd

btrfs_shared_libraries := libext2_uuid libext2_blkid
btrfs_static_libraries := libext2_uuid_static libext2_blkid

CRYPTO_OBJECTS = crypto/sha224-256.c crypto/blake2b-ref.c crypto/blake2b-sse2.c \
		 crypto/blake2b-sse41.c crypto/blake2b-avx2.c crypto/sha256-x86.c \
		 crypto/crc32c-pcl-intel-asm_64.c

objects = \
	kernel-lib/list_sort.c	\
	kernel-lib/raid56.c	\
	kernel-lib/rbtree.c	\
	kernel-lib/tables.c	\
	kernel-shared/accessors.c	\
	kernel-shared/async-thread.c	\
	kernel-shared/backref.c \
	kernel-shared/ctree.c	\
	kernel-shared/delayed-ref.c	\
	kernel-shared/dir-item.c	\
	kernel-shared/disk-io.c	\
	kernel-shared/extent-io-tree.c	\
	kernel-shared/extent-tree.c	\
	kernel-shared/extent_io.c	\
	kernel-shared/file-item.c	\
	kernel-shared/file.c	\
	kernel-shared/free-space-cache.c	\
	kernel-shared/free-space-tree.c	\
	kernel-shared/inode-item.c	\
	kernel-shared/inode.c	\
	kernel-shared/locking.c	\
	kernel-shared/messages.c	\
	kernel-shared/print-tree.c	\
	kernel-shared/root-tree.c	\
	kernel-shared/transaction.c	\
	kernel-shared/tree-checker.c	\
	kernel-shared/ulist.c	\
	kernel-shared/uuid-tree.c	\
	kernel-shared/volumes.c	\
	kernel-shared/zoned.c	\
	common/array.c		\
	common/cpu-utils.c	\
	common/device-scan.c	\
	common/device-utils.c	\
	common/extent-cache.c	\
	common/extent-tree-utils.c	\
	common/filesystem-utils.c	\
	common/format-output.c	\
	common/fsfeatures.c	\
	common/help.c	\
	common/inject-error.c	\
	common/messages.c	\
	common/open-utils.c	\
	common/parse-utils.c	\
	common/path-utils.c	\
	common/rbtree-utils.c	\
	common/send-stream.c	\
	common/send-utils.c	\
	common/sort-utils.c	\
	common/string-table.c	\
	common/string-utils.c	\
	common/sysfs-utils.c	\
	common/task-utils.c \
	common/units.c	\
	common/utils.c	\
	check/qgroup-verify.c	\
	check/repair.c	\
	cmds/receive-dump.c	\
	crypto/crc32c.c	\
	crypto/hash.c	\
	crypto/xxhash.c	\
	$(CRYPTO_OBJECTS)	\
	libbtrfsutil/stubs.c	\
	libbtrfsutil/subvolume.c

cmds_objects = cmds/subvolume.c cmds/subvolume-list.c \
	       cmds/filesystem.c cmds/device.c cmds/scrub.c \
	       cmds/inspect.c cmds/balance.c cmds/send.c cmds/receive.c \
	       cmds/quota.c cmds/qgroup.c cmds/replace.c check/main.c \
	       cmds/restore.c cmds/rescue.c cmds/rescue-chunk-recover.c \
	       cmds/rescue-super-recover.c \
	       cmds/property.c cmds/filesystem-usage.c cmds/inspect-dump-tree.c \
	       cmds/inspect-dump-super.c cmds/inspect-tree-stats.c cmds/filesystem-du.c \
	       cmds/reflink.c \
	       mkfs/common.c check/mode-common.c check/mode-lowmem.c \
	       common/clear-cache.c

libbtrfs_objects = \
		kernel-lib/rbtree.c	\
		libbtrfs/send-stream.c	\
		libbtrfs/send-utils.c	\
		libbtrfs/crc32c.c

libbtrfsutil_objects = libbtrfsutil/errors.c libbtrfsutil/filesystem.c \
		       libbtrfsutil/subvolume.c libbtrfsutil/qgroup.c \
		       libbtrfsutil/stubs.c

convert_objects = convert/main.c convert/common.c convert/source-fs.c \
		  convert/source-ext2.c convert/source-reiserfs.c \
		  mkfs/common.c common/clear-cache.c

mkfs_objects = mkfs/main.c mkfs/common.c mkfs/rootdir.c

image_objects = image/main.c image/sanitize.c image/image-create.c image/common.c \
		image/image-restore.c

tune_objects = tune/main.c tune/seeding.c tune/change-uuid.c tune/change-metadata-uuid.c \
	       tune/convert-bgt.c tune/change-csum.c common/clear-cache.c tune/quota.c

# external/e2fsprogs/lib is needed for uuid/uuid.h
common_C_INCLUDES := external/e2fsprogs/lib/ external/lzo/include/ external/zlib/ external/zstd/lib

#----------------------------------------------------------
include $(CLEAR_VARS)
LOCAL_SRC_FILES := $(libbtrfs_objects)
LOCAL_CFLAGS := $(STATIC_CFLAGS)
LOCAL_MODULE := libbtrfs
LOCAL_C_INCLUDES := $(common_C_INCLUDES)

intermediates := $(call local-generated-sources-dir)

BTRFS_PROGS_OPTS := --disable-libudev --disable-python --enable-year2038
CONFIG_STATUS := $(intermediates)/config.status
$(CONFIG_STATUS): $(LOCAL_PATH)/configure
	@rm -rf $(@D); mkdir -p $(@D)
	export PATH=/usr/bin:/bin:$$PATH; \
	for f in $(<D)/*; do if [ -d $$f ]; then \
		mkdir -p $(@D)/`basename $$f`; ln -sf `realpath --relative-to=$(@D)/d $$f/*` $(@D)/`basename $$f`; \
	else \
		ln -sf `realpath --relative-to=$(@D) $$f` $(@D); \
	fi; done;
	export PATH=/usr/bin:/bin:$$PATH; \
	$(LOCAL_PATH)/autogen.sh \
	cd $(@D); ./$(<F) $(CONFIG_OPTS) && \
	./$(<F) $(BTRFS_PROGS_OPTS) --prefix=/system || \
		(rm -rf $(@F); exit 1)

LOCAL_EXPORT_C_INCLUDE_DIRS := $(LOCAL_C_INCLUDES) $(intermediates) \
					$(intermediates)/kernel-lib $(intermediates)/libbtrfsutil \
					$(intermediates)/include $(intermediates)/libbtrfs
include $(BUILD_STATIC_LIBRARY)

#----------------------------------------------------------
include $(CLEAR_VARS)
LOCAL_SRC_FILES := $(libbtrfsutil_objects)
LOCAL_CFLAGS := $(STATIC_CFLAGS)
LOCAL_MODULE := libbtrfsutil
LOCAL_C_INCLUDES := $(common_C_INCLUDES)
include $(BUILD_STATIC_LIBRARY)

#----------------------------------------------------------
include $(CLEAR_VARS)
LOCAL_MODULE := btrfs
#LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_SRC_FILES := \
		$(objects) \
		$(cmds_objects) \
		btrfs.c

LOCAL_C_INCLUDES := $(common_C_INCLUDES)
LOCAL_CFLAGS := $(STATIC_CFLAGS)
#LOCAL_LDLIBS := $(LIBBTRFS_LIBS)
#LOCAL_LDFLAGS := $(STATIC_LDFLAGS)
LOCAL_POST_INSTALL_CMD := ln -sf btrfs $(TARGET_OUT)/bin/fsck.btrfs
LOCAL_POST_INSTALL_CMD += ln -sf btrfs $(TARGET_OUT)/bin/btrfsck
LOCAL_SHARED_LIBRARIES := $(btrfs_shared_libraries)
LOCAL_STATIC_LIBRARIES := libbtrfs libbtrfsutil liblzo-static libz libzstd
LOCAL_SYSTEM_SHARED_LIBRARIES := libc libcutils

LOCAL_EXPORT_C_INCLUDES := $(common_C_INCLUDES)
#LOCAL_MODULE_TAGS := optional
include $(BUILD_EXECUTABLE)

#----------------------------------------------------------
include $(CLEAR_VARS)
LOCAL_MODULE := mkfs.btrfs
LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_SRC_FILES := \
                $(objects) \
                $(mkfs_objects)

LOCAL_C_INCLUDES := $(common_C_INCLUDES)
LOCAL_CFLAGS := $(STATIC_CFLAGS)
#LOCAL_LDLIBS := $(LIBBTRFS_LIBS)
#LOCAL_LDFLAGS := $(STATIC_LDFLAGS)
LOCAL_STATIC_LIBRARIES := libbtrfs liblzo-static libzstd libbtrfsutil $(btrfs_static_libraries)
LOCAL_SYSTEM_SHARED_LIBRARIES := libc libcutils

LOCAL_EXPORT_C_INCLUDES := $(common_C_INCLUDES)
#LOCAL_MODULE_TAGS := optional
include $(BUILD_EXECUTABLE)

#---------------------------------------------------------------
include $(CLEAR_VARS)
LOCAL_MODULE := btrfstune
LOCAL_SRC_FILES := \
                $(objects) \
                $(tune_objects)

LOCAL_C_INCLUDES := $(common_C_INCLUDES)
LOCAL_CFLAGS := $(STATIC_CFLAGS)
LOCAL_SHARED_LIBRARIES := $(btrfs_shared_libraries)
#LOCAL_LDLIBS := $(LIBBTRFS_LIBS)
#LOCAL_LDFLAGS := $(STATIC_LDFLAGS)
LOCAL_SHARED_LIBRARIES := $(btrfs_shared_libraries)
LOCAL_STATIC_LIBRARIES := libbtrfs liblzo-static libzstd libbtrfsutil
LOCAL_SYSTEM_SHARED_LIBRARIES := libc libcutils

LOCAL_EXPORT_C_INCLUDES := $(common_C_INCLUDES)
LOCAL_MODULE_TAGS := optional
include $(BUILD_EXECUTABLE)
#--------------------------------------------------------------

#---------------------------------------------------------------
include $(CLEAR_VARS)
LOCAL_MODULE := btrfs-convert
LOCAL_SRC_FILES := \
                $(objects) \
				$(convert_objects)

LOCAL_C_INCLUDES := $(common_C_INCLUDES)
LOCAL_CFLAGS := $(STATIC_CFLAGS)
LOCAL_SHARED_LIBRARIES := $(btrfs_shared_libraries)
#LOCAL_LDLIBS := $(LIBBTRFS_LIBS)
#LOCAL_LDFLAGS := $(STATIC_LDFLAGS)
LOCAL_SHARED_LIBRARIES := $(btrfs_shared_libraries)
LOCAL_STATIC_LIBRARIES := libbtrfs liblzo-static libzstd libbtrfsutil
LOCAL_SYSTEM_SHARED_LIBRARIES := libc libcutils

LOCAL_EXPORT_C_INCLUDES := $(common_C_INCLUDES)
LOCAL_MODULE_TAGS := optional
include $(BUILD_EXECUTABLE)
#--------------------------------------------------------------

#---------------------------------------------------------------
include $(CLEAR_VARS)
LOCAL_MODULE := btrfs-image
LOCAL_SRC_FILES := \
                $(objects) \
				$(image_objects)

LOCAL_C_INCLUDES := $(common_C_INCLUDES)
LOCAL_CFLAGS := $(STATIC_CFLAGS)
LOCAL_SHARED_LIBRARIES := $(btrfs_shared_libraries)
#LOCAL_LDLIBS := $(LIBBTRFS_LIBS)
#LOCAL_LDFLAGS := $(STATIC_LDFLAGS)
LOCAL_SHARED_LIBRARIES := $(btrfs_shared_libraries)
LOCAL_STATIC_LIBRARIES := libbtrfs liblzo-static libzstd libbtrfsutil
LOCAL_SYSTEM_SHARED_LIBRARIES := libc libcutils

LOCAL_EXPORT_C_INCLUDES := $(common_C_INCLUDES)
LOCAL_MODULE_TAGS := optional
include $(BUILD_EXECUTABLE)
#--------------------------------------------------------------
