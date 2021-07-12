# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2020-2021, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

function(test)
	check_open(${DIR}/pool17 "1.7 1.8 1.9 1.10 1.11")

	# 1.7 -> 1.8
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.8 ${DIR}/pool17 -X fail-safety)
	check_open(${DIR}/pool17 "1.7 1.8 1.9 1.10 1.11")

	# 1.8 -> 1.9
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.9 ${DIR}/pool17 -X fail-safety)
	check_open(${DIR}/pool17 "1.7 1.8 1.9 1.10 1.11")

	# 1.9 -> 1.10
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.10 ${DIR}/pool17 -X fail-safety)
	check_open(${DIR}/pool17 "1.7 1.8 1.9 1.10 1.11")

	# 1.10 -> 1.11
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.11 ${DIR}/pool17 -X fail-safety)
	check_open(${DIR}/pool17 "1.7 1.8 1.9 1.10 1.11")
endfunction(test)

# single file pool
setup()

execute(0 ${TEST_DIR}/create_17 ${DIR}/pool17 16)

test()

# single file poolset
setup()

file(WRITE ${DIR}/pool17 "PMEMPOOLSET\n16M ${DIR}/part17\n")

execute(0 ${TEST_DIR}/create_17 ${DIR}/pool17)

test()

# multi file poolset
setup()

file(WRITE ${DIR}/pool17 "PMEMPOOLSET\n16M ${DIR}/part17_1\n16M ${DIR}/part17_2\n")

execute(0 ${TEST_DIR}/create_17 ${DIR}/pool17)

test()

# poolset with local replica
setup()

file(WRITE ${DIR}/pool17 "PMEMPOOLSET\n16M ${DIR}/part17_rep1\nREPLICA\n16M ${DIR}/part17_rep2\n")
execute(0 ${TEST_DIR}/create_17 ${DIR}/pool17)

test()

# multi file poolset with local replica and SINGLEHDR option

setup()

file(WRITE ${DIR}/pool17
	"PMEMPOOLSET\n"
	"OPTION SINGLEHDR\n"
	"16M ${DIR}/part17_part1_rep1\n"
	"16M ${DIR}/part17_part2_rep1\n"
	"REPLICA\n"
	"16M ${DIR}/part17_part1_rep2\n"
	"16M ${DIR}/part17_part2_rep2\n")

execute(0 ${TEST_DIR}/create_17 ${DIR}/pool17)
test()

# invalid pool
setup()

# uncomment when the layout version is changed
# file(WRITE ${DIR}/not_a_pool "This is not a pool\n")
# execute(15 ${EXE_DIR}/pmdk-convert ${DIR}/not_a_pool -X fail-safety --from 1.7) # CONVERT_FAILED

cleanup()
