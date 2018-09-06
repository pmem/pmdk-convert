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

# prepare single file pools for testing for each version of PMDK
function(prepare_files)
	setup()

	foreach(version ${VERSIONS})
		string(REPLACE "." "" bin_version ${version})
		execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_${bin_version}
				${DIR}/pool${bin_version}a 16)
		execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_${bin_version}
				${DIR}/pool${bin_version}c 16)
	endforeach()

endfunction()

set(curr_scenario 0)
set(last_scenario 9)

list(LENGTH VERSIONS num)
math(EXPR num "${num} - 1")

while(NOT curr_scenario GREATER last_scenario)
	prepare_files()
	set(index 1)

	while(index LESS num)
		list(GET VERSIONS ${index} curr_version)

		math(EXPR next "${index}+1")
		list(GET VERSIONS ${next} next_version)

		string(REPLACE "." "" curr_bin_version ${curr_version})
		string(REPLACE "." "" next_bin_version ${next_version})

		if(next_version EQUAL "1.2")
			set(mutex "-X;1.2-pmemmutex")
		else()
			unset(mutex)
		endif()

		execute(0 gdb --batch
			--command=${SRC_DIR}/trip_on_pre_commit.gdb
			--args ${CMAKE_CURRENT_BINARY_DIR}/transaction_${curr_bin_version}
			${DIR}/pool${curr_bin_version}a c ${curr_scenario})
		execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert
			--to=${next_version} ${DIR}/pool${curr_bin_version}a
			-X fail-safety ${mutex})
		execute(0
			${CMAKE_CURRENT_BINARY_DIR}/transaction_${next_bin_version}
			${DIR}/pool${curr_bin_version}a va ${curr_scenario})

		execute(0 gdb --batch
			--command=${SRC_DIR}/trip_on_post_commit.gdb
			--args ${CMAKE_CURRENT_BINARY_DIR}/transaction_${curr_bin_version}
			${DIR}/pool${curr_bin_version}c c ${curr_scenario})
		execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert
			--to=${next_version} ${DIR}/pool${curr_bin_version}c
			-X fail-safety ${mutex})
		execute(0
			${CMAKE_CURRENT_BINARY_DIR}/transaction_${next_bin_version}
			${DIR}/pool${curr_bin_version}c vc ${curr_scenario})

		MATH(EXPR index "${index} + 1")
	endwhile()

	MATH(EXPR curr_scenario "${curr_scenario} + 1")
endwhile()

cleanup()
