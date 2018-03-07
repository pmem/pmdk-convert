pmdk-convert: PMDK pool conversion tool
=======================================

### Building The Source ###

Requirements:
- libpmem-dev(el) >= 1.3 (http://pmem.io/pmdk/)
- cmake >= 3.3
- git

```sh
$ git clone https://github.com/marcinslusarz/pmdk-convert.git
$ cd pmdk-convert
$ mkdir build
$ cd build
$ cmake .. -DCMAKE_INSTALL_PREFIX=/home/user/pmdk-convert-bin
$ make
$ make install
```
