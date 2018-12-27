#
# Copyright 2018-2019, Intel Corporation
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

# File contains test which verifies converting the pool with major header
# field changed to 0 and (expected_major + 1) for every available version

include(${SRC_DIR}/helpers.cmake)

# get a major number that should be in the newest pool file
function(read_expected_major output)
	list(LENGTH VERSIONS len)
	math(EXPR len ${len}-1)
	list(GET VERSIONS ${len} newest_version)
	string(REGEX REPLACE "[0-9]+." "" out ${newest_version})
	set(${output} ${out} PARENT_SCOPE)
endfunction()

setup()

list(LENGTH VERSIONS num)
math(EXPR last_position "${num} - 1")
list(GET VERSIONS ${last_position}-1 newest_version)
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

		read_expected_major(expected_major)
		math(EXPR incorrect_version "${expected_major} + 1")

		execute(0 ${TEST_DIR}/pmemspoil ${DIR}/pool${bin_version} pool_hdr.major=${incorrect_version})
		execute(11 ${EXE_DIR}/pmdk-convert ${DIR}/pool${bin_version} -X fail-safety -X 1.2-pmemmutex)
		execute(2 ${TEST_DIR}/open_${bin_version} ${DIR}/pool${bin_version})

		# There is no need to check convert 'from' flag with newest version, because it is prevented in pmdk code.
		if(NOT(${curr_version} EQUAL ${newest_version}))
			execute(15 ${EXE_DIR}/pmdk-convert ${DIR}/pool${bin_version} -X fail-safety -X 1.2-pmemmutex --from ${curr_version})
		endif()
	endif()
	
	MATH(EXPR index "${index} + 1")

endwhile()

cleanup()
