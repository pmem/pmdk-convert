# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2020, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

# prepare poolsets on regular file for testing for each version of PMDK
function(prepare_files version)
	setup()

	file(WRITE ${DIR}/pool${version}a
		"PMEMPOOLSET
16M ${DIR}/part${version}a")

	execute(0 ${TEST_DIR}/create_${version}
			${DIR}/pool${version}a)

	file(WRITE ${DIR}/pool${version}c
		"PMEMPOOLSET
32M ${DIR}/part${version}c")

	execute(0 ${TEST_DIR}/create_${version}
		${DIR}/pool${version}c)
endfunction()

test_intr_tx(prepare_files)

cleanup()
