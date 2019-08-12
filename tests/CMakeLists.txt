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

if(WIN32)
	set(OPEN_SOURCE openW.c)
	set(CREATE_SOURCE createW.c)
else()
	set(OPEN_SOURCE open.c)
	set(CREATE_SOURCE create.c)
endif()

if(BUILD_CONVERT_V1)
	set(VERSIONS "${VERSIONS} 1.0")
endif()
if(BUILD_CONVERT_V2)
	set(VERSIONS "${VERSIONS} 1.1")
endif()
if(BUILD_CONVERT_V3)
	set(VERSIONS "${VERSIONS} 1.2")
endif()
if(BUILD_13)
	set(VERSIONS "${VERSIONS} 1.3")
endif()
if(BUILD_CONVERT_V4)
	set(VERSIONS "${VERSIONS} 1.4")
endif()
if(BUILD_CONVERT_V5)
	set(VERSIONS "${VERSIONS} 1.5")
endif()

if(BUILD_CONVERT_V1)
	add_executable(create_10 ${CREATE_SOURCE})
	target_include_directories(create_10 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.0/src/include)
	target_link_libraries(create_10 PRIVATE libpmem-convert)
	target_link_libraries(create_10 PRIVATE pmemobj_10)

	add_executable(open_10 open.c)
	target_include_directories(open_10 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.0/src/include)
	target_link_libraries(open_10 PRIVATE libpmem-convert)
	target_link_libraries(open_10 PRIVATE pmemobj_10)

	test("1.0_pool_conversion" basic10)
endif()

if(BUILD_CONVERT_V2)
	add_executable(create_11 ${CREATE_SOURCE})
	target_include_directories(create_11 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.1/src/include)
	target_link_libraries(create_11 PRIVATE libpmem-convert)
	target_link_libraries(create_11 PRIVATE pmemobj_11)

	add_executable(open_11 ${OPEN_SOURCE})
	target_include_directories(open_11 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.1/src/include)
	target_link_libraries(open_11 PRIVATE libpmem-convert)
	target_link_libraries(open_11 PRIVATE pmemobj_11)

	test("1.1_pool_conversion" basic11)
endif()

if(BUILD_CONVERT_V3)
	add_executable(create_12 ${CREATE_SOURCE})
	target_include_directories(create_12 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.2/src/include)
	target_link_libraries(create_12 PRIVATE libpmem-convert)
	target_link_libraries(create_12 PRIVATE pmemobj_12)

	add_executable(open_12 ${OPEN_SOURCE})
	target_include_directories(open_12 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.2/src/include)
	target_link_libraries(open_12 PRIVATE libpmem-convert)
	target_link_libraries(open_12 PRIVATE pmemobj_12)

	test("1.2_pool_conversion" basic12)
endif()

if(BUILD_13)
	add_executable(create_13 ${CREATE_SOURCE})
	target_include_directories(create_13 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.3/src/include)
	target_link_libraries(create_13 PRIVATE libpmem-convert)
	target_link_libraries(create_13 PRIVATE pmemobj_13)

	add_executable(open_13 ${OPEN_SOURCE})
	target_include_directories(open_13 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.3/src/include)
	target_link_libraries(open_13 PRIVATE libpmem-convert)
	target_link_libraries(open_13 PRIVATE pmemobj_13)

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
	add_executable(create_14 ${CREATE_SOURCE})
	target_include_directories(create_14 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.4/src/include)
	target_link_libraries(create_14 PRIVATE libpmem-convert)
	target_link_libraries(create_14 PRIVATE pmemobj_14)

	add_executable(open_14 ${OPEN_SOURCE})
	target_include_directories(open_14 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.4/src/include)
	target_link_libraries(open_14 PRIVATE libpmem-convert)
	target_link_libraries(open_14 PRIVATE pmemobj_14)

	test("1.4_pool_conversion" basic14)

	if(WIN32)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET open_14 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_14>
			$<TARGET_FILE_DIR:open_14>)
	endif()
endif()

