#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2019, Intel Corporation

#
# download-pmdk.sh - download pmdk sources
#

set -e

mkdir /opt/pmdk


wget https://github.com/pmem/pmdk/archive/cf5d532da36893334b7ec8db0a2b296151733d0e.tar.gz -O /opt/pmdk/cf5d532da36893334b7ec8db0a2b296151733d0e.tar.gz
wget https://github.com/pmem/pmdk/archive/1.5.1.tar.gz -O /opt/pmdk/1.5.1.tar.gz
wget https://github.com/pmem/pmdk/archive/1.4.2.tar.gz -O /opt/pmdk/1.4.2.tar.gz
wget https://github.com/pmem/pmdk/archive/1.3.1.tar.gz -O /opt/pmdk/1.3.1.tar.gz
wget https://github.com/pmem/pmdk/archive/1.2.3.tar.gz -O /opt/pmdk/1.2.3.tar.gz
wget https://github.com/pmem/pmdk/archive/1.1.tar.gz -O /opt/pmdk/1.1.tar.gz
wget https://github.com/pmem/pmdk/archive/1.0.tar.gz -O /opt/pmdk/1.0.tar.gz
