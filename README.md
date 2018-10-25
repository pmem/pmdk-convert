pmdk-convert: PMDK pool conversion tool
=======================================

[![Build Status](https://travis-ci.org/pmem/pmdk-convert.svg?branch=master)](https://travis-ci.org/pmem/pmdk-convert)
[![Build status](https://ci.appveyor.com/api/projects/status/github/pmem/pmdk-convert?branch/master?svg=true&pr=false)](https://ci.appveyor.com/project/pmem/pmdk-convert/branch/master)
[![Coverage Status](https://codecov.io/github/pmem/pmdk-convert/coverage.svg?branch=master)](https://codecov.io/gh/pmem/pmdk-convert/branch/master)

# Building The Source #

Requirements:
- cmake >= 3.3

On Windows:
- [Windows SDK](https://developer.microsoft.com/en-us/windows/downloads/windows-10-sdk) >= 10.0.16299

In pmdk-convert directory:

```sh
$ mkdir build
$ cd build
```

And then:

### On RPM-based Linux distros (Fedora, openSUSE, RHEL, SLES) ###

```sh
$ cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCPACK_GENERATOR=rpm
$ make package
$ sudo rpm -i pmdk-convert*.rpm
```

### On DEB-based Linux distros (Debian, Ubuntu) ###

```sh
$ cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCPACK_GENERATOR=deb
$ make package
$ sudo dpkg -i pmdk-convert*.deb
```

### On other Linux distros ###
```sh
$ cmake .. -DCMAKE_INSTALL_PREFIX=/home/user/pmdk-convert-bin
$ make
$ make install
```

### On Windows ###

```sh
PS> cmake .. -G "Visual Studio 14 2015 Win64"
PS> msbuild build/ALL_BUILD.vcxproj
```

To build pmdk-convert on Windows 8 you have to specify your SDK version in the cmake command i.e.
```sh
PS> cmake .. -G "Visual Studio 14 2015 Win64" -DCMAKE_SYSTEM_VERSION="10.0.26624"
```
