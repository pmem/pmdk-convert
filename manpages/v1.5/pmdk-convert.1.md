---
layout: manual
Content-Style: 'text/css'
title: PMDK-CONVERT
collection: pmempool
header: PMDK
date: pmem Tools version 1.5
...

[comment]: <> (Copyright 2016-2017, Intel Corporation)

[comment]: <> (Redistribution and use in source and binary forms, with or without)
[comment]: <> (modification, are permitted provided that the following conditions)
[comment]: <> (are met:)
[comment]: <> (    * Redistributions of source code must retain the above copyright)
[comment]: <> (      notice, this list of conditions and the following disclaimer.)
[comment]: <> (    * Redistributions in binary form must reproduce the above copyright)
[comment]: <> (      notice, this list of conditions and the following disclaimer in)
[comment]: <> (      the documentation and/or other materials provided with the)
[comment]: <> (      distribution.)
[comment]: <> (    * Neither the name of the copyright holder nor the names of its)
[comment]: <> (      contributors may be used to endorse or promote products derived)
[comment]: <> (      from this software without specific prior written permission.)

[comment]: <> (THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS)
[comment]: <> ("AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT)
[comment]: <> (LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR)
[comment]: <> (A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT)
[comment]: <> (OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,)
[comment]: <> (SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT)
[comment]: <> (LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,)
[comment]: <> (DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY)
[comment]: <> (THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT)
[comment]: <> ((INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE)
[comment]: <> (OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.)

[comment]: <> (pmdk-convert.1 -- man page for pmdk-convert)

[NAME](#name)<br />
[SYNOPSIS](#synopsis)<br />
[DESCRIPTION](#description)<br />
[EXAMPLE](#example)<br />
[SEE ALSO](#see-also)<br />


# NAME #

**pmdk-convert** - upgrade pool files layout version


# SYNOPSIS #

```
$ pmdk-convert <file>
```


# DESCRIPTION #

The **pmdk-convert** performs a conversion of the specified pool to the newest
layout supported by this tool. Currently only **libpmemobj**(7) pools are supported.

The conversion process is not fail-safe - power interruption may damage the
pool. It is advised to have a backup of the pool before conversion.

This tool doesn't support remote replicas. Before a conversion all remote replicas
have to be removed from the pool by **pmempool transform** command.

##### Options: #####

`-V, --version`

Display version information and exit.

`-h, --help`

Display help and the list of supported layouts and corresponding PMDK versions.

`-f, --from=pmdk-version`

Convert from specified PMDK version. This option is exclusive with -F option.

`-F, --from-layout=version`

Convert from specified layout version. This option is exclusive with -f option.

`-t, --to=version`

convert to specified PMDK version. This option is exclusive with -T option.

`-T, --to-layout=version`

Convert to specified layout version. This option is exclusive with -t option.

`-X, --force-yes=[question]`
reply positively to specified question
possible questions:
- fail-safety
- 1.2-pmemmutex


# EXAMPLE #

```
$ pmempool convert pool.obj
```

Updates pool.obj to the latest layout version.

```
$ pmempool convert pool.obj --from=1.2 --to=1.4
```

Updates pool.obj from PMDK 1.2 to PMDK 1.4


# SEE ALSO #

**pmempool**(1), **libpmemblk**(7), **libpmemlog**(7),
**libpmemobj**(7), **libpmempool**(7) and **<http://pmem.io>**
