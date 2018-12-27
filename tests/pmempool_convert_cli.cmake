#
# Copyright 2018, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

include(${SRC_DIR}/helpers.cmake)

function(call_convert pool_file)
	execute_process(COMMAND ${TEST_DIR}/pmempool-convert convert ${DIR}/${pool_file}
		-X fail-safety -X 1.2-pmemmutex RESULT_VARIABLE ret)
	if(ret EQUAL 0)
		message(FATAL_ERROR "pmempool-convert should not convert spoiled pool")
	endif()
endfunction()

function(read_expected_major output)
	execute_process(COMMAND ${TEST_DIR}/pmempool-convert create obj ${DIR}/poolObjTest
			RESULT_VARIABLE ret ERROR_VARIABLE err_msg)
	if(NOT ret EQUAL 0)
			message(FATAL_ERROR "pmempool-convert create failed: ${err_msg}")
	endif()
	execute_process(COMMAND ${TEST_DIR}/pmempool-convert info ${DIR}/poolObjTest
		OUTPUT_VARIABLE out RESULT_VARIABLE ret ERROR_VARIABLE err_msg)
	if(NOT ret EQUAL 0)
			message(FATAL_ERROR "pmempool-convert info failed: ${err_msg}")
	endif()
	string(REGEX MATCH "Major +: +[0-9]" out ${out})
	string(REGEX REPLACE "[^0-9]+" "" out ${out})
	set(${output} ${out} PARENT_SCOPE)
endfunction()

setup()

execute(0 ${TEST_DIR}/create_10 ${DIR}/pool10 16)

execute(0 ${TEST_DIR}/pmemspoil ${DIR}/pool10 pool_hdr.major=0)
call_convert(pool10)
execute(1 ${TEST_DIR}/pmempool-convert info ${DIR}/pool10)

read_expected_major(expected_major)
math(EXPR expected_major "${expected_major} + 1")

execute(0 ${TEST_DIR}/pmemspoil ${DIR}/pool10 pool_hdr.major=${expected_major})
call_convert(pool10)
execute(1 ${TEST_DIR}/pmempool-convert info ${DIR}/pool10)

cleanup()
