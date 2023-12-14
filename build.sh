#!/bin/sh -ex
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### SETUP vars
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
VERSION_OF_WASI_SDK_MAJOR="19"
VERSION_OF_WASI_SDK="${VERSION_OF_WASI_SDK_MAJOR}.0"
VERSION_OF_GMP="6.3.0"

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### Download required projects
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)
YICES2_SRC=yices2-src
YICES2_SRC_HOME=`pwd`/${YICES2_SRC}/src
YICES2_BUILD=yices2-build

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### Download required projects
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### WASI sdk select, check existence or fetch
WASI_SDK="wasi-sdk-${VERSION_OF_WASI_SDK}"
WASI_SDK_URL=https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${VERSION_OF_WASI_SDK_MAJOR}/${WASI_SDK}-linux.tar.gz
if ! [ -d ${WASI_SDK} ]; then curl -L ${WASI_SDK_URL} | tar xzf -; fi
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
    if ! [ -d ${GMP_BUILD_DIR} ]; then 
        mkdir "${GMP_BUILD_DIR}"
        cd ${GMP_BUILD_DIR}
        ../${GMP_RELEASE}/configure --host=${TARGET} --with-sysroot=${WASI_SYSROOT}
        make
        #make check # this fails, but no idea if it's because the 
        # wasified thing must be run using wasm runtime or real failure.
    else
        cd ${GMP_BUILD_DIR}
    fi
    make install exec_prefix=${GMP_PREFIX_DIR} prefix=${GMP_PREFIX_DIR}
    cd ..
fi

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### Build Yices2
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
pwd
${WASI_SDK_PATH}/clang --sysroot ${WASI_SYSROOT} -c getopt_long.c
export CFLAGS="--target=wasm32-unknown-wasi -D_WASI_EMULATED_SIGNAL -D_WASI_EMULATED_PROCESS_CLOCKS --sysroot=${SYSROOT}"
export LIBS="${LIBS_BEGIN} $(pwd)/getopt_long.o ${LIBS_END}"
export CPPFLAGS="-I${GMP_PREFIX_DIR}/include -I${YICES2_SRC_HOME}/include"
export LDFLAGS="-L${GMP_PREFIX_DIR}/lib"
cd yices2-src
cp ${WASI_SDK_HOME}/share/misc/config.guess ${WASI_SDK_HOME}/share/misc/config.sub .
autoconf
./configure --host=${TARGET}
make -e show-config
make -e show-details
make -e
