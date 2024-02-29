#!/bin/sh -ex

### TODO : what is the use of SOURCE_DATE_EPOCH ??
export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### WASI
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
# SETUP pathes and vars
# --------
VERSION_OF_WASI_SDK_MAJOR="19"
VERSION_OF_WASI_SDK="${VERSION_OF_WASI_SDK_MAJOR}.0"
WASI_SDK="wasi-sdk-${VERSION_OF_WASI_SDK}"

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
### SETUP pathes and vars -- GMP
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
VERSION_OF_GMP="6.3.0"
cat >tmp.pathes-gmp.mk <<END
# ---<[GMP pathes]>---
GMP_RELEASE := gmp-${VERSION_OF_GMP}
GMP_SOURCE_DIR := `pwd`/\${GMP_RELEASE}
GMP_BUILD_DIR := `pwd`/\${GMP_RELEASE}-build
GMP_PREFIX_DIR := `pwd`/\${GMP_RELEASE}-prefix"
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
PKG_CONFIG_SYSROOT_DIR := \${SYSROOT}"
END

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### SETUP vars -- YICES
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
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
# Requires : tmp.pathes-wasi.mk, tmp.pathes-gmp.mk, tmp.pathes-yices2.mk

# -- apps
CC := \${WASI_SDK_PATH}/clang
CC_FOR_BUILD := gcc

# -- flags 
SYSROOT := \${WASI_SDK_HOME}/share/wasi-sysroot
CFLAGS := --target=\${TARGET} -D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_PROCESS_CLOCKS --sysroot=\${SYSROOT}
CPPFLAGS := -I\${GMP_PREFIX_DIR}/include -I\${YICES2_SRC_HOME} -I\${YICES2_SRC_HOME}/include
LDFLAGS := -Wl,--strip-all -L\${GMP_PREFIX_DIR}/lib --sysroot=\${SYSROOT}
LIBS_BEGIN := -lwasi-emulated-process-clocks -lwasi-emulated-signal
LIBS_END :=  --sysroot=\${SYSROOT}
LIBS := \${LIBS_BEGIN} -lgmp \${GETOPT_OBJ} \${LIBS_END}
PKG_CONFIG_SYSROOT_DIR := \${SYSROOT}
END

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### Download required projects
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
WASI_SDK_HOME=`pwd`/${WASI_SDK}
WASI_SDK_PATH="${WASI_SDK_HOME}/bin"
WASI_SYSROOT="${WASI_SDK_HOME}/share/wasi-sysroot"
WASI_TOOLS="ar nm objdump ranlib strip"

if ! [ "$(which clang)" -eq "${WASI_SDK_PATH}/clang" ]; then
    export PATH="${WASI_SDK_PATH}:${PATH}"
fi

echo "clang will be '$(which clang)'"

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

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### Preparing builds
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###

### redefining apps
export CC="${WASI_SDK_PATH}/clang"
#export AR="${WASI_SDK_HOME}/bin/llvm-ar"
#export NM="${WASI_SDK_HOME}/bin/llvm-nm"
export CC_FOR_BUILD="gcc"

### defining flags common for BOTH builds
export SYSROOT="${WASI_SDK_HOME}/share/wasi-sysroot"
export CFLAGS="--target=wasm32-unknown-wasi -D_WASI_EMULATED_SIGNAL --sysroot=${SYSROOT}"
export LDFLAGS="-Wl,--strip-all --sysroot=${SYSROOT}"
LIBS_BEGIN="-lwasi-emulated-process-clocks -lwasi-emulated-signal"
LIBS_END=" --sysroot=${SYSROOT}"
export PKG_CONFIG_SYSROOT_DIR="${SYSROOT}"


### others
export TARGET="wasm32-unknown-wasi"
#TARGET="wasm32-wasi"
export ARCH="${TARGET}"

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### Build Gnu MP
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###

export LIBS="${LIBS_BEGIN} ${LIBS_END}"
if ! [ -d ${GMP_PREFIX_DIR} ]; then 
    mkdir "${GMP_PREFIX_DIR}"
    cd ${GMP_PREFIX_DIR}
    if ! [ -f "Makefile.yowasp" ]; then
        cat >Makefile.yowasp <<END
# pathes
include ../tmp.pathes-wasi.mk
include ../tmp.pathes-gmp.mk

# vars
include ../tmp.vars-gmp.mk

lib/libgmp.a: \${GMP_BUILD_DIR}
	cd \${GMP_BUILD_DIR}
	\${GMP_SOURCE_DIR}/configure --host=\${TARGET} --with-sysroot=\${WASI_SYSROOT}
	make
	make install 

\${GMP_BUILD_DIR}:
	mkdir -p \${GMP_BUILD_DIR}
END
    fi
    echo "###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=### Build Gnu MP"
    make -f Makefile.yowasp exec_prefix=${GMP_PREFIX_DIR} prefix=${GMP_PREFIX_DIR}
    echo "###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=### DONE"
    cd ..
fi

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### Build Yices2
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###

pwd
export CFLAGS="--target=wasm32-unknown-wasi -D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_PROCESS_CLOCKS --sysroot=${SYSROOT}"
export LIBS="${LIBS_BEGIN} -lgmp $(pwd)/getopt/getopt_long.o ${LIBS_END}"
#export CPPFLAGS="-I${SYSROOT}/include/wasi -I${GMP_PREFIX_DIR}/include -I${YICES2_SRC_HOME} -I${YICES2_SRC_HOME}/include"
export CPPFLAGS="-I${GMP_PREFIX_DIR}/include -I${YICES2_SRC_HOME} -I${YICES2_SRC_HOME}/include"
export LDFLAGS="-Wl,--strip-all -L${GMP_PREFIX_DIR}/lib --sysroot=${SYSROOT}"
cd yices2-src
cp ${WASI_SDK_HOME}/share/misc/config.guess ${WASI_SDK_HOME}/share/misc/config.sub .
autoconf
./configure --host=${TARGET}
make -e show-config
make -e show-details
make -e static-bin
