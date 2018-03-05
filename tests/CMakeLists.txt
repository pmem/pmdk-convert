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

set(TEST_DIR ${CMAKE_CURRENT_BINARY_DIR}/test
	CACHE STRING "working directory for tests")

add_executable(create_10 create.c)
target_include_directories(create_10 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.0/src/include)
target_link_libraries(create_10 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(create_10 PRIVATE pmemobj_10)

add_executable(create_11 create.c)
target_include_directories(create_11 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.1/src/include)
target_link_libraries(create_11 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(create_11 PRIVATE pmemobj_11)

add_executable(create_12 create.c)
target_include_directories(create_12 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.2/src/include)
target_link_libraries(create_12 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(create_12 PRIVATE pmemobj_12)

add_executable(create_13 create.c)
target_include_directories(create_13 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.3/src/include)
target_link_libraries(create_13 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(create_13 PRIVATE pmemobj_13)

add_executable(open_10 open.c)
target_include_directories(open_10 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.0/src/include)
target_link_libraries(open_10 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(open_10 PRIVATE pmemobj_10)

add_executable(open_11 open.c)
target_include_directories(open_11 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.1/src/include)
target_link_libraries(open_11 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(open_11 PRIVATE pmemobj_11)

add_executable(open_12 open.c)
target_include_directories(open_12 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.2/src/include)
target_link_libraries(open_12 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(open_12 PRIVATE pmemobj_12)

add_executable(open_13 open.c)
target_include_directories(open_13 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.3/src/include)
target_link_libraries(open_13 PRIVATE ${PMEM_LIBRARIES})
target_link_libraries(open_13 PRIVATE pmemobj_13)

option(TESTS_USE_FORCED_PMEM "let tests force enable or force disable use of optimized flush in libpmemobj (to speed them up)" OFF)

set(GLOBAL_TEST_ARGS
	-DPARENT_DIR=${TEST_DIR}/
	-DTESTS_USE_FORCED_PMEM=${TESTS_USE_FORCED_PMEM})

if(TRACE_TESTS)
	set(GLOBAL_TEST_ARGS ${GLOBAL_TEST_ARGS} --trace-expand)
endif()

# Configures test ${name} using tracer ${tracer}.
# Optional next argument is passed as is to test.
# Optional next argument is appended to environment variables.
function(test name)
	add_test(NAME ${name}
		COMMAND ${CMAKE_COMMAND}
			${GLOBAL_TEST_ARGS}
			-DTEST_NAME=${name}
			-DSRC_DIR=${CMAKE_CURRENT_SOURCE_DIR}
			-DBIN_DIR=${CMAKE_CURRENT_BINARY_DIR}/${name}
			${ARGV4}
			-P ${CMAKE_CURRENT_SOURCE_DIR}/${name}.cmake)

	set_tests_properties(${name} PROPERTIES
		ENVIRONMENT "LC_ALL=C;PATH=$ENV{PATH};${ARGV4}")
endfunction()

test(basic)
