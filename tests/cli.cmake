#
# Copyright 2018-2019, Intel Corporation
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
execute(6 ${EXE_DIR}/pmdk-convert --from 1.10) # FROM_INVALID
execute(6 ${EXE_DIR}/pmdk-convert --from 110) # FROM_INVALID
execute(6 ${EXE_DIR}/pmdk-convert --from 1.a) # FROM_INVALID
execute(6 ${EXE_DIR}/pmdk-convert --from a.0) # FROM_INVALID
execute(7 ${EXE_DIR}/pmdk-convert --to 1.10) # TO_INVALID
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

execute(12 ${EXE_DIR}/pmdk-convert ${DIR}/pool --from 1.8) # UNSUPPORTED_FROM
execute(12 ${EXE_DIR}/pmdk-convert ${DIR}/pool --from-layout 7) # UNSUPPORTED_FROM

execute(13 ${EXE_DIR}/pmdk-convert ${DIR}/pool --to 1.8) # UNSUPPORTED_TO
execute(13 ${EXE_DIR}/pmdk-convert ${DIR}/pool --to-layout 7) # UNSUPPORTED_TO

execute(14 ${EXE_DIR}/pmdk-convert ${DIR}/pool --from ${NEWEST_VER} --to ${OLDEST_VER}) # BACKWARD_CONVERSION
execute(14 ${EXE_DIR}/pmdk-convert ${DIR}/pool --from-layout 5 --to-layout 4) # BACKWARD_CONVERSION

file(WRITE ${DIR}/empty_file "")
execute_arg(${DIR}/empty_file 25 ${EXE_DIR}/pmdk-convert ${DIR}/pool) # STDIN_EOF

file(WRITE ${DIR}/yes "Yy\n")
execute_arg(${DIR}/yes 0 ${EXE_DIR}/pmdk-convert ${DIR}/pool)

execute_arg(${DIR}/yes 0 ${EXE_DIR}/pmdk-convert ${DIR}/pool) # nothing to convert

cleanup()
