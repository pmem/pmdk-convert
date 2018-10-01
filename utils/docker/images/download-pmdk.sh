#!/usr/bin/env bash
#
# Copyright 2018, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#
# download-pmdk.sh - download pmdk sources
#

set -e

mkdir /opt/pmdk

wget https://github.com/pmem/pmdk/archive/b7c4d0ae08f7f535e6f8a2b789c2ad3db0ee0858.tar.gz -O /opt/pmdk/nvml-1.4.2.tar.gz
wget https://github.com/pmem/pmdk/archive/1.3.1.tar.gz -O /opt/pmdk/nvml-1.3.1.tar.gz
wget https://github.com/pmem/pmdk/archive/1.2.3.tar.gz -O /opt/pmdk/nvml-1.2.3.tar.gz
wget https://github.com/pmem/pmdk/archive/1.1.tar.gz -O /opt/pmdk/nvml-1.1.tar.gz
wget https://github.com/pmem/pmdk/archive/1.0.tar.gz -O /opt/pmdk/nvml-1.0.tar.gz

# Download and install libpmem-1.4 and libpmempool-1.4 packages
if [ "$1" = "deb" ]; then
	wget https://github.com/pmem/pmdk/releases/download/1.4/pmdk-1.4-dpkgs.tar.gz
	tar -xzf pmdk-1.4-dpkgs.tar.gz
	dpkg -i libpmem_*.deb libpmem-dev*.deb
	dpkg -i libpmempool_*.deb libpmempool-dev*.deb
	rm *.deb pmdk-1.4-dpkgs.tar.gz
elif [ "$1" = "rpm" ]; then
	wget https://github.com/pmem/pmdk/releases/download/1.4/pmdk-1.4-rpms.tar.gz
	tar -xzf pmdk-1.4-rpms.tar.gz
	rpm -i x86_64/libpmem-*.rpm
	rpm -i x86_64/libpmempool-*.rpm
	rm -r x86_64 *.rpm pmdk-1.4-rpms.tar.gz
fi
