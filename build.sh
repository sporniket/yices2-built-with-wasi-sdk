#!/bin/sh -ex
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
# Unofficial Yices2 WebAssembly packages
#
# Copyright (C) 2023 - 2024 David SPORN <sporniket.studio@gmail.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###

### TODO : what is the use of SOURCE_DATE_EPOCH ??
export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### Dependencies specification
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
# Normally, only this section should be updated to migrate the dependencies
# that are downloaded.
# --------

# --------
# WASI SDK 
# --------
VERSION_OF_WASI_SDK_MAJOR="19"
VERSION_OF_WASI_SDK="${VERSION_OF_WASI_SDK_MAJOR}.0"

# --------
# GMP
# --------
VERSION_OF_GMP="6.3.0"

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### WASI
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
# SETUP pathes and vars
# --------
WASI_SDK="wasi-sdk-${VERSION_OF_WASI_SDK}"
WASI_SDK_HOME=`pwd`/${WASI_SDK}

cat >tmp.pathes-wasi.mk <<END
# ---<[WASI SDK pathes]>---
WASI_SDK_HOME := `pwd`/${WASI_SDK}
WASI_SDK_PATH := \${WASI_SDK_HOME}/bin
WASI_SYSROOT := \${WASI_SDK_HOME}/share/wasi-sysroot
PATH := \${WASI_SDK_PATH}:\${PATH}
END

# --------
# DOWNLOAD
# --------
WASI_SDK_URL=https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${VERSION_OF_WASI_SDK_MAJOR}/${WASI_SDK}-linux.tar.gz
if ! [ -d ${WASI_SDK} ]; then curl -L ${WASI_SDK_URL} | tar xzf -; fi

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### GETOPT
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
# SETUP pathes and vars
# --------
cat >tmp.pathes-getopt.mk <<END
# ---<[GETOPT pathes]>---
GETOPT_HOME := `pwd`/getopt
GETOPT_SRC := \${GETOPT_HOME}/getopt_long.c
GETOPT_OBJ := \${GETOPT_HOME}/getopt_long.o
END

cat >tmp.vars-getopt.mk <<END
# ---<[GETOPT variables]>---
# Requires : tmp.pathes-wasi.mk

# -- apps
CC := \${WASI_SDK_PATH}/clang 

# -- flags
CFLAGS := --sysroot \${WASI_SYSROOT} -c 
END

# --------
# BUILD
# --------
make -C $(pwd)/getopt

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### GMP
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
# SETUP pathes and vars
# --------
cat >tmp.pathes-gmp.mk <<END
# ---<[GMP pathes]>---
GMP_RELEASE := gmp-${VERSION_OF_GMP}
GMP_SOURCE_DIR := `pwd`/\${GMP_RELEASE}
GMP_BUILD_DIR := `pwd`/\${GMP_RELEASE}-build
GMP_PREFIX_DIR := `pwd`/\${GMP_RELEASE}-prefix
END

cat >tmp.vars-gmp.mk <<END
# ---<[GMP variables]>---
# Requires : tmp.pathes-wasi.mk

# -- apps
CC := \${WASI_SDK_PATH}/clang
CC_FOR_BUILD := gcc

# -- flags 
TARGET := wasm32-unknown-wasi
ARCH := \${TARGET}
SYSROOT := \${WASI_SDK_HOME}/share/wasi-sysroot
CFLAGS := --target=\${TARGET} -D_WASI_EMULATED_SIGNAL --sysroot=\${SYSROOT}
LDFLAGS := -Wl,--strip-all --sysroot=\${SYSROOT}
LIBS_BEGIN := -lwasi-emulated-process-clocks -lwasi-emulated-signal
LIBS_END := --sysroot=\${SYSROOT}
LIBS := \${LIBS_BEGIN} \${LIBS_END}
PKG_CONFIG_SYSROOT_DIR := \${SYSROOT}
END

# --------
# Download
# --------

### GNU MP library select source tarball, check existence or fetch
GMP_RELEASE="gmp-${VERSION_OF_GMP}"
GMP_RELEASE_TARBALL="${GMP_RELEASE}.tar"
GMP_RELEASE_TARBALL_COMPRESSED="${GMP_RELEASE}.tar.gz"
GMP_RELEASE_URL=https://gmplib.org/download/gmp/${GMP_RELEASE_TARBALL_COMPRESSED}
if ! [ -d ${GMP_RELEASE} ]; then 
    if ! [ -f ${GMP_RELEASE_TARBALL} ]; then 
        if ! [ -f ${GMP_RELEASE_TARBALL_COMPRESSED} ]; then 
            curl -L --output "${GMP_RELEASE_TARBALL_COMPRESSED}" ${GMP_RELEASE_URL} 
        fi
        gunzip ${GMP_RELEASE_TARBALL_COMPRESSED}
    fi
    tar xf ${GMP_RELEASE_TARBALL}
fi
GMP_BUILD_DIR="${GMP_RELEASE}-build"
GMP_PREFIX_DIR="$(pwd)/${GMP_RELEASE}-prefix"

# --------
# BUILD
# --------
if ! [ -d ${GMP_PREFIX_DIR} ]; then 
    mkdir "${GMP_PREFIX_DIR}"
    cd ${GMP_PREFIX_DIR}
    cat >Makefile.yowasp <<END
