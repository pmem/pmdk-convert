# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2019, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

# prepare single file pools for testing for each version of PMDK
function(prepare_files)
	setup()

	foreach(version ${VERSIONS})
		string(REPLACE "." "" bin_version ${version})

		execute(0 ${TEST_DIR}/create_${bin_version}
			${DIR}/pool${bin_version}a 16)

		execute(0 ${TEST_DIR}/create_${bin_version}
			${DIR}/pool${bin_version}c 32)
	endforeach()

endfunction()

test_intr_tx(prepare_files)

cleanup()
