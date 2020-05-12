# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2020, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

# prepare poolsets with local replica on regular files for testing for each
# version of PMDK
function(prepare_files bin_version)
	setup()

	file(WRITE ${DIR}/pool${bin_version}a
		"PMEMPOOLSET
16M ${DIR}/part${bin_version}a_rep1
REPLICA
16M ${DIR}/part${bin_version}a_rep2")

	execute(0 ${TEST_DIR}/create_${bin_version}
		${DIR}/pool${bin_version}a)

	file(WRITE ${DIR}/pool${bin_version}c
		"PMEMPOOLSET
32M ${DIR}/part${bin_version}c_rep1
REPLICA
32M ${DIR}/part${bin_version}c_rep2")

	execute(0 ${TEST_DIR}/create_${bin_version}
		${DIR}/pool${bin_version}c)
endfunction()

test_intr_tx(prepare_files)

cleanup()
