# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2019-2020, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

function(test)
	check_open(${DIR}/pool11 "1.1")

	# 1.1 -> 1.2
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.2 ${DIR}/pool11 -X fail-safety -X 1.2-pmemmutex)
	check_open(${DIR}/pool11 "1.2")

	# 1.2 -> 1.3
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.3 ${DIR}/pool11 -X fail-safety)
	check_open(${DIR}/pool11 "1.3 1.4")

	# 1.3 -> 1.4
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.4 ${DIR}/pool11 -X fail-safety)
	check_open(${DIR}/pool11 "1.3 1.4")

	# 1.4 -> 1.5
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.5 ${DIR}/pool11 -X fail-safety)
	check_open(${DIR}/pool11 "1.5 1.6")

	# 1.5 -> 1.6
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.6 ${DIR}/pool11 -X fail-safety)
	check_open(${DIR}/pool11 "1.5 1.6")

	# 1.6 -> 1.7
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.7 ${DIR}/pool11 -X fail-safety)
	check_open(${DIR}/pool11 "1.7 1.8 1.9 1.10")

	# 1.7 -> 1.8
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.8 ${DIR}/pool11 -X fail-safety)
	check_open(${DIR}/pool11 "1.7 1.8 1.9 1.10")

	# 1.8 -> 1.9
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.9 ${DIR}/pool11 -X fail-safety)
	check_open(${DIR}/pool11 "1.7 1.8 1.9 1.10")

	# 1.9 -> 1.10
	execute(0 ${EXE_DIR}/pmdk-convert --to=1.10 ${DIR}/pool11 -X fail-safety)
	check_open(${DIR}/pool11 "1.7 1.8 1.9 1.10")
endfunction(test)

# single file pool
setup()

execute(0 ${TEST_DIR}/create_11 ${DIR}/pool11 16)

test()

# single file poolset
setup()

file(WRITE ${DIR}/pool11 "PMEMPOOLSET\n16M ${DIR}/part11\n")
execute(0 ${TEST_DIR}/create_11 ${DIR}/pool11)

test()

# multi file poolset
setup()

file(WRITE ${DIR}/pool11 "PMEMPOOLSET\n16M ${DIR}/part11_1\n16M ${DIR}/part11_2\n")
execute(0 ${TEST_DIR}/create_11 ${DIR}/pool11)

test()

# poolset with local replica
setup()

file(WRITE ${DIR}/pool11 "PMEMPOOLSET\n16M ${DIR}/part11_rep1\nREPLICA\n16M ${DIR}/part11_rep2\n")
execute(0 ${TEST_DIR}/create_11 ${DIR}/pool11)

test()

setup()

file(WRITE ${DIR}/not_a_pool "This is not a pool\n")
execute(15 ${EXE_DIR}/pmdk-convert ${DIR}/not_a_pool -X fail-safety --from 1.1) # CONVERT_FAILED

cleanup()
