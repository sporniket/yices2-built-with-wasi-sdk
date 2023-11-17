#!/bin/sh -ex
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### SETUP vars
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
VERSION_OF_WASI_SDK="19.0"
VERSION_OF_GMP="6.3.0"

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### Download required projects
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)
YICES2_SRC=yices2-src
YICES2_BUILD=yices2-build

###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### Download required projects
###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###=###
### WASI sdk select, check existence or fetch
WASI_SDK="wasi-sdk-${VERSION_OF_WASI_SDK}"
WASI_SDK_URL=https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-19/${WASI_SDK}-linux.tar.gz
if ! [ -d ${WASI_SDK} ]; then curl -L ${WASI_SDK_URL} | tar xzf -; fi
WASI_SDK_HOME=`pwd`/${WASI_SDK}
WASI_SDK_PATH="${WASI_SDK_HOME}/bin"
WASI_TOOLS="ar nm objdump ranlib strip"
for t in ${WASI_TOOLS}; do
    alias "wasm32-unknown-wasi-${t}"="${WASI_SDK_PATH}/${t}"
done
alias

### GNU MP library select source tarball, check existence or fetch
GMP_RELEASE="gmp-${VERSION_OF_GMP}"
GMP_RELEASE_TARBALL="${GMP_RELEASE}.tar"
GMP_RELEASE_TARBALL_LZ="${GMP_RELEASE}.tar.lz"
GMP_RELEASE_URL=https://gmplib.org/download/gmp/${GMP_RELEASE}.tar.lz
if ! [ -d ${GMP_RELEASE} ]; then 
    if ! [ -f ${GMP_RELEASE_TARBALL} ]; then 
        if ! [ -f ${GMP_RELEASE_TARBALL_LZ} ]; then 
            curl -L --output "${GMP_RELEASE_TARBALL_LZ}" ${GMP_RELEASE_URL} 
        fi
        lzip --decompress ${GMP_RELEASE_TARBALL_LZ}
    fi
    tar xf ${GMP_RELEASE_TARBALL}
fi
