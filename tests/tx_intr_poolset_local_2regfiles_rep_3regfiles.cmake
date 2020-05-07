# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2020, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

# prepare poolsets with local replica on regular files for testing for
# each version of PMDK
function(prepare_files version)
	setup()

	file(WRITE ${DIR}/pool${version}a
		"PMEMPOOLSET
32M ${DIR}/part${version}a_1
16M ${DIR}/part${version}a_2
REPLICA
12M ${DIR}/part${version}a_3
8M ${DIR}/part${version}a_4
40M ${DIR}/part${version}a_5")

	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_${version}
		${DIR}/pool${version}a)

	file(WRITE ${DIR}/pool${version}c
		"PMEMPOOLSET
128M ${DIR}/part${version}c_1
48M ${DIR}/part${version}c_2
REPLICA
24M ${DIR}/part${version}c_3
16M ${DIR}/part${version}c_4
32M ${DIR}/part${version}c_5")

	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_${version}
			${DIR}/pool${version}c)
endfunction()

test_intr_tx(prepare_files)

#cleanup()
