#
# Copyright 2018, Intel Corporation
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

setup()

file(WRITE ${DIR}/poolset10 "PMEMPOOLSET\n16M ${DIR}/part10\n")
file(WRITE ${DIR}/poolset11 "PMEMPOOLSET\n16M ${DIR}/part11\n")
file(WRITE ${DIR}/poolset12 "PMEMPOOLSET\n16M ${DIR}/part12\n")
file(WRITE ${DIR}/poolset13 "PMEMPOOLSET\n16M ${DIR}/part13\n")

execute(${CMAKE_CURRENT_BINARY_DIR}/create_10 ${DIR}/poolset10)
execute(${CMAKE_CURRENT_BINARY_DIR}/create_11 ${DIR}/poolset11)
execute(${CMAKE_CURRENT_BINARY_DIR}/create_12 ${DIR}/poolset12)
execute(${CMAKE_CURRENT_BINARY_DIR}/create_13 ${DIR}/poolset13)

execute(${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/poolset10)
execute(${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/poolset11)
execute(${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/poolset12)
execute(${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/poolset13)

execute_expect_failure(${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/poolset10)
execute_expect_failure(${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/poolset10)
execute_expect_failure(${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/poolset10)

execute_expect_failure(${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/poolset11)
execute_expect_failure(${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/poolset11)
execute_expect_failure(${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/poolset11)

execute_expect_failure(${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/poolset12)
execute_expect_failure(${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/poolset12)
execute_expect_failure(${CMAKE_CURRENT_BINARY_DIR}/open_13 ${DIR}/poolset12)

execute_expect_failure(${CMAKE_CURRENT_BINARY_DIR}/open_10 ${DIR}/poolset13)
execute_expect_failure(${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/poolset13)
execute_expect_failure(${CMAKE_CURRENT_BINARY_DIR}/open_12 ${DIR}/poolset13)

execute(${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert ${DIR}/poolset10 0)
#execute(${CMAKE_CURRENT_BINARY_DIR}/open_11 ${DIR}/poolset10)

cleanup()
