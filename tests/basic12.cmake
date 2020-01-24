#
# Copyright 2019-2020, Intel Corporation
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
	check_open(${DIR}/pool12 "1.2")

	# 1.2 -> 1.3
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.3 ${DIR}/pool12 -X fail-safety)
	check_open(${DIR}/pool12 "1.3 1.4")

	# 1.3 -> 1.4
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.4 ${DIR}/pool12 -X fail-safety)
	check_open(${DIR}/pool12 "1.3 1.4")

	# 1.4 -> 1.5
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.5 ${DIR}/pool12 -X fail-safety)
	check_open(${DIR}/pool12 "1.5 1.6")

	# 1.5 -> 1.6
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.6 ${DIR}/pool12 -X fail-safety)
	check_open(${DIR}/pool12 "1.5 1.6")

	# 1.6 -> 1.7
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.7 ${DIR}/pool12 -X fail-safety)
	check_open(${DIR}/pool12 "1.7 1.8")

	# 1.7 -> 1.8
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.8 ${DIR}/pool12 -X fail-safety)
	check_open(${DIR}/pool12 "1.7 1.8")
endfunction(test)

# single file pool
setup()

execute(0 ${TEST_DIR}/create_12 ${DIR}/pool12 16)

test()

# single file poolset
setup()

file(WRITE ${DIR}/pool12 "PMEMPOOLSET\n16M ${DIR}/part12\n")

execute(0 ${TEST_DIR}/create_12 ${DIR}/pool12)

test()

# multi file poolset
setup()

file(WRITE ${DIR}/pool12 "PMEMPOOLSET\n16M ${DIR}/part12_1\n16M ${DIR}/part12_2\n")

execute(0 ${TEST_DIR}/create_12 ${DIR}/pool12)

test()

# poolset with local replica
setup()

file(WRITE ${DIR}/pool12 "PMEMPOOLSET\n16M ${DIR}/part12_rep1\nREPLICA\n16M ${DIR}/part12_rep2\n")
execute(0 ${TEST_DIR}/create_12 ${DIR}/pool12)

test()

# invalid pool
setup()

file(WRITE ${DIR}/not_a_pool "This is not a pool\n")
execute(15 ${EXE_DIR}/pmdk-convert ${DIR}/not_a_pool -X fail-safety --from 1.2) # CONVERT_FAILED

cleanup()
