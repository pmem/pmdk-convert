#
# Copyright 2017-2019, Intel Corporation
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

cmake_minimum_required(VERSION 3.3)
set(DIR ${PARENT_DIR}/😘⠝⠧⠍⠇ɗPMDKӜ⥺🙋${TEST_NAME})

# convert the version list to the array
string(REPLACE " " ";" VERSIONS ${VERSIONS})

if(WIN32)
	set(EXE_DIR ${CMAKE_CURRENT_BINARY_DIR}/../${CONFIG})
	set(TEST_DIR ${CMAKE_CURRENT_BINARY_DIR}/../tests/${CONFIG})
else()
	set(EXE_DIR ${CMAKE_CURRENT_BINARY_DIR}/../)
	set(TEST_DIR ${CMAKE_CURRENT_BINARY_DIR}/../tests/)
endif()

# tries to open the ${pool} with all PMDK ${VERSIONS}
# expect a success when a pmdk version is on the ${correct} list
function(check_open pool correct)
	string(REPLACE " " ";" correct ${correct})
	foreach(it ${VERSIONS})
		string(REPLACE "." "" app ${it})
		if (${it} IN_LIST correct)
			execute(0 ${TEST_DIR}/open_${app} ${pool})
		else()
			execute(2 ${TEST_DIR}/open_${app} ${pool})
		endif()
	endforeach(it)
endfunction(check_open)

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


function(execute_cdb SRC_VERSION SCENARIO)
	set(CDB_PRE_COMMIT_COMMAND "bm pmemobj_${SRC_VERSION}!tx_pre_commit \"
	.if ( poi (transaction_${SRC_VERSION}!trap) == 1 ) {} .else {gc}\"\;g\;q")
	set(CDB_POST_COMMIT_COMMAND "bm pmemobj_${SRC_VERSION}!tx_post_commit \"
	.if ( poi (transaction_${SRC_VERSION}!trap) == 1 ) {} .else {gc}\"\;g\;q")

	if(TESTS_USE_FORCED_PMEM)
		set(ENV{PMEM_IS_PMEM_FORCE} 1)
	endif()
	execute_process(COMMAND ${CDB_PATH}/cdb.exe -c ${CDB_PRE_COMMIT_COMMAND}
			${TEST_DIR}/transaction_${SRC_VERSION}
			${DIR}/pool${SRC_VERSION}a c ${SCENARIO}
			RESULT_VARIABLE CDB_RET)
	execute_process(COMMAND ${CDB_PATH}/cdb.exe -c ${CDB_POST_COMMIT_COMMAND}
			${TEST_DIR}/transaction_${SRC_VERSION}
			${DIR}/pool${SRC_VERSION}c c ${SCENARIO}
			RESULT_VARIABLE CDB_RET)

	if(TESTS_USE_FORCED_PMEM)
		unset(ENV{PMEM_IS_PMEM_FORCE})
	endif()
endfunction()

