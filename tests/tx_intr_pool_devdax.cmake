# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2019, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

# prepare single file pools on DAX device for testing for each version of PMDK
function(prepare_files version)
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/clean_pool ${devdax})
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_${version} ${devdax})
	set(pool_file "${devdax}" PARENT_SCOPE)
endfunction()

function(test_devdax test_intr_tx_devdax)
	lock_devdax()
	setup()

	string(REPLACE " " ";" DEVICE_DAX_PATHS ${DEVICE_DAX_PATHS})
	list(GET DEVICE_DAX_PATHS 0 devdax)
	list(LENGTH VERSIONS num)
	math(EXPR num "${num} - 1")
	set(index 1)

	while(index LESS num)
		list(GET VERSIONS ${index} curr_version)
		math(EXPR next "${index} + 1")
		list(GET VERSIONS ${next} next_version)

		# DAX devices are supported from PMDK version 1.2
		if(curr_version VERSION_GREATER "1.1")
			test_intr_tx_devdax(prepare_files ${curr_version} ${next_version})
		endif()

		MATH(EXPR index "${index} + 1")
	endwhile()

	unlock_devdax()
endfunction()

test_devdax(test_intr_tx_devdax)

cleanup()
