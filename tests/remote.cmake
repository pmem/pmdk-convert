# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018, Intel Corporation

include(${SRC_DIR}/helpers.cmake)

list(GET VERSIONS 1 VER)
string(REPLACE "." "" VER ${VER})

setup()

file(WRITE ${DIR}/pool "PMEMPOOLSET\n16M ${DIR}/part\nREPLICA user@example.com remote-objpool.set\n")
execute(23 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert ${DIR}/pool)

setup()
file(WRITE ${DIR}/pool "PMEMPOOLSET\n16M ${DIR}/part\nREPLICA          user@example.com remote-objpool.set # abcdefgh\n")
execute(23 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert ${DIR}/pool --from-layout 4 --to-layout 5)

setup()
file(WRITE ${DIR}/pool "PMEMPOOLSET\n16M ${DIR}/part\nREPLICA  a\n")
execute(23 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert ${DIR}/pool --from-layout 4 --to-layout 5)

setup()
file(WRITE ${DIR}/pool "PMEMPOOLSET\n16M ${DIR}/part\nREPLICA # user@example.com remote-objpool.set\n16M ${DIR}/replica")
execute(23 ${CMAKE_CURRENT_BINARY_DIR}/../pmdk-convert ${DIR}/pool --from-layout 4 --to-layout 5 -X fail-safety)

cleanup()
