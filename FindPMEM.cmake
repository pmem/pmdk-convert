# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018, Intel Corporation

find_path(PMEM_INCLUDE_DIRS libpmem.h)
find_library(PMEM_LIBRARIES NAMES pmem libpmem)

mark_as_advanced(PMEM_LIBRARIES PMEM_INCLUDE_DIRS)
