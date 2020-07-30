# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2019-2020, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

function(test)
	check_open(${DIR}/pool14 "1.4")

	# 1.4 -> 1.5
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.5 ${DIR}/pool14 -X fail-safety)
	check_open(${DIR}/pool14 "1.5 1.6")

	# 1.5 -> 1.6
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.6 ${DIR}/pool14 -X fail-safety)
	check_open(${DIR}/pool14 "1.5 1.6")

	# 1.6 -> 1.7
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.7 ${DIR}/pool14 -X fail-safety)
	check_open(${DIR}/pool14 "1.7 1.8 1.9")

	# 1.7 -> 1.8
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.8 ${DIR}/pool14 -X fail-safety)
	check_open(${DIR}/pool14 "1.7 1.8 1.9")

	# 1.8 -> 1.9
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.9 ${DIR}/pool14 -X fail-safety)
	check_open(${DIR}/pool14 "1.7 1.8 1.9")
endfunction(test)

# single file pool
setup()

execute(0 ${TEST_DIR}/create_14 ${DIR}/pool14 16)

test()

# single file poolset
setup()

file(WRITE ${DIR}/pool14 "PMEMPOOLSET\n16M ${DIR}/part14\n")

execute(0 ${TEST_DIR}/create_14 ${DIR}/pool14)

test()

# multi file poolset
setup()

file(WRITE ${DIR}/pool14 "PMEMPOOLSET\n16M ${DIR}/part14_1\n16M ${DIR}/part14_2\n")

execute(0 ${TEST_DIR}/create_14 ${DIR}/pool14)

test()

# poolset with local replica
setup()

file(WRITE ${DIR}/pool14 "PMEMPOOLSET\n16M ${DIR}/part14_rep1\nREPLICA\n16M ${DIR}/part14_rep2\n")
execute(0 ${TEST_DIR}/create_14 ${DIR}/pool14)

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

execute(0 ${TEST_DIR}/create_14 ${DIR}/pool14)
test()

# invalid pool
setup()

file(WRITE ${DIR}/not_a_pool "This is not a pool\n")
execute(15 ${EXE_DIR}/pmdk-convert ${DIR}/not_a_pool -X fail-safety --from 1.4) # CONVERT_FAILED

cleanup()
