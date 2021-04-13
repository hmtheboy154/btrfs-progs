LOCAL_PATH:= $(call my-dir)

#include $(call all-subdir-makefiles)

CFLAGS := -g -O1 -Wall -D_FORTIFY_SOURCE=2 -include config.h \
	-DBTRFS_FLAT_INCLUDES -D_XOPEN_SOURCE=700 -fno-strict-aliasing -fPIC \
	-Wno-unused-variable -Wno-unused-parameter -Wno-sign-compare -Wno-pointer-arith

LDFLAGS := -static -rdynamic

LIBS := -luuid   -lblkid   -lz   -llzo2 -L. -lpthread -lzstd
LIBBTRFS_LIBS := $(LIBS)

STATIC_CFLAGS := $(CFLAGS) -ffunction-sections -fdata-sections
STATIC_LDFLAGS := -static -Wl,--gc-sections
STATIC_LIBS := -luuid   -lblkid -luuid -lz   -llzo2 -L. -pthread -lzstd

btrfs_shared_libraries := libext2_uuid libext2_blkid
btrfs_static_libraries := libext2_uuid_static libext2_blkid

objects = kernel-shared/dir-item.c \
	  qgroup.c kernel-lib/list_sort.c props.c \
	  kernel-shared/ulist.c check/qgroup-verify.c kernel-shared/backref.c \
	  common/string-table.c common/task-utils.c \
	  kernel-shared/inode.c kernel-shared/file.c common/help.c cmds/receive-dump.c \
	  common/fsfeatures.c \
	  common/format-output.c \
	  common/device-utils.c
cmds_objects = cmds/subvolume.c cmds/filesystem.c cmds/device.c cmds/scrub.c \
	       cmds/inspect.c cmds/balance.c cmds/send.c cmds/receive.c \
	       cmds/quota.c cmds/qgroup.c cmds/replace.c check/main.c \
	       cmds/restore.c cmds/rescue.c cmds/rescue-chunk-recover.c \
	       cmds/rescue-super-recover.c \
	       cmds/property.c cmds/filesystem-usage.c cmds/inspect-dump-tree.c \
	       cmds/inspect-dump-super.c cmds/inspect-tree-stats.c cmds/filesystem-du.c \
	       mkfs/common.c check/mode-common.c check/mode-lowmem.c
libbtrfs_objects = common/send-stream.c common/send-utils.c kernel-lib/rbtree.c btrfs-list.c \
		   kernel-lib/radix-tree.c common/extent-cache.c kernel-shared/extent_io.c \
		   crypto/crc32c.c common/messages.c \
		   kernel-shared/uuid-tree.c common/utils-lib.c common/rbtree-utils.c \
		   kernel-shared/ctree.c kernel-shared/disk-io.c \
		   kernel-shared/extent-tree.c kernel-shared/delayed-ref.c \
		   kernel-shared/print-tree.c \
		   kernel-shared/free-space-cache.c kernel-shared/root-tree.c \
		   kernel-shared/volumes.c kernel-shared/transaction.c \
		   kernel-shared/free-space-tree.c repair.c kernel-shared/inode-item.c \
		   kernel-shared/file-item.c \
		   kernel-lib/raid56.c kernel-lib/tables.c \
		   common/device-scan.c common/path-utils.c \
		   common/utils.c libbtrfsutil/subvolume.c libbtrfsutil/stubs.c \
		   crypto/hash.c crypto/xxhash.c crypto/sha224-256.c crypto/blake2b-ref.c
libbtrfs_headers = common/send-stream.h common/send-utils.h send.h kernel-lib/rbtree.h btrfs-list.h \
	       crypto/crc32c.h kernel-lib/list.h kerncompat.h \
	       kernel-lib/radix-tree.h kernel-lib/sizes.h kernel-lib/raid56.h \
	       common/extent-cache.h kernel-shared/extent_io.h ioctl.h \
	       kernel-shared/ctree.h btrfsck.h version.h
libbtrfsutil_objects = libbtrfsutil/errors.c libbtrfsutil/filesystem.c \
		       libbtrfsutil/subvolume.c libbtrfsutil/qgroup.c \
		       libbtrfsutil/stubs.c
blkid_objects := partition/ superblocks/ topology/


# external/e2fsprogs/lib is needed for uuid/uuid.h
common_C_INCLUDES := $(LOCAL_PATH) $(LOCAL_PATH)/libbtrfsutil $(LOCAL_PATH)/kernel-lib external/e2fsprogs/lib/ external/lzo/include/ external/zlib/ external/zstd/lib

#----------------------------------------------------------
include $(CLEAR_VARS)
LOCAL_SRC_FILES := $(libbtrfs_objects) $(libbtrfsutil_objects)
LOCAL_CFLAGS := $(STATIC_CFLAGS)
LOCAL_MODULE := libbtrfs
LOCAL_C_INCLUDES := $(common_C_INCLUDES)
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
LOCAL_SHARED_LIBRARIES := $(btrfs_shared_libraries)
LOCAL_STATIC_LIBRARIES := libbtrfs liblzo-static libz libzstd libbtrfsutil
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
                mkfs/common.c \
                mkfs/main.c \
				mkfs/rootdir.c

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
                btrfstune.c

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