function(test_intr_tx prepare_files)
	set(curr_scenario 0)
	set(last_scenario 9)

	list(LENGTH VERSIONS num)
	math(EXPR num "${num} - 1")

	while(NOT curr_scenario GREATER last_scenario)
		prepare_files()
		set(index 1)

		while(index LESS num)
			list(GET VERSIONS ${index} curr_version)

			math(EXPR next "${index} + 1")
			list(GET VERSIONS ${next} next_version)

			string(REPLACE "." "" curr_bin_version ${curr_version})
			string(REPLACE "." "" next_bin_version ${next_version})

			if(next_version EQUAL "1.2")
				set(mutex "-X;1.2-pmemmutex")
			else()
				unset(mutex)
			endif()

			lock_tx_intr()

			if(WIN32)
				execute_cdb(${curr_bin_version} ${curr_scenario})
				execute(0 ${EXE_DIR}/pmdk-convert
					--to=${next_version} ${DIR}/pool${curr_bin_version}a
					-X fail-safety)
				execute(0
					${TEST_DIR}/transaction_${next_bin_version}
					${DIR}/pool${curr_bin_version}a va ${curr_scenario})
				execute(0 ${EXE_DIR}/pmdk-convert
					--to=${next_version} ${DIR}/pool${curr_bin_version}c
					-X fail-safety)
				execute(0
					${TEST_DIR}/transaction_${next_bin_version}
					${DIR}/pool${curr_bin_version}c vc ${curr_scenario})
			else()
				execute(0 gdb --batch
					--command=${SRC_DIR}/trip_on_pre_commit.gdb
					--args ${TEST_DIR}/transaction_${curr_bin_version}
					${DIR}/pool${curr_bin_version}a c ${curr_scenario})
				execute(0 ${EXE_DIR}/pmdk-convert
					--to=${next_version} ${DIR}/pool${curr_bin_version}a
					-X fail-safety ${mutex})
				execute(0
					${TEST_DIR}/transaction_${next_bin_version}
					${DIR}/pool${curr_bin_version}a va ${curr_scenario})

				execute(0 gdb --batch
					--command=${SRC_DIR}/trip_on_post_commit.gdb
					--args ${TEST_DIR}/transaction_${curr_bin_version}
					${DIR}/pool${curr_bin_version}c c ${curr_scenario})
				execute(0 ${EXE_DIR}/pmdk-convert
					--to=${next_version} ${DIR}/pool${curr_bin_version}c
					-X fail-safety ${mutex})
				execute(0
					${TEST_DIR}/transaction_${next_bin_version}
					${DIR}/pool${curr_bin_version}c vc ${curr_scenario})
			endif()

			unlock_tx_intr()

			MATH(EXPR index "${index} + 1")
		endwhile()

		MATH(EXPR curr_scenario "${curr_scenario} + 1")
	endwhile()
endfunction()

set(DEVDAX_LOCKS "${PARENT_DIR}/../devdax.lock")
set(TX_INTR_LOCKS "${PARENT_DIR}/../tx_intr.lock")

# acquire a lock on DAX devices
function(lock_devdax)
       file(LOCK ${DEVDAX_LOCKS})
endfunction()

# release a lock on DAX devices
function(unlock_devdax)
       file(LOCK ${DEVDAX_LOCKS} RELEASE)
endfunction()

# acquire a lock on tests with interrupted transactions
function(lock_tx_intr)
       file(LOCK ${TX_INTR_LOCKS})
endfunction()

# release a lock on tests with interrupted transactions
function(unlock_tx_intr)
       file(LOCK ${TX_INTR_LOCKS} RELEASE)
endfunction()

function(test_intr_tx_devdax prepare_files curr_version next_version)
	set(curr_scenario 0)
	set(last_scenario 9)

	while(NOT curr_scenario GREATER last_scenario)
		string(REPLACE "." "" curr_bin_version ${curr_version})
		string(REPLACE "." "" next_bin_version ${next_version})

		prepare_files(${curr_bin_version})

		lock_tx_intr()

		execute(0 gdb --batch
				--command=${SRC_DIR}/trip_on_pre_commit.gdb
				--args ${TEST_DIR}/transaction_${curr_bin_version}
				${pool_file} c ${curr_scenario})
		execute(0 ${EXE_DIR}/pmdk-convert
				--to=${next_version} ${pool_file} -X fail-safety)
		execute(0
				${TEST_DIR}/transaction_${next_bin_version}
				${pool_file} va ${curr_scenario})

		prepare_files(${curr_bin_version})

		execute(0 gdb --batch
				--command=${SRC_DIR}/trip_on_post_commit.gdb
				--args ${TEST_DIR}/transaction_${curr_bin_version}
				${pool_file} c ${curr_scenario})
		execute(0 ${EXE_DIR}/pmdk-convert
				--to=${next_version} ${pool_file} -X fail-safety)
		execute(0
				${TEST_DIR}/transaction_${next_bin_version}
				${pool_file} vc ${curr_scenario})

		unlock_tx_intr()

		MATH(EXPR curr_scenario "${curr_scenario} + 1")
	endwhile()
endfunction()
