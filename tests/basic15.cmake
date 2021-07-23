# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2019-2021, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

function(test)
	check_open(${DIR}/pool15 "1.5 1.6")

	# 1.5 -> 1.6
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.6 ${DIR}/pool15 -X fail-safety)
	check_open(${DIR}/pool15 "1.5 1.6")

	# 1.6 -> 1.7
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.7 ${DIR}/pool15 -X fail-safety)
	check_open(${DIR}/pool15 "1.7 1.8 1.9 1.10 1.11")

	# 1.7 -> 1.8
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.8 ${DIR}/pool15 -X fail-safety)
	check_open(${DIR}/pool15 "1.7 1.8 1.9 1.10 1.11")

	# 1.8 -> 1.9
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.9 ${DIR}/pool15 -X fail-safety)
	check_open(${DIR}/pool15 "1.7 1.8 1.9 1.10 1.11")

	# 1.9 -> 1.10
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.10 ${DIR}/pool15 -X fail-safety)
	check_open(${DIR}/pool15 "1.7 1.8 1.9 1.10 1.11")

	# 1.10 -> 1.11
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.11 ${DIR}/pool15 -X fail-safety)
	check_open(${DIR}/pool15 "1.7 1.8 1.9 1.10 1.11")
endfunction(test)

# single file pool
setup()

execute(0 ${TEST_DIR}/create_15 ${DIR}/pool15 16)

test()

# single file poolset
setup()

file(WRITE ${DIR}/pool15 "PMEMPOOLSET\n16M ${DIR}/part15\n")

execute(0 ${TEST_DIR}/create_15 ${DIR}/pool15)

test()

# multi file poolset
setup()

file(WRITE ${DIR}/pool15 "PMEMPOOLSET\n16M ${DIR}/part15_1\n16M ${DIR}/part15_2\n")

execute(0 ${TEST_DIR}/create_15 ${DIR}/pool15)

test()

# poolset with local replica
setup()

file(WRITE ${DIR}/pool15 "PMEMPOOLSET\n16M ${DIR}/part15_rep1\nREPLICA\n16M ${DIR}/part15_rep2\n")
execute(0 ${TEST_DIR}/create_15 ${DIR}/pool15)

test()

# multi file poolset with local replica and SINGLEHDR option

setup()

file(WRITE ${DIR}/pool15
	"PMEMPOOLSET\n"
	"OPTION SINGLEHDR\n"
	"16M ${DIR}/part15_part1_rep1\n"
	"16M ${DIR}/part15_part2_rep1\n"
	"REPLICA\n"
	"16M ${DIR}/part15_part1_rep2\n"
	"16M ${DIR}/part15_part2_rep2\n")

execute(0 ${TEST_DIR}/create_15 ${DIR}/pool15)
test()

# invalid pool
setup()

file(WRITE ${DIR}/not_a_pool "This is not a pool\n")
execute(15 ${EXE_DIR}/pmdk-convert ${DIR}/not_a_pool -X fail-safety --from 1.5) # CONVERT_FAILED

cleanup()
