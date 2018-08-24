pmdk-convert: PMDK pool conversion tool
=======================================

THIS PROJECT IS IN PRE-ALPHA STAGE. USE PMEMPOOL CONVERT FOR NOW.

[![Build Status](https://travis-ci.org/pmem/pmdk-convert.svg?branch=master)](https://travis-ci.org/pmem/pmdk-convert)
[![Coverage Status](https://codecov.io/github/pmem/pmdk-convert/coverage.svg?branch=master)](https://codecov.io/gh/pmem/pmdk-convert/branch/master)

### Building The Source ###

Requirements:
- libpmem-dev(el) >= 1.3 (http://pmem.io/pmdk/)
- cmake >= 3.3
- git

```sh
$ git clone https://github.com/pmem/pmdk-convert.git
$ cd pmdk-convert
$ mkdir build
$ cd build
$ cmake .. -DCMAKE_INSTALL_PREFIX=/home/user/pmdk-convert-bin
$ make
$ make install
```
