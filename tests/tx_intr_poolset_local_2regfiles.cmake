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

# prepare poolsets on regular files for testing for each version of PMDK
function(prepare_files)
	setup()

	foreach(version ${VERSIONS})
		string(REPLACE "." "" bin_version ${version})

		file(WRITE ${DIR}/pool${bin_version}a
			"PMEMPOOLSET
16M ${DIR}/part${bin_version}a_1
16M ${DIR}/part${bin_version}a_2")

		execute(0 ${TEST_DIR}/create_${bin_version}
			${DIR}/pool${bin_version}a)

		file(WRITE ${DIR}/pool${bin_version}c
			"PMEMPOOLSET
16M ${DIR}/part${bin_version}c_1
16M ${DIR}/part${bin_version}c_2")
		execute(0 ${TEST_DIR}/create_${bin_version}
			${DIR}/pool${bin_version}c)
	endforeach()

endfunction()

test_intr_tx(prepare_files)

cleanup()
