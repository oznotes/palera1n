SRC = $(shell pwd)
DEP = $(SRC)/dep_root
STRIP = strip
CC ?= gcc
CFLAGS += -isystem $(DEP)/include -I$(SRC)/include -I$(SRC) -D_XOPEN_SOURCE=500
CFLAGS += -Wall -Wextra -Wno-unused-parameter -DPALERAIN_VERSION=\"2.0\" -DHAVE_LIBIMOBILEDEVICE
CFLAGS += -Wno-unused-variable -I$(SRC)/src -std=c99 -pedantic-errors -D_C99_SOURCE -D_POSIX_C_SOURCE=200112L
LIBS += $(DEP)/lib/libimobiledevice-1.0.a $(DEP)/lib/libirecovery-1.0.a $(DEP)/lib/libusbmuxd-2.0.a
LIBS += $(DEP)/lib/libimobiledevice-glue-1.0.a $(DEP)/lib/libplist-2.0.a -pthread -lm
LIBS += $(DEP)/lib/libmbedtls.a $(DEP)/lib/libmbedcrypto.a $(DEP)/lib/libmbedx509.a $(DEP)/lib/libreadline.a -lusb-1.0

# Platform-specific settings
ifeq ($(OS),Windows_NT)
    CFLAGS += -DWIN32
else
    CFLAGS += -fdata-sections -ffunction-sections
    LDFLAGS += -Wl,--gc-sections
endif

# Development and release builds
ifeq ($(DEV_BUILD),1)
    CFLAGS += -O0 -g -DDEV_BUILD -fno-omit-frame-pointer
    ifeq ($(ASAN),1)
        BUILD_STYLE=ASAN
        CFLAGS += -fsanitize=address,undefined -fsanitize-address-use-after-return=runtime
    else ifeq ($(TSAN),1)
        BUILD_STYLE=TSAN
        CFLAGS += -fsanitize=thread,undefined
    else
        BUILD_STYLE = DEVELOPMENT
    endif
else
    CFLAGS += -Os -g
    BUILD_STYLE = RELEASE
endif

LIBS += -lc

# Add the usbmuxd include path
CFLAGS += -I$(DEP)/include

# Build and version information
BUILD_DATE := $(shell date)
BUILD_NUMBER := $(shell git rev-list --count HEAD)
BUILD_TAG := $(shell git describe --dirty --tags --abbrev=7)
BUILD_WHOAMI := $(shell whoami)
BUILD_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
BUILD_COMMIT := $(shell git rev-parse HEAD)

CFLAGS += -DBUILD_STYLE="\"$(BUILD_STYLE)\"" -DBUILD_DATE="\"$(BUILD_DATE)\""
CFLAGS += -DBUILD_WHOAMI="\"$(BUILD_WHOAMI)\"" -DBUILD_TAG="\"$(BUILD_TAG)\""
CFLAGS += -DBUILD_NUMBER="\"$(BUILD_NUMBER)\"" -DBUILD_BRANCH="\"$(BUILD_BRANCH)\""
CFLAGS += -DBUILD_COMMIT="\"$(BUILD_COMMIT)\""

CPATH =
LIBRARY_PATH =

export SRC DEP UNAME CC CFLAGS LDFLAGS LIBS SHELL TARGET_OS DEV_BUILD BUILD_DATE BUILD_TAG BUILD_WHOAMI BUILD_STYLE BUILD_NUMBER BUILD_BRANCH

all: palera1n

palera1n: download-deps
	$(MAKE) -C src

clean:
	$(MAKE) -C src clean
	$(MAKE) -C docs clean

download-deps:
	$(MAKE) -C src $(patsubst %, resources/%, checkra1n-macos checkra1n-linux-arm64 checkra1n-linux-armel checkra1n-linux-x86 checkra1n-linux-x86_64 checkra1n-kpf-pongo ramdisk.dmg binpack.dmg Pongo.bin)

docs:
	$(MAKE) -C docs

distclean: clean
	$(MAKE) -C src distclean

.PHONY: all palera1n clean docs distclean
