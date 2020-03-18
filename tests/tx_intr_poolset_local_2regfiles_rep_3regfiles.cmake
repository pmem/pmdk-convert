# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2019, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

# prepare poolsets with local replica on regular files for testing for
# each version of PMDK
function(prepare_files)
	setup()

	foreach(version ${VERSIONS})
		string(REPLACE "." "" bin_version ${version})

		file(WRITE ${DIR}/pool${bin_version}a
			"PMEMPOOLSET
32M ${DIR}/part${bin_version}a_1
16M ${DIR}/part${bin_version}a_2
REPLICA
12M ${DIR}/part${bin_version}a_3
8M ${DIR}/part${bin_version}a_4
40M ${DIR}/part${bin_version}a_5")

		execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_${bin_version}
				${DIR}/pool${bin_version}a)

		file(WRITE ${DIR}/pool${bin_version}c
			"PMEMPOOLSET
128M ${DIR}/part${bin_version}c_1
48M ${DIR}/part${bin_version}c_2
REPLICA
24M ${DIR}/part${bin_version}c_3
16M ${DIR}/part${bin_version}c_4
32M ${DIR}/part${bin_version}c_5")

		execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_${bin_version}
				${DIR}/pool${bin_version}c)
	endforeach()

endfunction()

test_intr_tx(prepare_files)

#cleanup()
