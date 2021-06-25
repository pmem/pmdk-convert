# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2019-2021, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

function(test)
	check_open(${DIR}/pool10 "1.0")

	# 1.0 -> 1.1
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.1 ${DIR}/pool10 -X fail-safety)
	check_open(${DIR}/pool10 "1.1")

	# 1.1 -> 1.2
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.2 ${DIR}/pool10 -X fail-safety -X 1.2-pmemmutex)
	check_open(${DIR}/pool10 "1.2")

	# 1.2 -> 1.3
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.3 ${DIR}/pool10 -X fail-safety)
	check_open(${DIR}/pool10 "1.3 1.4")

	# 1.3 -> 1.4
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.4 ${DIR}/pool10 -X fail-safety)
	check_open(${DIR}/pool10 "1.3 1.4")

	# 1.4 -> 1.5
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.5 ${DIR}/pool10 -X fail-safety)
	check_open(${DIR}/pool10 "1.5 1.6")

	# 1.5 -> 1.6
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.6 ${DIR}/pool10 -X fail-safety)
	check_open(${DIR}/pool10 "1.5 1.6")

	# 1.6 -> 1.7
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.7 ${DIR}/pool10 -X fail-safety)
	check_open(${DIR}/pool10 "1.7 1.8 1.9 1.10 1.11")

	# 1.7 -> 1.8
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.8 ${DIR}/pool10 -X fail-safety)
	check_open(${DIR}/pool10 "1.7 1.8 1.9 1.10 1.11")

	# 1.8 -> 1.9
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.9 ${DIR}/pool10 -X fail-safety)
	check_open(${DIR}/pool10 "1.7 1.8 1.9 1.10 1.11")

	# 1.9 -> 1.10
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.10 ${DIR}/pool10 -X fail-safety)
	check_open(${DIR}/pool10 "1.7 1.8 1.9 1.10 1.11")

	# 1.10 -> 1.11
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.11 ${DIR}/pool10 -X fail-safety)
	check_open(${DIR}/pool10 "1.7 1.8 1.9 1.10 1.11")
endfunction(test)

# single file pool
setup()

execute(0 ${TEST_DIR}/create_10 ${DIR}/pool10 16)

test()

# single file poolset
setup()

file(WRITE ${DIR}/pool10 "PMEMPOOLSET\n16M ${DIR}/part10\n")

execute(0 ${TEST_DIR}/create_10 ${DIR}/pool10)
execute(0 ${TEST_DIR}/open_10 ${DIR}/pool10)

test()

# multi file poolset
setup()

file(WRITE ${DIR}/pool10 "PMEMPOOLSET\n16M ${DIR}/part10_1\n16M ${DIR}/part10_2\n")

execute(0 ${TEST_DIR}/create_10 ${DIR}/pool10)
execute(0 ${TEST_DIR}/open_10 ${DIR}/pool10)
test()

# poolset with local replica
setup()

file(WRITE ${DIR}/pool10 "PMEMPOOLSET\n16M ${DIR}/part10_rep1\nREPLICA\n16M ${DIR}/part10_rep2\n")
execute(0 ${TEST_DIR}/create_10 ${DIR}/pool10)
execute(0 ${TEST_DIR}/open_10 ${DIR}/pool10)

test()

# invalid pool
setup()

file(WRITE ${DIR}/not_a_pool "This is not a pool\n")
execute(15 ${EXE_DIR}/pmdk-convert ${DIR}/not_a_pool -X fail-safety --from 1.0) # CONVERT_FAILED

cleanup()