# pathes
include ../tmp.pathes-wasi.mk
include ../tmp.pathes-gmp.mk

# vars
include ../tmp.vars-gmp.mk
ENV_OVERRIDE := CC="\${CC}" \\
  CC_FOR_BUILD="\${CC_FOR_BUILD}" \\
  TARGET="\${TARGET}" \\
  ARCH="\${ARCH}" \\
  SYSROOT="\${SYSROOT}" \\
  CFLAGS="\${CFLAGS}" \\
  CPPFLAGS="\${CPPFLAGS}" \\
  LDFLAGS="\${LDFLAGS}" \\
  LIBS_BEGIN="\${LIBS_BEGIN}" \\
  LIBS_END="\${LIBS_END}" \\
  LIBS="\${LIBS}" \\
  PKG_CONFIG_SYSROOT_DIR="\${PKG_CONFIG_SYSROOT_DIR}" \\
  PATH="\${PATH}" \\

lib/libgmp.a: \${GMP_BUILD_DIR}
	cd \${GMP_BUILD_DIR}
	\${GMP_SOURCE_DIR}/configure --host=\${TARGET} --with-sysroot=\${WASI_SYSROOT} \${ENV_OVERRIDE}
	make \${ENV_OVERRIDE}
	make install \${ENV_OVERRIDE}

\${GMP_BUILD_DIR}:
	mkdir -p \${GMP_BUILD_DIR}
END
    echo "###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=### Build Gnu MP"
    make -f Makefile.yowasp exec_prefix=${GMP_PREFIX_DIR} prefix=${GMP_PREFIX_DIR}
    echo "###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=### DONE"
    cd ..
fi

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### YICES2
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
# SETUP pathes and vars
# --------
YICES2_SRC=yices2-src
YICES2_SRC_HOME=`pwd`/${YICES2_SRC}/src
YICES2_BUILD=yices2-build

cat >tmp.pathes-yices2.mk <<END
# ---<[YICES2 pathes]>---
YICES2_SRC := `pwd`/yices2-src
YICES2_SRC_HOME := \${YICES2_SRC}/src
YICES2_BUILD := `pwd`/yices2-build
END

cat >tmp.vars-yices2.mk <<END
# ---<[YICES2 variables]>---
# Requires : tmp.pathes-wasi.mk, tmp.pathes-gmp.mk, tmp.pathes-getopt.mk, tmp.pathes-yices2.mk

# -- apps
CC := \${WASI_SDK_PATH}/clang
CC_FOR_BUILD := gcc

# -- flags 
TARGET := wasm32-unknown-wasi
ARCH := \${TARGET}
SYSROOT := \${WASI_SDK_HOME}/share/wasi-sysroot
CFLAGS := --target=\${TARGET} -D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_PROCESS_CLOCKS --sysroot=\${SYSROOT}
CPPFLAGS := -I\${GMP_PREFIX_DIR}/include -I\${YICES2_SRC_HOME} -I\${YICES2_SRC_HOME}/include
LDFLAGS := -v -Wl,--strip-all -L\${GMP_PREFIX_DIR}/lib --sysroot=\${SYSROOT}
LIBS_BEGIN := -lwasi-emulated-process-clocks -lwasi-emulated-signal
LIBS_END := --sysroot=\${SYSROOT}
LIBS := \${LIBS_BEGIN} \${GETOPT_OBJ} \${LIBS_END}
PKG_CONFIG_SYSROOT_DIR := \${SYSROOT}
END

# --------
# BUILD
# --------
pwd
cd yices2-src
cp ${WASI_SDK_HOME}/share/misc/config.guess ${WASI_SDK_HOME}/share/misc/config.sub .
cat >Makefile.yowasp <<END
# pathes
include ../tmp.pathes-wasi.mk
include ../tmp.pathes-gmp.mk
include ../tmp.pathes-getopt.mk
include ../tmp.pathes-yices2.mk

# vars
include ../tmp.vars-yices2.mk
ENV_OVERRIDE := CC="\${CC}" \\
  CC_FOR_BUILD="\${CC_FOR_BUILD}" \\
  TARGET="\${TARGET}" \\
  ARCH="\${ARCH}" \\
  SYSROOT="\${SYSROOT}" \\
  CFLAGS="\${CFLAGS}" \\
  CPPFLAGS="\${CPPFLAGS}" \\
  LDFLAGS="\${LDFLAGS}" \\
  LIBS_BEGIN="\${LIBS_BEGIN}" \\
  LIBS_END="\${LIBS_END}" \\
  LIBS="\${LIBS}" \\
  PKG_CONFIG_SYSROOT_DIR="\${PKG_CONFIG_SYSROOT_DIR}" \\


build/wasm32-unknown-wasi-release/static_bin/yices_smtcomp/yices:
	autoconf
	./configure --host=\${TARGET} \${ENV_OVERRIDE}
	grep "CPPFLAGS" configs/make.include.\${TARGET}
	make -e static-bin \${ENV_OVERRIDE}

END
echo "###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=### Build Yices2"
make -f Makefile.yowasp
echo "###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=### DONE"

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### THE END
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
