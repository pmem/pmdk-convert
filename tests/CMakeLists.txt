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

include(${CMAKE_SOURCE_DIR}/utils/utils.cmake)

set(TEST_DIR ${CMAKE_CURRENT_BINARY_DIR}/test
	CACHE STRING "working directory for tests")

option(TESTS_USE_FORCED_PMEM "let tests force enable or force disable use of optimized flush in libpmemobj (to speed them up)" OFF)

set(DEVICE_DAX_PATHS "" CACHE STRING
	"for tests that require raw dax devices without a file system. Some tests might require two DAX devices.
	Example: '/dev/dax1.0 /dev/dax2.0'")

set(GLOBAL_TEST_ARGS
	-DPARENT_DIR=${TEST_DIR}/
	-DTESTS_USE_FORCED_PMEM=${TESTS_USE_FORCED_PMEM}
	-DDEVICE_DAX_PATHS=${DEVICE_DAX_PATHS})

# convert the DEVICE_DAX_PATHS list to the array
if(DEVICE_DAX_PATHS)
	string(REPLACE " " ";" DEVICE_DAX_PATHS ${DEVICE_DAX_PATHS})
endif()

list(LENGTH DEVICE_DAX_PATHS devdax_num)

if(TRACE_TESTS)
	set(GLOBAL_TEST_ARGS ${GLOBAL_TEST_ARGS} --trace-expand)
endif()

# Configures test ${name}
function(test name file)
	add_test(NAME ${name}
		COMMAND ${CMAKE_COMMAND}
			${GLOBAL_TEST_ARGS}
			-DTEST_NAME=${name}
			-DSRC_DIR=${CMAKE_CURRENT_SOURCE_DIR}
			-DBIN_DIR=${CMAKE_CURRENT_BINARY_DIR}/${file}
			-DVERSIONS=${VERSIONS}
			-DCONFIG=$<CONFIG>
			-P ${CMAKE_CURRENT_SOURCE_DIR}/${file}.cmake)

	set_tests_properties(${name} PROPERTIES
		ENVIRONMENT "LC_ALL=C;PATH=$ENV{PATH}")
endfunction()

macro(require_libpmempool ver)
	if(PKG_CONFIG_FOUND)
		pkg_check_modules(LIBPMEMPOOL REQUIRED libpmempool>=${ver})
	else()
		find_package(LIBPMEMPOOL REQUIRED)
	endif()
	link_directories(${LIBPMEMPOOL_LIBRARY_DIRS})
endmacro()

if(BUILD_CONVERT_V1)
add_executable(create_10 create.c)
target_include_directories(create_10 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.0/src/include)
target_link_libraries(create_10 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(create_10 PRIVATE pmemobj_10)

add_executable(open_10 open.c)
target_include_directories(open_10 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.0/src/include)
target_link_libraries(open_10 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(open_10 PRIVATE pmemobj_10)

set(VERSIONS "${VERSIONS} 1.0")
test("1.0_pool_conversion" basic10)
endif()

if(BUILD_CONVERT_V2)
add_executable(create_11 create.c)
target_include_directories(create_11 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.1/src/include)
target_link_libraries(create_11 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(create_11 PRIVATE pmemobj_11)

add_executable(open_11 open.c)
target_include_directories(open_11 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.1/src/include)
target_link_libraries(open_11 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(open_11 PRIVATE pmemobj_11)

set(VERSIONS "${VERSIONS} 1.1")
test("1.1_pool_conversion" basic11)
endif()

if(BUILD_CONVERT_V3)
add_executable(create_12 create.c)
target_include_directories(create_12 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.2/src/include)
target_link_libraries(create_12 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(create_12 PRIVATE pmemobj_12)

add_executable(open_12 open.c)
target_include_directories(open_12 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.2/src/include)
target_link_libraries(open_12 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(open_12 PRIVATE pmemobj_12)

set(VERSIONS "${VERSIONS} 1.2")
test("1.2_pool_conversion" basic12)
endif()

if(BUILD_13)
add_executable(create_13 create.c)
target_include_directories(create_13 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.3/src/include)
target_link_libraries(create_13 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(create_13 PRIVATE pmemobj_13)
target_compile_definitions(create_13 PRIVATE NVML_UTF8_API)

add_executable(open_13 open.c)
target_include_directories(open_13 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.3/src/include)
target_link_libraries(open_13 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(open_13 PRIVATE pmemobj_13)
target_compile_definitions(open_13 PRIVATE NVML_UTF8_API)

set(VERSIONS "${VERSIONS} 1.3")
test("1.3_pool_conversion" basic13)

if(WIN32)
	# on windows dll and executable must be in the same dir
	add_custom_command(TARGET open_13 POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy_if_different
		$<TARGET_FILE:pmemobj_13>
		$<TARGET_FILE_DIR:open_13>)
endif()
endif()

if(BUILD_CONVERT_V4)
add_executable(create_14 create.c)
target_include_directories(create_14 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.4/src/include)
target_link_libraries(create_14 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(create_14 PRIVATE pmemobj_14)
target_compile_definitions(create_14 PRIVATE NVML_UTF8_API)

add_executable(open_14 open.c)
target_include_directories(open_14 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.4/src/include)
target_link_libraries(open_14 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(open_14 PRIVATE pmemobj_14)
target_compile_definitions(open_14 PRIVATE NVML_UTF8_API)

set(VERSIONS "${VERSIONS} 1.4")
test("1.4_pool_conversion" basic14)

if(WIN32)
	# on windows dll and executable must be in the same dir
	add_custom_command(TARGET open_14 POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy_if_different
		$<TARGET_FILE:pmemobj_14>
		$<TARGET_FILE_DIR:open_14>)

	add_custom_command(TARGET open_14 POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy_if_different
		$<TARGET_FILE_DIR:pmemobj_14>/libpmem.dll
		$<TARGET_FILE_DIR:open_14>)
endif()
endif()

if (NOT WIN32)
if(BUILD_CONVERT_V1)
add_executable(transaction_10 transaction.c)
disable_optimization(transaction_10)
target_include_directories(transaction_10 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.0/src/include)
target_link_libraries(transaction_10 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(transaction_10 PRIVATE pmemobj_10)
endif()

if(BUILD_CONVERT_V2)
add_executable(transaction_11 transaction.c)
disable_optimization(transaction_11)
target_include_directories(transaction_11 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.1/src/include)
target_link_libraries(transaction_11 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(transaction_11 PRIVATE pmemobj_11)
endif()

if(BUILD_CONVERT_V3)
add_executable(transaction_12 transaction.c)
disable_optimization(transaction_12)
target_include_directories(transaction_12 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.2/src/include)
target_link_libraries(transaction_12 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(transaction_12 PRIVATE pmemobj_12)
endif()

if(BUILD_CONVERT_V4)
add_executable(transaction_13 transaction.c)
disable_optimization(transaction_13)
target_include_directories(transaction_13 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.3/src/include)
target_link_libraries(transaction_13 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(transaction_13 PRIVATE pmemobj_13)
endif()

if(BUILD_CONVERT_V4)
add_executable(transaction_14 transaction.c)
disable_optimization(transaction_14)
target_include_directories(transaction_14 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.4/src/include)
target_link_libraries(transaction_14 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(transaction_14 PRIVATE pmemobj_14)
endif()
endif()

test("cli_test" cli)

if (NOT WIN32)
require_libpmempool(1.3)

add_executable(clean_pool clean.c)
target_include_directories(clean_pool PRIVATE ${LIBPMEMPOOL_INCLUDE_DIRS})
target_link_libraries(clean_pool PRIVATE ${LIBPMEMPOOL_LIBRARIES})

if(DEVICE_DAX_PATHS)
	file(WRITE ${TEST_DIR}/../devdax.lock "")
endif()

test("tx_intr_single_file_pools" tx_intr_single_file_pools)
test("tx_intr_single_file_poolsets" tx_intr_single_file_poolsets)
test("tx_intr_multi_file_poolsets" tx_intr_multi_file_poolsets)
test("tx_intr_poolsets_with_local_replica" tx_intr_poolsets_with_local_replica)
test("poolsets_with_remote_replica" remote)

if(NOT DEVICE_DAX_PATHS)
	test("tx_intr_single_file_pools_devdax_SKIP_BECAUSE_OF_NO_DEVDAX_DEFINED"
		skip_test)
	test("tx_intr_single_file_poolsets_devdax_SKIP_BECAUSE_OF_NO_DEVDAX_DEFINED"
		skip_test)
else()
	test("tx_intr_single_file_pools_devdax" tx_intr_single_file_pools_devdax)
	test("tx_intr_single_file_poolsets_devdax"
		tx_intr_single_file_poolsets_devdax)
endif()

if(devdax_num LESS 2)
	test("tx_intr_multi_file_poolsets_devdax_SKIP_BECAUSE_OF_NOT_ENOUGH_DEVDAX_DEFINED"
		skip_test)
	test("tx_intr_poolsets_with_local_replica_devdax_SKIP_BECAUSE_OF_NOT_ENOUGH_DEVDAX_DEFINED"
		skip_test)
else()
	test("tx_intr_multi_file_poolsets_devdax"
		tx_intr_multi_file_poolsets_devdax)
	test("tx_intr_poolsets_with_local_replica_devdax"
		tx_intr_poolsets_with_local_replica_devdax)
endif()
endif()
