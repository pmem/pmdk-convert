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

set(DIR ${PARENT_DIR}/${TEST_NAME})

function(setup)
	execute_process(COMMAND ${CMAKE_COMMAND} -E remove_directory ${DIR})
	execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${DIR})
	execute_process(COMMAND ${CMAKE_COMMAND} -E remove_directory ${BIN_DIR})
	execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${BIN_DIR})
endfunction()

function(cleanup)
	execute_process(COMMAND ${CMAKE_COMMAND} -E remove_directory ${DIR})
endfunction()

# Generic command executor which stops the test if the executed process
# returns a non-zero value. Useful, as cmake ignores such failures
# by default.
function(execute cmd)
	execute_process(COMMAND ${cmd} ${ARGN}
			RESULT_VARIABLE res)
	if(res)
		message(FATAL_ERROR "${cmd} ${ARGN} failed: ${res}")
	endif()
endfunction()

# Generic command executor which handles failures and returns command output.
function(execute_with_output out cmd)
	execute_process(COMMAND ${cmd} ${ARGN}
			OUTPUT_FILE ${out}
			RESULT_VARIABLE res)
	if(res)
		message(FATAL_ERROR "${cmd} ${ARGN} > ${out} failed: ${res}")
	endif()
endfunction()

# Executes command expecting it to fail.
function(execute_expect_failure cmd)
	execute_process(COMMAND ${cmd} ${ARGN}
			RESULT_VARIABLE res)
	if(NOT res)
		message(FATAL_ERROR "${cmd} ${ARGN} unexpectedly succeeded")
	endif()
endfunction()

# Executes test command ${name} and verifies its status.
# First argument of the command is test directory name.
# Optional function arguments are passed as consecutive arguments to
# the command.
function(execute name)
	if(TESTS_USE_FORCED_PMEM)
		set(ENV{PMEM_IS_PMEM_FORCE} 1)
	endif()

	message(STATUS "Executing: ${name} ${ARGN}")

	execute_process(COMMAND ${name} ${ARGN}
			RESULT_VARIABLE HAD_ERROR
			OUTPUT_FILE ${BIN_DIR}/out
			ERROR_FILE ${BIN_DIR}/err)
	if(TESTS_USE_FORCED_PMEM)
		unset(ENV{PMEM_IS_PMEM_FORCE})
	endif()

	message(STATUS "Test ${name}:")
	file(READ ${BIN_DIR}/out OUT)
	message(STATUS "Stdout:\n${OUT}")
	file(READ ${BIN_DIR}/err ERR)
	message(STATUS "Stderr:\n${ERR}")

	if(HAD_ERROR)
		message(FATAL_ERROR "Test ${name} failed: ${HAD_ERROR}")
	endif()

	if(EXISTS ${SRC_DIR}/err.match)
		match(${BIN_DIR}/err ${SRC_DIR}/err.match)
	endif()
endfunction()
