# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2020, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

list(LENGTH VERSIONS NUM_OF_PMDK_VERSIONS)
math(EXPR NUM_OF_PMDK_VERSIONS "${NUM_OF_PMDK_VERSIONS} - 1")
list(GET VERSIONS 1 OLDEST_VER)
list(GET VERSIONS ${NUM_OF_PMDK_VERSIONS} NEWEST_VER)
string(REPLACE "." "" BIN_VER ${OLDEST_VER})

# argument parsing
setup()

execute(0 ${EXE_DIR}/pmdk-convert --help)
execute(0 ${EXE_DIR}/pmdk-convert --version)

execute(1 ${EXE_DIR}/pmdk-convert) # NOT_ENOUGH_ARGS
execute(2 ${EXE_DIR}/pmdk-convert --force-yes xxx) # UNKNOWN_FLAG
execute(3 ${EXE_DIR}/pmdk-convert --unknown) # UNKNOWN_ARG
execute(4 ${EXE_DIR}/pmdk-convert --from 1.0 --from-layout 1) # FROM_EXCLUSIVE
execute(5 ${EXE_DIR}/pmdk-convert --to 1.1 --to-layout 2) # TO_EXCLUSIVE
execute(6 ${EXE_DIR}/pmdk-convert --from 1.100) # FROM_INVALID
execute(6 ${EXE_DIR}/pmdk-convert --from 110) # FROM_INVALID
execute(6 ${EXE_DIR}/pmdk-convert --from 1.a) # FROM_INVALID
execute(6 ${EXE_DIR}/pmdk-convert --from a.0) # FROM_INVALID
execute(7 ${EXE_DIR}/pmdk-convert --to 1.10.0) # TO_INVALID
execute(8 ${EXE_DIR}/pmdk-convert --from-layout v10) # FROM_LAYOUT_INVALID
execute(9 ${EXE_DIR}/pmdk-convert --to-layout v10) # TO_LAYOUT_INVALID
execute(10 ${EXE_DIR}/pmdk-convert --from 1.0 --to 1.1) # NO_POOL

file(WRITE ${DIR}/not_a_pool "This is not a pool\n")
execute(11 ${EXE_DIR}/pmdk-convert ${DIR}/not_a_pool) # POOL_DETECTION
execute(15 ${EXE_DIR}/pmdk-convert ${DIR}/not_a_pool --from ${OLDEST_VER} -X fail-safety) # CONVERT_FAILED

file(WRITE ${DIR}/pool "PMEMPOOLSET\n16M ${DIR}/part_a\n16M ${DIR}/part_b\n")
execute(0 ${TEST_DIR}/create_${BIN_VER} ${DIR}/pool)
execute(11 ${EXE_DIR}/pmdk-convert ${DIR}/part_a) # POOL_DETECTION
execute(15 ${EXE_DIR}/pmdk-convert ${DIR}/part_b --from ${OLDEST_VER} -X fail-safety) # CONVERT_FAILED

execute(12 ${EXE_DIR}/pmdk-convert ${DIR}/pool --from 2.0) # UNSUPPORTED_FROM
execute(12 ${EXE_DIR}/pmdk-convert ${DIR}/pool --from-layout 7) # UNSUPPORTED_FROM

execute(13 ${EXE_DIR}/pmdk-convert ${DIR}/pool --to 2.0) # UNSUPPORTED_TO
execute(13 ${EXE_DIR}/pmdk-convert ${DIR}/pool --to-layout 7) # UNSUPPORTED_TO

execute(14 ${EXE_DIR}/pmdk-convert ${DIR}/pool --from ${NEWEST_VER} --to ${OLDEST_VER}) # BACKWARD_CONVERSION
execute(14 ${EXE_DIR}/pmdk-convert ${DIR}/pool --from-layout 5 --to-layout 4) # BACKWARD_CONVERSION

file(WRITE ${DIR}/empty_file "")
execute_arg(${DIR}/empty_file 25 ${EXE_DIR}/pmdk-convert ${DIR}/pool) # STDIN_EOF

file(WRITE ${DIR}/yes "Yy\n")
execute_arg(${DIR}/yes 0 ${EXE_DIR}/pmdk-convert ${DIR}/pool)

execute_arg(${DIR}/yes 0 ${EXE_DIR}/pmdk-convert ${DIR}/pool) # nothing to convert

cleanup()
