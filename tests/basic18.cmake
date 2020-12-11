# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2020, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

function(test)
	check_open(${DIR}/pool18 "1.7 1.8 1.9 1.10")

	# 1.8 -> 1.9
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.9 ${DIR}/pool18 -X fail-safety)
	check_open(${DIR}/pool18 "1.7 1.8 1.9 1.10")

	# 1.9 -> 1.10
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.10 ${DIR}/pool18 -X fail-safety)
	check_open(${DIR}/pool18 "1.7 1.8 1.9 1.10")
endfunction(test)

# single file pool
setup()

execute(0 ${TEST_DIR}/create_18 ${DIR}/pool18 16)

test()

# single file poolset
setup()

file(WRITE ${DIR}/pool18 "PMEMPOOLSET\n16M ${DIR}/part18\n")

execute(0 ${TEST_DIR}/create_18 ${DIR}/pool18)

test()

# multi file poolset
setup()

file(WRITE ${DIR}/pool18 "PMEMPOOLSET\n16M ${DIR}/part18_1\n16M ${DIR}/part18_2\n")

execute(0 ${TEST_DIR}/create_18 ${DIR}/pool18)

test()

# poolset with local replica
setup()

file(WRITE ${DIR}/pool18 "PMEMPOOLSET\n16M ${DIR}/part18_rep1\nREPLICA\n16M ${DIR}/part18_rep2\n")
execute(0 ${TEST_DIR}/create_18 ${DIR}/pool18)

test()

# multi file poolset with local replica and SINGLEHDR option

setup()

file(WRITE ${DIR}/pool18
	"PMEMPOOLSET\n"
	"OPTION SINGLEHDR\n"
	"16M ${DIR}/part18_part1_rep1\n"
	"16M ${DIR}/part18_part2_rep1\n"
	"REPLICA\n"
	"16M ${DIR}/part18_part1_rep2\n"
	"16M ${DIR}/part18_part2_rep2\n")

execute(0 ${TEST_DIR}/create_18 ${DIR}/pool18)
test()

# invalid pool
setup()

cleanup()
