# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2020, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

# prepare poolsets on regular file for testing for each version of PMDK
function(prepare_files bin_version)
	setup()

	file(WRITE ${DIR}/pool${bin_version}a
		"PMEMPOOLSET
16M ${DIR}/part${bin_version}a")

	execute(0 ${TEST_DIR}/create_${bin_version}
			${DIR}/pool${bin_version}a)

	file(WRITE ${DIR}/pool${bin_version}c
		"PMEMPOOLSET
32M ${DIR}/part${bin_version}c")

	execute(0 ${TEST_DIR}/create_${bin_version}
		${DIR}/pool${bin_version}c)
endfunction()

test_intr_tx(prepare_files)

cleanup()
