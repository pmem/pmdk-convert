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

# prepare single file pools on DAX device for testing for each version of PMDK
function(prepare_files version)
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/clean_pool ${devdax})
	execute(0 ${CMAKE_CURRENT_BINARY_DIR}/create_${version} ${devdax})
	set(pool_file "${devdax}" PARENT_SCOPE)
endfunction()

function(test_devdax test_intr_tx_devdax)
	lock_devdax()
	setup()

	string(REPLACE " " ";" DEVICE_DAX_PATHS ${DEVICE_DAX_PATHS})
	list(GET DEVICE_DAX_PATHS 0 devdax)
	list(LENGTH VERSIONS num)
	math(EXPR num "${num} - 1")
	set(index 1)

	while(index LESS num)
		list(GET VERSIONS ${index} curr_version)
		math(EXPR next "${index} + 1")
		list(GET VERSIONS ${next} next_version)

		# DAX devices are supported from PMDK version 1.2
		if(curr_version VERSION_GREATER "1.1")
			test_intr_tx_devdax(prepare_files ${curr_version} ${next_version})
		endif()
		
		MATH(EXPR index "${index} + 1")
	endwhile()
	
	unlock_devdax()
endfunction()

test_devdax(test_intr_tx_devdax)

cleanup()
