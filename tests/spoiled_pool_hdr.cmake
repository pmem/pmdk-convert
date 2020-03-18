# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2019, Intel Corporation

# File contains test which verifies converting the pool with major header
# field changed to 0 and (expected_major + 1) for every available version

include(${SRC_DIR}/helpers.cmake)

setup()

list(LENGTH VERSIONS num)
math(EXPR last_position "${num} - 1")
list(GET VERSIONS ${last_position} newest_version)
string(REPLACE "." "" last_bin_version ${newest_version})

# first PMDK version with the newest layout
set(BEGIN_LATEST_LAYOUT 1.7)

execute(0 ${TEST_DIR}/create_${last_bin_version} ${DIR}/poolTest${last_bin_version} 16)
execute_process(COMMAND ${TEST_DIR}/pmempool-convert info ${DIR}/poolTest${last_bin_version}
	OUTPUT_VARIABLE out RESULT_VARIABLE ret ERROR_VARIABLE err_msg)
if(NOT ret EQUAL 0)
	message(FATAL_ERROR "pmempool-convert info failed: ${err_msg}")
endif()
string(REGEX MATCH "Major +: +[0-9]" out ${out})
string(REGEX REPLACE "[^0-9]+" "" expected_major ${out})
math(EXPR incorrect_version "${expected_major} + 1")
set(index 1)
list(GET VERSIONS 1 min_version)
string(REPLACE "." "" min_version ${min_version})

while(index LESS num)
	list(GET VERSIONS ${index} curr_version)
	string(REPLACE "." "" bin_version ${curr_version})

	if(NOT(bin_version LESS min_version))
		execute(0 ${TEST_DIR}/create_${bin_version} ${DIR}/pool${bin_version} 16)

		execute(0 ${TEST_DIR}/pmemspoil ${DIR}/pool${bin_version} pool_hdr.major=0)
		execute(11 ${EXE_DIR}/pmdk-convert ${DIR}/pool${bin_version} -X fail-safety -X 1.2-pmemmutex)
		execute(2 ${TEST_DIR}/open_${bin_version} ${DIR}/pool${bin_version})

		execute(0 ${TEST_DIR}/pmemspoil ${DIR}/pool${bin_version} pool_hdr.major=${incorrect_version})
		execute(11 ${EXE_DIR}/pmdk-convert ${DIR}/pool${bin_version} -X fail-safety -X 1.2-pmemmutex)
		execute(2 ${TEST_DIR}/open_${bin_version} ${DIR}/pool${bin_version})

		# pmdk-convert skips all checks when from==to, so there's no point in checking that
		if(${curr_version} VERSION_LESS ${BEGIN_LATEST_LAYOUT})
			execute(15 ${EXE_DIR}/pmdk-convert ${DIR}/pool${bin_version} -X fail-safety -X 1.2-pmemmutex --from ${curr_version})
		else()
			execute(0 ${EXE_DIR}/pmdk-convert ${DIR}/pool${bin_version} -X fail-safety -X 1.2-pmemmutex --from ${curr_version})
		endif()
	endif()

	MATH(EXPR index "${index} + 1")

endwhile()

cleanup()