if(BUILD_CONVERT_V5)
	add_executable(create_15 ${CREATE_SOURCE})
	target_include_directories(create_15 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/include)
	target_link_libraries(create_15 PRIVATE libpmem-convert)
	target_link_libraries(create_15 PRIVATE pmemobj_15)

	add_executable(open_15 ${OPEN_SOURCE})
	target_include_directories(open_15 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/include)
	target_link_libraries(open_15 PRIVATE libpmem-convert)
	target_link_libraries(open_15 PRIVATE pmemobj_15)

	if(WIN32)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET open_15 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_15>
			$<TARGET_FILE_DIR:open_15>)

		add_custom_command(TARGET open_15 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE_DIR:pmemobj_15>/libpmem-convert.dll
			$<TARGET_FILE_DIR:open_15>)
	endif()

	set(COMMON_SOURCES
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/badblock.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/file.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/mmap.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/pool_hdr.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/out.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/os_dimm_none.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/set.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/shutdown_state.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/util.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/uuid.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/ctl_sds.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/ctl.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/ctl_prefault.c
		)

	if(WIN32)
		set(COMMON_SOURCES ${COMMON_SOURCES}
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/badblock_none.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/file_windows.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/fs_windows.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/mmap_windows.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/os_deep_windows.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/os_thread_windows.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/os_windows.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/util_windows.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/uuid_windows.c
			)
	else()
		set(COMMON_SOURCES ${COMMON_SOURCES}
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/badblock_ndctl.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/extent_linux.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/file_posix.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/fs_posix.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/mmap_posix.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/os_deep_linux.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/os_posix.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/os_thread_posix.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/util_posix.c
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/common/uuid_linux.c
			)
	endif()

	set(BLK_SOURCES
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemblk/blk.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemblk/btt.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemblk/libpmemblk.c
		${COMMON_SOURCES}
		)

	if(WIN32)
		set(BLK_SOURCES ${BLK_SOURCES}
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemblk/libpmemblk_main.c
			)
	endif()

	if(MSVC)
		FILE(READ ${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemblk/libpmemblk.def DEFFILE)
		string(REPLACE "libpmemblk" "pmemblk_15" DEFFILE "${DEFFILE}")
		FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/pmemblk_15.def "${DEFFILE}")
		add_library(pmemblk_15 SHARED ${BLK_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/pmemblk_15.def)
		target_compile_options(pmemblk_15 PRIVATE /FI"${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/include/platform.h")
	else()
		add_library(pmemblk_15 SHARED ${BLK_SOURCES})
	endif()

	target_compile_definitions(pmemblk_15 PRIVATE SRCVERSION="${NVML15}")
	target_compile_definitions(pmemblk_15 PRIVATE PMDK_UTF8_API)
	target_compile_definitions(pmemblk_15 PRIVATE _PMEMBLK_INTRNL)

	target_include_directories(pmemblk_15 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/include)
	target_include_directories(pmemblk_15 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemblk)
	target_include_directories(pmemblk_15 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/common)
	target_include_directories(pmemblk_15 PRIVATE ${PMEM_INCLUDE_DIRS})

	if(WIN32)
		target_include_directories(pmemblk_15 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/include/)
		target_include_directories(pmemblk_15 PRIVATE ${CMAKE_SOURCE_DIR}/include/)
	endif()

	target_link_libraries(pmemblk_15 PRIVATE libpmem-convert)
	target_link_libraries(pmemblk_15 PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemblk_15 PRIVATE ${CMAKE_THREAD_LIBS_INIT})

	if(NOT MSVC)
		target_link_libraries(pmemblk_15 PRIVATE -Wl,--version-script=${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemblk/libpmemblk.map)
	endif()

	set(LOG_SOURCES
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemlog/libpmemlog.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemlog/log.c
		${COMMON_SOURCES}
		)

	if(WIN32)
		set(LOG_SOURCES ${LOG_SOURCES}
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemlog/libpmemlog_main.c
			)
	endif()

	if(MSVC)
		FILE(READ ${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemlog/libpmemlog.def DEFFILE)
		string(REPLACE "libpmemlog" "pmemlog_15" DEFFILE "${DEFFILE}")
		FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/pmemlog_15.def "${DEFFILE}")
		add_library(pmemlog_15 SHARED ${LOG_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/pmemlog_15.def)
		target_compile_options(pmemlog_15 PRIVATE /FI"${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/include/platform.h")
	else()
		add_library(pmemlog_15 SHARED ${LOG_SOURCES})
	endif()

	target_compile_definitions(pmemlog_15 PRIVATE SRCVERSION="${NVML15}")
	target_compile_definitions(pmemlog_15 PRIVATE PMDK_UTF8_API)
	target_compile_definitions(pmemlog_15 PRIVATE _PMEMLOG_INTRNL)

	target_include_directories(pmemlog_15 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/include)
	target_include_directories(pmemlog_15 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemlog)
	target_include_directories(pmemlog_15 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/common)
	target_include_directories(pmemlog_15 PRIVATE ${PMEM_INCLUDE_DIRS})

	if(WIN32)
		target_include_directories(pmemlog_15 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/include/)
		target_include_directories(pmemlog_15 PRIVATE ${CMAKE_SOURCE_DIR}/include/)
	endif()

	target_link_libraries(pmemlog_15 PRIVATE libpmem-convert)
	target_link_libraries(pmemlog_15 PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemlog_15 PRIVATE ${CMAKE_THREAD_LIBS_INIT})

	if(NOT MSVC)
		target_link_libraries(pmemlog_15 PRIVATE -Wl,--version-script=${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemlog/libpmemlog.map)
	endif()

	set(PMEMSPOIL_SOURCES
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/test/tools/pmemspoil/spoil.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/common.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemblk/btt.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/output.c
		${COMMON_SOURCES}
		)

	if(WIN32)
		set(PMEMSPOIL_SOURCES
			${PMEMSPOIL_SOURCES}
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/getopt/getopt.c
			)
	endif()

	add_executable(pmemspoil ${PMEMSPOIL_SOURCES})

	if(WIN32)
		target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/getopt)
		target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/include)
	endif()

	if(MSVC)
		target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/include/)
		target_compile_options(pmemspoil PRIVATE /FI"${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/include/platform.h")
	endif()

	target_compile_definitions(pmemspoil PRIVATE SRCVERSION="${NVML15}")
	target_compile_definitions(pmemspoil PRIVATE PMDK_UTF8_API)
	target_compile_definitions(pmemspoil PRIVATE LIBDIR="${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")

	target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/include)
	target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/common)
	target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemobj)
	target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemlog)
	target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemblk)
	target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool)

	target_link_libraries(pmemspoil PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemspoil PRIVATE libpmem-convert)
	target_link_libraries(pmemspoil PRIVATE pmemobj_15)

	if(WIN32)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET pmemspoil POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:libpmem-convert>
			$<TARGET_FILE_DIR:pmemspoil>)
	endif()

	set(PMEMPOOL_SOURCES
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/pmempool.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/check.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/common.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/convert.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/create.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/dump.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/feature.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/info.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/info_blk.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/info_obj.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/info_log.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/output.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/rm.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/synchronize.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool/transform.c

		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemblk/btt.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemobj/ulog.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemobj/memblock.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemobj/alloc_class.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemobj/memops.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemobj/heap.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemobj/cuckoo.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemobj/bucket.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemobj/recycler.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemobj/container_seglists.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemobj/container_ravl.c
		${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemobj/ravl.c
		${COMMON_SOURCES}
		)

	if(NOT WIN32)
		set(PMEMPOOL_SOURCES ${PMEMPOOL_SOURCES}
			${CMAKE_SOURCE_DIR}/nvml-1.5/src/librpmem/rpmem_util.c)
	endif()

	if(WIN32)
		add_executable(pmempool-convert ${PMEMPOOL_SOURCES} ${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/getopt/getopt.c)
		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/getopt/)
		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/include/)
	else()
		add_executable(pmempool-convert ${PMEMPOOL_SOURCES})
	endif()

	if(MSVC)
		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/include/)
		target_compile_options(pmempool-convert PRIVATE /FI"${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/include/platform.h")
	endif()

	target_compile_definitions(pmempool-convert PRIVATE SRCVERSION="${NVML15}")
	target_compile_definitions(pmempool-convert PRIVATE PMDK_UTF8_API)
	target_compile_definitions(pmempool-convert PRIVATE LIBDIR="${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")

	target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/include)
	target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/common)
	target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemlog)
	target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemblk)
	target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmemobj)
	target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmempool)
	target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/rpmem_common)
	target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/librpmem)
	target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/tools/pmempool)

	target_link_libraries(pmempool-convert PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmempool-convert PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmempool-convert PRIVATE libpmem-convert)
	target_link_libraries(pmempool-convert PRIVATE libpmempool-convert)
	target_link_libraries(pmempool-convert PRIVATE pmemobj_15)
	target_link_libraries(pmempool-convert PRIVATE pmemblk_15)
	target_link_libraries(pmempool-convert PRIVATE pmemlog_15)

	if(WIN32)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET pmempool-convert POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:libpmempool-convert>
			$<TARGET_FILE_DIR:pmempool-convert>)
	endif()
	
	test("compare_replicas" compare_replicas)
