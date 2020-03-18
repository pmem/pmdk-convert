# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2019, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

# prepare poolset on DAX devices for testing for each version of PMDK
function(prepare_files version)
	file(WRITE ${DIR}/pool${version} "PMEMPOOLSET
AUTO ${devdax_1}
AUTO ${devdax_2}")
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/clean_pool ${devdax_1})
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/clean_pool ${devdax_2})
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_${version}
			${DIR}/pool${version})
	set(pool_file "${DIR}/pool${version}" PARENT_SCOPE)
endfunction()

function(test_devdax test_intr_tx_devdax)
	lock_devdax()
	setup()

	string(REPLACE " " ";" DEVICE_DAX_PATHS ${DEVICE_DAX_PATHS})
	list(GET DEVICE_DAX_PATHS 0 devdax_1)
	list(GET DEVICE_DAX_PATHS 1 devdax_2)
	list(LENGTH VERSIONS num)
	math(EXPR num "${num} - 1")
	set(index 1)

	while(index LESS num)
		list(GET VERSIONS ${index} curr_version)
		math(EXPR next "${index} + 1")
		list(GET VERSIONS ${next} next_version)

		# Multi DAX devices are supported from PMDK version 1.3
		if(curr_version VERSION_GREATER "1.2")
			test_intr_tx_devdax(prepare_files ${curr_version} ${next_version})
		endif()

		MATH(EXPR index "${index} + 1")
	endwhile()

	unlock_devdax()
endfunction()

test_devdax(test_intr_tx_devdax)

cleanup()
