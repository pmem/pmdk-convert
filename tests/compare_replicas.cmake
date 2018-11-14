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

function(pmempool_info pool_file output)
	execute_process(COMMAND ${EXE_DIR}/pmempool info -soOaAbd -l -Z -H -C
					${DIR}/${pool_file} OUTPUT_VARIABLE out
					RESULT_VARIABLE ret ERROR_VARIABLE err_msg)
	if(NOT ret EQUAL 0)
		message(FATAL_ERROR "pmempool info failed: ${err_msg}")
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

file(WRITE ${DIR}/pool${bin_version} "PMEMPOOLSET\n
	16M ${DIR}/part${bin_version}_rep1\nREPLICA\n
	16M ${DIR}/part${bin_version}_rep2\n")

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