endif()

if(NOT WIN32)
	if(BUILD_CONVERT_V1)
		add_executable(transaction_10 transaction.c)
		disable_optimization(transaction_10)
		target_include_directories(transaction_10 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.0/src/include)
		target_link_libraries(transaction_10 PRIVATE libpmem-convert)
		target_link_libraries(transaction_10 PRIVATE pmemobj_10)
	endif()

	if(BUILD_CONVERT_V2)
		add_executable(transaction_11 transaction.c)
		disable_optimization(transaction_11)
		target_include_directories(transaction_11 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.1/src/include)
		target_link_libraries(transaction_11 PRIVATE libpmem-convert)
		target_link_libraries(transaction_11 PRIVATE pmemobj_11)
	endif()

	if(BUILD_CONVERT_V3)
		add_executable(transaction_12 transaction.c)
		disable_optimization(transaction_12)
		target_include_directories(transaction_12 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.2/src/include)
		target_link_libraries(transaction_12 PRIVATE libpmem-convert)
		target_link_libraries(transaction_12 PRIVATE pmemobj_12)
	endif()

	if(BUILD_13)
		add_executable(transaction_13 transaction.c)
		disable_optimization(transaction_13)
		target_include_directories(transaction_13 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.3/src/include)
		target_link_libraries(transaction_13 PRIVATE libpmem-convert)
		target_link_libraries(transaction_13 PRIVATE pmemobj_13)
	endif()

	if(BUILD_CONVERT_V4)
		add_executable(transaction_14 transaction.c)
		disable_optimization(transaction_14)
		target_include_directories(transaction_14 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.4/src/include)
		target_link_libraries(transaction_14 PRIVATE libpmem-convert)
		target_link_libraries(transaction_14 PRIVATE pmemobj_14)
	endif()

	if(BUILD_CONVERT_V5)
		add_executable(transaction_15 transaction.c)
		disable_optimization(transaction_15)
		target_include_directories(transaction_15 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/include)
		target_link_libraries(transaction_15 PRIVATE libpmem-convert)
		target_link_libraries(transaction_15 PRIVATE pmemobj_15)
	endif()
