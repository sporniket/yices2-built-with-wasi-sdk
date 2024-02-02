#!/bin/bash
rm -Rf gmp-6.3.0-*
rm -Rf yices2-src/build/wasm32-unknown-wasi-release/ yices2-src/configs/make.include.wasm32-unknown-wasi
[ -f getopt/getopt_long.o ] && rm getopt/getopt_long.o
