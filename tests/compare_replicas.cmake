# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

function(pmempool_info pool_file output)
	execute_process(COMMAND ${TEST_DIR}/pmempool-convert info -soOaAbd -l -Z -H -C
					${DIR}/${pool_file} OUTPUT_VARIABLE out
					RESULT_VARIABLE ret ERROR_VARIABLE err_msg)
	if(NOT ret EQUAL 0)
		message(FATAL_ERROR "pmempool-convert info failed: ${err_msg}")
	endif()
	set(${output} ${out} PARENT_SCOPE)
endfunction(pmempool_info)

setup()

list(LENGTH VERSIONS len)
math(EXPR len ${len}-1)
list(GET VERSIONS ${len} newest_version)
math(EXPR len ${len}-1)
list(GET VERSIONS ${len} version)
string(REPLACE "." "" bin_version ${version})

file(WRITE ${DIR}/pool${bin_version} "PMEMPOOLSET
16M ${DIR}/part${bin_version}_rep1
REPLICA
16M ${DIR}/part${bin_version}_rep2")

execute(0 ${TEST_DIR}/create_${bin_version}
		${DIR}/pool${bin_version})

execute(0 ${EXE_DIR}/pmdk-convert --to=${newest_version}
		${DIR}/pool${bin_version} -X fail-safety)

pmempool_info(part${bin_version}_rep1 replica1)
pmempool_info(part${bin_version}_rep2 replica2)

string(REGEX REPLACE "([\n]path)([^\n]*)" "" replica1 ${replica1})
string(REGEX REPLACE "([\n]path)([^\n]*)" "" replica2 ${replica2})
string(REGEX REPLACE "([\n]size)([^\n]*)" "" replica1 ${replica1})
string(REGEX REPLACE "([\n]size)([^\n]*)" "" replica2 ${replica2})
string(REGEX REPLACE "([\n]UUID).*(Checksum)([^\n]*)" "" replica1 ${replica1})
string(REGEX REPLACE "([\n]UUID).*(Checksum)([^\n]*)" "" replica2 ${replica2})

if(NOT "${replica1}" STREQUAL "${replica2}")
	message(FATAL_ERROR "Test compare_replicas failed: replicas are not equal")
endif()

cleanup()
