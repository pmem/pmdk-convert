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

	string(REPLACE "." "" curr_bin_version ${MIN_VERSION})
	string(REPLACE "." "" max_bin_version ${MAX_VERSION})
	#temporarily, so far version 1.5 is not available
	MATH(EXPR max_bin_version "${max_bin_version} - 1")

	while(curr_bin_version LESS max_bin_version)
		file(WRITE ${DIR}/pool${curr_bin_version}a
			"PMEMPOOLSET\n16M ${DIR}/part${curr_bin_version}a\n")
		execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_${curr_bin_version}
			${DIR}/pool${curr_bin_version}a)
		execute_process(COMMAND ${CMAKE_COMMAND} -E rename
			${DIR}/part${curr_bin_version}a ${DIR}/pool${curr_bin_version}a)

		file(WRITE ${DIR}/pool${curr_bin_version}c
			"PMEMPOOLSET\n16M ${DIR}/part${curr_bin_version}c\n")
		execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_${curr_bin_version}
			${DIR}/pool${curr_bin_version}c)
		execute_process(COMMAND ${CMAKE_COMMAND} -E rename
			${DIR}/part${curr_bin_version}c ${DIR}/pool${curr_bin_version}c)

		MATH(EXPR curr_bin_version "${curr_bin_version} + 1")
	endwhile()

endfunction()

function(test)
	set(curr_scenario 0)
	set(last_scenario 9)

	while(NOT curr_scenario GREATER last_scenario)
		prepare_files()

		set(curr_version ${MIN_VERSION})
		string(REPLACE "." "" curr_bin_version ${curr_version})
		string(REPLACE "." "" max_bin_version ${MAX_VERSION})
		#temporarily, so far version 1.5 is not available
		MATH(EXPR max_bin_version "${max_bin_version} - 1")

		while(curr_bin_version LESS max_bin_version)
			calculate("${curr_version} + 0.1" next_version)
			MATH(EXPR next_bin_version "${curr_bin_version} + 1")

			if(next_version EQUAL "1.2")
				set(mutex "1.2-pmemmutex")
				set(option "-X")
			else()
				unset(mutex)
				unset(option)
			endif()

			execute(0 gdb --batch
				--command=${SRC_DIR}/trip_on_pre_commit.gdb
				--args ${CMAKE_CURRENT_BINARY_DIR}/transaction_${curr_bin_version}
				${DIR}/pool${curr_bin_version}a c ${curr_scenario})
			execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert
				--to=${next_version} ${DIR}/pool${curr_bin_version}a
				-X fail-safety ${option} ${mutex})
			execute(0
				${CMAKE_CURRENT_BINARY_DIR}/transaction_${next_bin_version}
				${DIR}/pool${curr_bin_version}a va ${curr_scenario})

			execute(0 gdb --batch
				--command=${SRC_DIR}/trip_on_post_commit.gdb
				--args ${CMAKE_CURRENT_BINARY_DIR}/transaction_${curr_bin_version}
				${DIR}/pool${curr_bin_version}c c ${curr_scenario})
			execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert
				--to=${next_version} ${DIR}/pool${curr_bin_version}c
				-X fail-safety ${option} ${mutex})
			execute(0
				${CMAKE_CURRENT_BINARY_DIR}/transaction_${next_bin_version}
				${DIR}/pool${curr_bin_version}c vc ${curr_scenario})

			MATH(EXPR curr_bin_version "${curr_bin_version} + 1")
			calculate("${curr_version} + 0.1" curr_version)
		endwhile()
		MATH(EXPR curr_scenario "${curr_scenario} + 1")
	endwhile()

endfunction(test)

test()

cleanup()
