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

function(test)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool10)

	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool11)

	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool12)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool12)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool12)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool12)

	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool13)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool13)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool13)

	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool14)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool14)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool14)

	# 1.0 -> 1.1
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.1 ${DIR}/pool10 -X fail-safety)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool10)
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool10)

	# 1.1 -> 1.2
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.2 ${DIR}/pool10 -X fail-safety -X 1.2-pmemmutex)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool10)
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool10)

	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.2 ${DIR}/pool11 -X fail-safety -X 1.2-pmemmutex)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool11)
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool11)

	# 1.2 -> 1.3
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.3 ${DIR}/pool10 -X fail-safety)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool10)
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool10)

	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.3 ${DIR}/pool11 -X fail-safety)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool11)
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool11)

	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.3 ${DIR}/pool12 -X fail-safety)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool12)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool12)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool12)
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool12)

	# 1.3 -> 1.4
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.4 ${DIR}/pool10 -X fail-safety)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool10)
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool10)

	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.4 ${DIR}/pool11 -X fail-safety)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool11)
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool11)

	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.4 ${DIR}/pool12 -X fail-safety)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool12)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool12)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool12)
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool12)

	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.4 ${DIR}/pool13 -X fail-safety)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool13)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool13)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool13)
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool13)

	# 1.4 -> 1.5
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.5 ${DIR}/pool10 -X fail-safety)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool10)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool10)
	#execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_15 ${DIR}/pool10)

	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.5 ${DIR}/pool11 -X fail-safety)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool11)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool11)
	#execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_15 ${DIR}/pool11)

	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.5 ${DIR}/pool12 -X fail-safety)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool12)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool12)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool12)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool12)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool12)
	#execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_15 ${DIR}/pool12)

	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.5 ${DIR}/pool13 -X fail-safety)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool13)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool13)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool13)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool13)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool13)
	#execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_15 ${DIR}/pool13)

	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --to=1.5 ${DIR}/pool14 -X fail-safety)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool14)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool14)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool14)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool14)
	execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool14)
	#execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_15 ${DIR}/pool14)
endfunction(test)

# single file pool
setup()

file(WRITE ${DIR}/pool10 "PMEMPOOLSET\n16M ${DIR}/part10\n")
file(WRITE ${DIR}/pool11 "PMEMPOOLSET\n16M ${DIR}/part11\n")
file(WRITE ${DIR}/pool12 "PMEMPOOLSET\n16M ${DIR}/part12\n")
file(WRITE ${DIR}/pool13 "PMEMPOOLSET\n16M ${DIR}/part13\n")
file(WRITE ${DIR}/pool14 "PMEMPOOLSET\n16M ${DIR}/part14\n")

execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_10 ${DIR}/pool10)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_11 ${DIR}/pool11)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_12 ${DIR}/pool12)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_13 ${DIR}/pool13)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_14 ${DIR}/pool14)

execute_process(COMMAND ${CMAKE_COMMAND} -E rename ${DIR}/part10 ${DIR}/pool10)
execute_process(COMMAND ${CMAKE_COMMAND} -E rename ${DIR}/part11 ${DIR}/pool11)
execute_process(COMMAND ${CMAKE_COMMAND} -E rename ${DIR}/part12 ${DIR}/pool12)
execute_process(COMMAND ${CMAKE_COMMAND} -E rename ${DIR}/part13 ${DIR}/pool13)
execute_process(COMMAND ${CMAKE_COMMAND} -E rename ${DIR}/part14 ${DIR}/pool14)

test()

# single file poolset
setup()

file(WRITE ${DIR}/pool10 "PMEMPOOLSET\n16M ${DIR}/part10\n")
file(WRITE ${DIR}/pool11 "PMEMPOOLSET\n16M ${DIR}/part11\n")
file(WRITE ${DIR}/pool12 "PMEMPOOLSET\n16M ${DIR}/part12\n")
file(WRITE ${DIR}/pool13 "PMEMPOOLSET\n16M ${DIR}/part13\n")
file(WRITE ${DIR}/pool14 "PMEMPOOLSET\n16M ${DIR}/part14\n")

execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_10 ${DIR}/pool10)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_11 ${DIR}/pool11)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_12 ${DIR}/pool12)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_13 ${DIR}/pool13)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_14 ${DIR}/pool14)

execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool10)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool11)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool12)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool13)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool14)


test()

# multi file poolset
setup()

file(WRITE ${DIR}/pool10 "PMEMPOOLSET\n16M ${DIR}/part10_1\n16M ${DIR}/part10_2\n")
file(WRITE ${DIR}/pool11 "PMEMPOOLSET\n16M ${DIR}/part11_1\n16M ${DIR}/part11_2\n")
file(WRITE ${DIR}/pool12 "PMEMPOOLSET\n16M ${DIR}/part12_1\n16M ${DIR}/part12_2\n")
file(WRITE ${DIR}/pool13 "PMEMPOOLSET\n16M ${DIR}/part13_1\n16M ${DIR}/part13_2\n")
file(WRITE ${DIR}/pool14 "PMEMPOOLSET\n16M ${DIR}/part14_1\n16M ${DIR}/part14_2\n")

execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_10 ${DIR}/pool10)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_11 ${DIR}/pool11)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_12 ${DIR}/pool12)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_13 ${DIR}/pool13)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_14 ${DIR}/pool14)

execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool10)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool11)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool12)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool13)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool14)

test()

# poolset with local replica
setup()

file(WRITE ${DIR}/pool10 "PMEMPOOLSET\n16M ${DIR}/part10_rep1\nREPLICA\n16M ${DIR}/part10_rep2\n")
file(WRITE ${DIR}/pool11 "PMEMPOOLSET\n16M ${DIR}/part11_rep1\nREPLICA\n16M ${DIR}/part11_rep2\n")
file(WRITE ${DIR}/pool12 "PMEMPOOLSET\n16M ${DIR}/part12_rep1\nREPLICA\n16M ${DIR}/part12_rep2\n")
file(WRITE ${DIR}/pool13 "PMEMPOOLSET\n16M ${DIR}/part13_rep1\nREPLICA\n16M ${DIR}/part13_rep2\n")
file(WRITE ${DIR}/pool14 "PMEMPOOLSET\n16M ${DIR}/part14_rep1\nREPLICA\n16M ${DIR}/part14_rep2\n")

execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_10 ${DIR}/pool10)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_11 ${DIR}/pool11)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_12 ${DIR}/pool12)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_13 ${DIR}/pool13)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_14 ${DIR}/pool14)

execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/pool10)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/pool11)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/pool12)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/pool13)
execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool14)

test()

# multi file poolset with local replica and SINGLEHDR option
setup()

file(WRITE ${DIR}/pool14
	"PMEMPOOLSET\n"
	"OPTION SINGLEHDR\n"
	"16M ${DIR}/part14_part1_rep1\n"
	"16M ${DIR}/part14_part2_rep1\n"
	"REPLICA\n"
	"16M ${DIR}/part14_part1_rep2\n"
	"16M ${DIR}/part14_part2_rep2\n")

execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_14 ${DIR}/pool14)

execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool14)

execute(0 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert --from=1.4 --to=1.5 ${DIR}/pool14 -X fail-safety)
execute(2 ${CMAKE_CURRENT_BINARY_DIR}/open_14 ${DIR}/pool14)
#execute(0 ${CMAKE_CURRENT_BINARY_DIR}/open_15 ${DIR}/pool14)

cleanup()
