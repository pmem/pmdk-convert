# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2022, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

function(test)
	check_open(${DIR}/pool111 "1.7 1.8 1.9 1.10 1.11 1.12")

	# 1.11 -> 1.12
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.12 ${DIR}/pool111 -X fail-safety)
	check_open(${DIR}/pool111 "1.7 1.8 1.9 1.10 1.11 1.12")
endfunction(test)

# single file pool
setup()

execute(0 ${TEST_DIR}/create_111 ${DIR}/pool111 16)

test()

# single file poolset
setup()

file(WRITE ${DIR}/pool111 "PMEMPOOLSET\n16M ${DIR}/part111\n")

execute(0 ${TEST_DIR}/create_111 ${DIR}/pool111)

test()

# multi file poolset
setup()

file(WRITE ${DIR}/pool111 "PMEMPOOLSET\n16M ${DIR}/part111_1\n16M ${DIR}/part111_2\n")

execute(0 ${TEST_DIR}/create_111 ${DIR}/pool111)

test()

# poolset with local replica
setup()

file(WRITE ${DIR}/pool111 "PMEMPOOLSET\n16M ${DIR}/part111_rep1\nREPLICA\n16M ${DIR}/part111_rep2\n")
execute(0 ${TEST_DIR}/create_111 ${DIR}/pool111)

test()

# multi file poolset with local replica and SINGLEHDR option

setup()

file(WRITE ${DIR}/pool111
	"PMEMPOOLSET\n"
	"OPTION SINGLEHDR\n"
	"16M ${DIR}/part111_part1_rep1\n"
	"16M ${DIR}/part111_part2_rep1\n"
	"REPLICA\n"
	"16M ${DIR}/part111_part1_rep2\n"
	"16M ${DIR}/part111_part2_rep2\n")

execute(0 ${TEST_DIR}/create_111 ${DIR}/pool111)
test()

# invalid pool
setup()

cleanup()
