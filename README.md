pmdk-convert: PMDK pool conversion tool
=======================================

THIS PROJECT IS IN PRE-ALPHA STAGE. USE PMEMPOOL CONVERT FOR NOW.

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