endif()

test("cli_test" cli)

if(NOT WIN32)
	add_executable(clean_pool clean.c)
	target_include_directories(clean_pool PRIVATE ${LIBPMEMPOOL_INCLUDE_DIRS})
	target_link_libraries(clean_pool PRIVATE ${LIBPMEMPOOL_LIBRARIES})

	if(DEVICE_DAX_PATHS)
		file(WRITE ${TEST_DIR}/../devdax.lock "")
	endif()

	file(WRITE ${TEST_DIR}/../tx_intr.lock "")

	test("tx_intr_pool_regfile" tx_intr_pool_regfile)
	test("tx_intr_poolset_local_2regfiles" tx_intr_poolset_local_2regfiles)
	test("tx_intr_poolset_local_regfile" tx_intr_poolset_local_regfile)
	test("tx_intr_poolset_local_regfile_rep_regfile"
		tx_intr_poolset_local_regfile_rep_regfile)
	test("tx_intr_poolset_local_2regfiles_rep_3regfiles"
		tx_intr_poolset_local_2regfiles_rep_3regfiles)
	test("poolsets_with_remote_replica" remote)

	if(NOT DEVICE_DAX_PATHS)
		test("tx_intr_pool_devdax_SKIP_BECAUSE_OF_NO_DEVDAX_DEFINED"
			skip_test)
		test("tx_intr_poolset_local_devdax_devdax_SKIP_BECAUSE_OF_NO_DEVDAX_DEFINED"
			skip_test)
	else()
		test("tx_intr_pool_devdax" tx_intr_pool_devdax)
		test("tx_intr_poolset_local_devdax" tx_intr_poolset_local_devdax)
	endif()

	if(devdax_num LESS 2)
		test("tx_intr_poolset_local_2devdaxes_SKIP_BECAUSE_OF_NOT_ENOUGH_DEVDAX_DEFINED"
			skip_test)
		test("tx_intr_poolset_local_devdax_rep_devdax_SKIP_BECAUSE_OF_NOT_ENOUGH_DEVDAX_DEFINED"
			skip_test)
		test("tx_intr_poolset_local_2devdaxes_rep_2regfiles_SKIP_BECAUSE_OF_NOT_ENOUGH_DEVDAX_DEFINED"
			skip_test)
		test("tx_intr_poolset_local_2regfiles_rep_2devdaxes_SKIP_BECAUSE_OF_NOT_ENOUGH_DEVDAX_DEFINED"
			skip_test)
	else()
		test("tx_intr_poolset_local_2devdaxes" tx_intr_poolset_local_2devdaxes)
		test("tx_intr_poolset_local_devdax_rep_devdax"
			tx_intr_poolset_local_devdax_rep_devdax)
		test("tx_intr_poolset_local_2devdaxes_rep_2regfiles" 
			tx_intr_poolset_local_2devdaxes_rep_2regfiles)
		test("tx_intr_poolset_local_2regfiles_rep_2devdaxes"
			tx_intr_poolset_local_2regfiles_rep_2devdaxes)
	endif()
endif()
