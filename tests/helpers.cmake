#
# Copyright 2017-2018, Intel Corporation
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

set(DIR ${PARENT_DIR}/${TEST_NAME})
cmake_minimum_required(VERSION 3.3)

function(setup)
	execute_process(COMMAND ${CMAKE_COMMAND} -E remove_directory ${DIR})
	execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${DIR})
	execute_process(COMMAND ${CMAKE_COMMAND} -E remove_directory ${BIN_DIR})
	execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${BIN_DIR})
endfunction()

function(cleanup)
	execute_process(COMMAND ${CMAKE_COMMAND} -E remove_directory ${DIR})
endfunction()

# Executes test command ${name} and verifies its status matches ${expectation}.
# Optional function arguments are passed as consecutive arguments to
# the command.
function(execute_arg input expectation name)
	if(TESTS_USE_FORCED_PMEM)
		set(ENV{PMEM_IS_PMEM_FORCE} 1)
	endif()

	message(STATUS "Executing: ${name} ${ARGN}")
	if("${input}" STREQUAL "")
		execute_process(COMMAND ${name} ${ARGN}
			RESULT_VARIABLE RET
			OUTPUT_FILE ${BIN_DIR}/out
			ERROR_FILE ${BIN_DIR}/err)
	else()
		execute_process(COMMAND ${name} ${ARGN}
			RESULT_VARIABLE RET
			INPUT_FILE ${input}
			OUTPUT_FILE ${BIN_DIR}/out
			ERROR_FILE ${BIN_DIR}/err)
	endif()
	if(TESTS_USE_FORCED_PMEM)
		unset(ENV{PMEM_IS_PMEM_FORCE})
	endif()

	message(STATUS "Test ${name}:")
	file(READ ${BIN_DIR}/out OUT)
	message(STATUS "Stdout:\n${OUT}")
	file(READ ${BIN_DIR}/err ERR)
	message(STATUS "Stderr:\n${ERR}")

	if(NOT RET EQUAL expectation)
		message(FATAL_ERROR "${name} ${ARGN} exit code ${RET} doesn't match expectation ${expectation}")
	endif()
endfunction()

function(execute expectation name)
	execute_arg("" ${expectation} ${name} ${ARGN})
endfunction()
