# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2019-2020, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

function(test)
	check_open(${DIR}/pool13 "1.3 1.4")

	# 1.3 -> 1.4
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.4 ${DIR}/pool13 -X fail-safety)
	check_open(${DIR}/pool13 "1.3 1.4")

	# 1.4 -> 1.5
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.5 ${DIR}/pool13 -X fail-safety)
	check_open(${DIR}/pool13 "1.5 1.6")

	# 1.5 -> 1.6
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.6 ${DIR}/pool13 -X fail-safety)
	check_open(${DIR}/pool13 "1.5 1.6")

	# 1.6 -> 1.7
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.7 ${DIR}/pool13 -X fail-safety)
	check_open(${DIR}/pool13 "1.7 1.8")

	# 1.7 -> 1.8
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.8 ${DIR}/pool13 -X fail-safety)
	check_open(${DIR}/pool13 "1.7 1.8")
endfunction(test)

# single file pool
setup()

execute(0 ${TEST_DIR}/create_13 ${DIR}/pool13 16)

test()

# single file poolset
setup()

file(WRITE ${DIR}/pool13 "PMEMPOOLSET\n16M ${DIR}/part13\n")

execute(0 ${TEST_DIR}/create_13 ${DIR}/pool13)

test()

# multi file poolset
setup()

file(WRITE ${DIR}/pool13 "PMEMPOOLSET\n16M ${DIR}/part13_1\n16M ${DIR}/part13_2\n")

execute(0 ${TEST_DIR}/create_13 ${DIR}/pool13)

test()

# poolset with local replica
setup()

file(WRITE ${DIR}/pool13 "PMEMPOOLSET\n16M ${DIR}/part13_rep1\nREPLICA\n16M ${DIR}/part13_rep2\n")
execute(0 ${TEST_DIR}/create_13 ${DIR}/pool13)

test()

# invalid pool
setup()

file(WRITE ${DIR}/not_a_pool "This is not a pool\n")
execute(15 ${EXE_DIR}/pmdk-convert ${DIR}/not_a_pool -X fail-safety --from 1.3) # CONVERT_FAILED

cleanup()
