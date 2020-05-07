# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2020, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

# prepare poolsets with local replica on regular files for testing for each
# version of PMDK
function(prepare_files version)
	setup()

	file(WRITE ${DIR}/pool${version}a
		"PMEMPOOLSET
16M ${DIR}/part${version}a_rep1
REPLICA
16M ${DIR}/part${version}a_rep2")

	execute(0 ${TEST_DIR}/create_${version}
		${DIR}/pool${version}a)

	file(WRITE ${DIR}/pool${version}c
		"PMEMPOOLSET
32M ${DIR}/part${version}c_rep1
REPLICA
32M ${DIR}/part${version}c_rep2")

	execute(0 ${TEST_DIR}/create_${version}
		${DIR}/pool${version}c)
endfunction()

test_intr_tx(prepare_files)

cleanup()
