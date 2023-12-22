> quickly jotted down readme...

# Yices2 built with WASI-SDK

If succesful, this project is meant to be a part of the [YoWASP](http://yowasp.org/) suite.

This project uses those projects : 

* [Yices2](https://github.com/SRI-CSL/yices2) BUT it uses in fact [a fork](https://github.com/sporniket/yices2) to store some patching in a special branch.
* [WASI-SDK](https://github.com/WebAssembly/wasi-sdk)
* [GNU MP BigNum library](https://gmplib.org)

## How to use this repository

Clone with submodule, then invoke `build.sh`
```
git clone --recurse-submodules https://github.com/sporniket/yices2-built-with-wasi-sdk.git
cd yices2-built-with-wasi-sdk
./build.sh
```

