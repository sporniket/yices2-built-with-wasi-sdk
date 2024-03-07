> quickly jotted down readme...

```
Unofficial Yices2 WebAssembly packages

Copyright (C) 2023 - 2024 David SPORN <sporniket.studio@gmail.com>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

```

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

