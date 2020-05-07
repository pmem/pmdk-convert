# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2020, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

# prepare single file pools for testing for each version of PMDK
function(prepare_files bin_version)
	setup()

	execute(0 ${TEST_DIR}/create_${bin_version}
		${DIR}/pool${bin_version}a 16)

	execute(0 ${TEST_DIR}/create_${bin_version}
		${DIR}/pool${bin_version}c 32)
endfunction()

test_intr_tx(prepare_files)

cleanup()
