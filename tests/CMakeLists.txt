# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2022, Intel Corporation

include(${CMAKE_SOURCE_DIR}/utils/utils.cmake)

set(TEST_DIR ${CMAKE_CURRENT_BINARY_DIR}/test
	CACHE STRING "working directory for tests")

option(TESTS_USE_FORCED_PMEM "let tests force enable or force disable use of optimized flush in libpmemobj (to speed them up)" OFF)

set(DEVICE_DAX_PATHS "" CACHE STRING
	"for tests that require raw dax devices without a file system. Some tests might require two DAX devices.
	Example: '/dev/dax1.0 /dev/dax2.0'")

if(WIN32)
	set(CDB_PATH "" CACHE PATH "requied for windows tests with cdb debugger")
endif()

set(GLOBAL_TEST_ARGS
	-DPARENT_DIR=${TEST_DIR}/
	-DTESTS_USE_FORCED_PMEM=${TESTS_USE_FORCED_PMEM}
	-DDEVICE_DAX_PATHS=${DEVICE_DAX_PATHS}
	-DCDB_PATH=${CDB_PATH})

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

# Finding cdb executable debugger file and setting path to it
function(set_cdb_executable)
	if(EXISTS ${CDB_PATH})
		find_program(CDB_EXE cdb.exe ${CDB_PATH})
		if(NOT CDB_EXE)
			message(WARNING "CDB Debugger not found!")
		endif()
	else()
		unset(CDB_EXE)
	endif()
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
if(BUILD_15)
	set(VERSIONS "${VERSIONS} 1.5")
endif()
if(BUILD_CONVERT_V5)
	set(VERSIONS "${VERSIONS} 1.6")
endif()
if(BUILD_17)
	set(VERSIONS "${VERSIONS} 1.7")
endif()
if(BUILD_18)
	set(VERSIONS "${VERSIONS} 1.8")
endif()
if(BUILD_19)
	set(VERSIONS "${VERSIONS} 1.9")
endif()
if(BUILD_110)
	set(VERSIONS "${VERSIONS} 1.10")
endif()
if(BUILD_111)
	set(VERSIONS "${VERSIONS} 1.11")
endif()
if(BUILD_CONVERT_V6)
	set(VERSIONS "${VERSIONS} 1.12")
endif()

if(BUILD_CONVERT_V1)
	add_executable(create_10 ${CREATE_SOURCE})
	target_include_directories(create_10 PRIVATE ${CMAKE_SOURCE_DIR}/${VER10}/src/include)
	target_link_libraries(create_10 PRIVATE libpmem-convert)
	target_link_libraries(create_10 PRIVATE pmemobj_10)

	add_executable(open_10 open.c)
	target_include_directories(open_10 PRIVATE ${CMAKE_SOURCE_DIR}/${VER10}/src/include)
	target_link_libraries(open_10 PRIVATE libpmem-convert)
	target_link_libraries(open_10 PRIVATE pmemobj_10)

	test("1.0_pool_conversion" basic10)
endif()

if(BUILD_CONVERT_V2)
	add_executable(create_11 ${CREATE_SOURCE})
	target_include_directories(create_11 PRIVATE ${CMAKE_SOURCE_DIR}/${VER11}/src/include)
	target_link_libraries(create_11 PRIVATE libpmem-convert)
	target_link_libraries(create_11 PRIVATE pmemobj_11)

	add_executable(open_11 ${OPEN_SOURCE})
	target_include_directories(open_11 PRIVATE ${CMAKE_SOURCE_DIR}/${VER11}/src/include)
	target_link_libraries(open_11 PRIVATE libpmem-convert)
	target_link_libraries(open_11 PRIVATE pmemobj_11)

	test("1.1_pool_conversion" basic11)
endif()

if(BUILD_CONVERT_V3)
	add_executable(create_12 ${CREATE_SOURCE})
	target_include_directories(create_12 PRIVATE ${CMAKE_SOURCE_DIR}/${VER12}/src/include)
	target_link_libraries(create_12 PRIVATE libpmem-convert)
	target_link_libraries(create_12 PRIVATE pmemobj_12)

	add_executable(open_12 ${OPEN_SOURCE})
	target_include_directories(open_12 PRIVATE ${CMAKE_SOURCE_DIR}/${VER12}/src/include)
	target_link_libraries(open_12 PRIVATE libpmem-convert)
	target_link_libraries(open_12 PRIVATE pmemobj_12)

	test("1.2_pool_conversion" basic12)
endif()

if(BUILD_13)
	add_executable(create_13 ${CREATE_SOURCE})
	target_include_directories(create_13 PRIVATE ${CMAKE_SOURCE_DIR}/${VER13}/src/include)
	target_link_libraries(create_13 PRIVATE libpmem-convert)
	target_link_libraries(create_13 PRIVATE pmemobj_13)

	add_executable(open_13 ${OPEN_SOURCE})
	target_include_directories(open_13 PRIVATE ${CMAKE_SOURCE_DIR}/${VER13}/src/include)
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
	target_include_directories(create_14 PRIVATE ${CMAKE_SOURCE_DIR}/${VER14}/src/include)
	target_link_libraries(create_14 PRIVATE libpmem-convert)
	target_link_libraries(create_14 PRIVATE pmemobj_14)

	add_executable(open_14 ${OPEN_SOURCE})
	target_include_directories(open_14 PRIVATE ${CMAKE_SOURCE_DIR}/${VER14}/src/include)
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

if(BUILD_15)
	add_executable(create_15 ${CREATE_SOURCE})
	target_include_directories(create_15 PRIVATE ${CMAKE_SOURCE_DIR}/${VER15}/src/include)
	target_link_libraries(create_15 PRIVATE libpmem-convert)
	target_link_libraries(create_15 PRIVATE pmemobj_15)

	add_executable(open_15 ${OPEN_SOURCE})
	target_include_directories(open_15 PRIVATE ${CMAKE_SOURCE_DIR}/${VER15}/src/include)
	target_link_libraries(open_15 PRIVATE libpmem-convert)
	target_link_libraries(open_15 PRIVATE pmemobj_15)

	test("1.5_pool_conversion" basic15)

	if(WIN32)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET open_15 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_15>
			$<TARGET_FILE_DIR:open_15>)
	endif()
endif()

if(BUILD_CONVERT_V5)
	add_executable(create_16 ${CREATE_SOURCE})
	target_include_directories(create_16 PRIVATE ${CMAKE_SOURCE_DIR}/${VER16}/src/include)
	target_link_libraries(create_16 PRIVATE libpmem-convert)
	target_link_libraries(create_16 PRIVATE pmemobj_16)

	add_executable(open_16 ${OPEN_SOURCE})
	target_include_directories(open_16 PRIVATE ${CMAKE_SOURCE_DIR}/${VER16}/src/include)
	target_link_libraries(open_16 PRIVATE libpmem-convert)
	target_link_libraries(open_16 PRIVATE pmemobj_16)

	test("1.6_pool_conversion" basic16)

	if(WIN32)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET open_16 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_16>
			$<TARGET_FILE_DIR:open_16>)

		add_custom_command(TARGET open_16 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE_DIR:pmemobj_16>/libpmem-convert.dll
			$<TARGET_FILE_DIR:open_16>)
	endif()
endif()

if(BUILD_17)
	add_executable(create_17 ${CREATE_SOURCE})
	target_include_directories(create_17 PRIVATE ${CMAKE_SOURCE_DIR}/${VER17}/src/include)
	target_link_libraries(create_17 PRIVATE libpmem-convert)
	target_link_libraries(create_17 PRIVATE pmemobj_17)

	add_executable(open_17 ${OPEN_SOURCE})
	target_include_directories(open_17 PRIVATE ${CMAKE_SOURCE_DIR}/${VER17}/src/include)
	target_link_libraries(open_17 PRIVATE libpmem-convert)
	target_link_libraries(open_17 PRIVATE pmemobj_17)

	test("1.7_pool_conversion" basic17)

	if(WIN32)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET open_17 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_17>
			$<TARGET_FILE_DIR:open_17>)

		add_custom_command(TARGET open_17 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE_DIR:pmemobj_17>/libpmem-convert.dll
			$<TARGET_FILE_DIR:open_17>)
	endif()
endif()

if(BUILD_18)
	add_executable(create_18 ${CREATE_SOURCE})
	target_include_directories(create_18 PRIVATE ${CMAKE_SOURCE_DIR}/${VER18}/src/include)
	target_link_libraries(create_18 PRIVATE libpmem-convert)
	target_link_libraries(create_18 PRIVATE pmemobj_18)

	add_executable(open_18 ${OPEN_SOURCE})
	target_include_directories(open_18 PRIVATE ${CMAKE_SOURCE_DIR}/${VER18}/src/include)
	target_link_libraries(open_18 PRIVATE libpmem-convert)
	target_link_libraries(open_18 PRIVATE pmemobj_18)

	test("1.8_pool_conversion" basic18)

	if(WIN32)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET open_18 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_18>
			$<TARGET_FILE_DIR:open_18>)

		add_custom_command(TARGET open_18 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE_DIR:pmemobj_18>/libpmem-convert.dll
			$<TARGET_FILE_DIR:open_18>)
	endif()
endif()

if(BUILD_19)
	add_executable(create_19 ${CREATE_SOURCE})
	target_include_directories(create_19 PRIVATE ${CMAKE_SOURCE_DIR}/${VER19}/src/include)
	target_link_libraries(create_19 PRIVATE libpmem-convert)
	target_link_libraries(create_19 PRIVATE pmemobj_19)

	add_executable(open_19 ${OPEN_SOURCE})
	target_include_directories(open_19 PRIVATE ${CMAKE_SOURCE_DIR}/${VER19}/src/include)
	target_link_libraries(open_19 PRIVATE libpmem-convert)
	target_link_libraries(open_19 PRIVATE pmemobj_19)

	test("1.9_pool_conversion" basic19)

	if(WIN32)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET open_19 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_19>
			$<TARGET_FILE_DIR:open_19>)

		add_custom_command(TARGET open_19 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE_DIR:pmemobj_19>/libpmem-convert.dll
			$<TARGET_FILE_DIR:open_19>)
	endif()

endif()

if(BUILD_110)
	add_executable(create_110 ${CREATE_SOURCE})
	target_include_directories(create_110 PRIVATE ${CMAKE_SOURCE_DIR}/${VER110}/src/include)
	target_link_libraries(create_110 PRIVATE libpmem-convert)
	target_link_libraries(create_110 PRIVATE pmemobj_110)

	add_executable(open_110 ${OPEN_SOURCE})
	target_include_directories(open_110 PRIVATE ${CMAKE_SOURCE_DIR}/${VER110}/src/include)
	target_link_libraries(open_110 PRIVATE libpmem-convert)
	target_link_libraries(open_110 PRIVATE pmemobj_110)

	test("1.10_pool_conversion" basic110)

	if(WIN32)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET open_110 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_110>
			$<TARGET_FILE_DIR:open_110>)

		add_custom_command(TARGET open_110 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE_DIR:pmemobj_110>/libpmem-convert.dll
			$<TARGET_FILE_DIR:open_110>)
	endif()
endif()

if(BUILD_111)
	add_executable(create_111 ${CREATE_SOURCE})
	target_include_directories(create_111 PRIVATE ${CMAKE_SOURCE_DIR}/${VER111}/src/include)
	target_link_libraries(create_111 PRIVATE libpmem-convert)
	target_link_libraries(create_111 PRIVATE pmemobj_111)

	add_executable(open_111 ${OPEN_SOURCE})
	target_include_directories(open_111 PRIVATE ${CMAKE_SOURCE_DIR}/${VER111}/src/include)
	target_link_libraries(open_111 PRIVATE libpmem-convert)
	target_link_libraries(open_111 PRIVATE pmemobj_111)

	test("1.11_pool_conversion" basic111)

	if(WIN32)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET open_111 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_111>
			$<TARGET_FILE_DIR:open_111>)

		add_custom_command(TARGET open_111 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE_DIR:pmemobj_111>/libpmem-convert.dll
			$<TARGET_FILE_DIR:open_111>)
	endif()
endif()

if(BUILD_CONVERT_V6)
	add_executable(create_112 ${CREATE_SOURCE})
	target_include_directories(create_112 PRIVATE ${CMAKE_SOURCE_DIR}/${VER112}/src/include)
	target_link_libraries(create_112 PRIVATE libpmem-convert)
	target_link_libraries(create_112 PRIVATE pmemobj_112)

	add_executable(open_112 ${OPEN_SOURCE})
	target_include_directories(open_112 PRIVATE ${CMAKE_SOURCE_DIR}/${VER112}/src/include)
	target_link_libraries(open_112 PRIVATE libpmem-convert)
	target_link_libraries(open_112 PRIVATE pmemobj_112)

	if(WIN32)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET open_112 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_112>
			$<TARGET_FILE_DIR:open_112>)

		add_custom_command(TARGET open_112 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE_DIR:pmemobj_112>/libpmem-convert.dll
			$<TARGET_FILE_DIR:open_112)
	endif()

	set(COMMON_SOURCES
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/badblocks.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/badblocks_none.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/usc_none.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/pmem2_utils.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/source.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core/alloc.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core/membuf.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core/out.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core/util.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/bad_blocks.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/file.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/mmap.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/pool_hdr.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/set.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/set_badblocks.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/shutdown_state.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/uuid.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/ctl_cow.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/ctl_fallocate.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/ctl_sds.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/ctl.c
		${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/ctl_prefault.c
		)

	if(WIN32)
		set(COMMON_SOURCES ${COMMON_SOURCES}
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core/fs_windows.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core/os_thread_windows.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core/os_windows.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core/util_windows.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/file_windows.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/mmap_windows.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/os_deep_windows.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/uuid_windows.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/deep_flush_windows.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/source_windows.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/persist_windows.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/pmem2_utils_other.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/region_namespace_none.c
			)
	else()
		set(COMMON_SOURCES ${COMMON_SOURCES}
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core/os_posix.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core/fs_posix.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core/os_thread_posix.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core/util_posix.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/file_posix.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/mmap_posix.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/os_deep_linux.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common/uuid_linux.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/deep_flush_linux.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/extent_linux.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/source_posix.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/persist_posix.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/pmem2_utils_linux.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/pmem2_utils_ndctl.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem2/region_namespace_ndctl.c
			)
	endif()

	function(build_libpmemblk_112)
		set(BLK_SOURCES
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemblk/blk.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemblk/btt.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemblk/libpmemblk.c
			${COMMON_SOURCES}
			)

		if(WIN32)
			set(BLK_SOURCES ${BLK_SOURCES}
				${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemblk/libpmemblk_main.c
				)
		endif()

		if(MSVC)
			FILE(READ ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemblk/libpmemblk.def DEFFILE)
			string(REPLACE "libpmemblk" "pmemblk_112" DEFFILE "${DEFFILE}")
			FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/pmemblk_112.def "${DEFFILE}")
			add_library(pmemblk_112 SHARED ${BLK_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/pmemblk_112.def)
			target_compile_options(pmemblk_112 PRIVATE /FI"${CMAKE_SOURCE_DIR}/${VER112}/src/windows/include/platform.h")
		else()
			add_library(pmemblk_112 SHARED ${BLK_SOURCES})
		endif()

		target_compile_definitions(pmemblk_112 PRIVATE SRCVERSION="${MAX_STABLE}")
		target_compile_definitions(pmemblk_112 PRIVATE PMDK_UTF8_API)
		target_compile_definitions(pmemblk_112 PRIVATE _PMEMBLK_INTRNL)

		target_include_directories(pmemblk_112 PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/include)
		target_include_directories(pmemblk_112 PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemblk)
		target_include_directories(pmemblk_112 PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common)
		target_include_directories(pmemblk_112 PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core)
		target_include_directories(pmemblk_112 PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/deps/miniasync/src/include)
		target_include_directories(pmemblk_112 PRIVATE ${PMEM_INCLUDE_DIRS})

		if(WIN32)
			target_include_directories(pmemblk_112 PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/windows/include/)
			target_include_directories(pmemblk_112 PRIVATE ${CMAKE_SOURCE_DIR}/include/)
		endif()

		target_link_libraries(pmemblk_112 PRIVATE libpmem-convert)
		target_link_libraries(pmemblk_112 PRIVATE ${CMAKE_DL_LIBS})
		target_link_libraries(pmemblk_112 PRIVATE ${CMAKE_THREAD_LIBS_INIT})

		if(NOT MSVC)
			FILE(READ ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemblk/libpmemblk.link.in LINKFILE)
			if(DEFINED ENV{FAULT_INJECTION})
				string(REPLACE "fault_injection;" "libpmemblk_inject_fault_at;\n\t\tlibpmemblk_fault_injection_enabled;" LINKFILE "${LINKFILE}")
			else()
				string(REPLACE "fault_injection;" "" LINKFILE "${LINKFILE}")
			endif()
			FILE(WRITE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemblk/libpmemblk.link "${LINKFILE}")
			target_link_libraries(pmemblk_112 PRIVATE -Wl,--version-script=${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemblk/libpmemblk.link)
		endif()
	endfunction(build_libpmemblk_112)

	build_libpmemblk_112()

	function(build_libpmemlog_112)
		set(LOG_SOURCES
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemlog/libpmemlog.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemlog/log.c
			${COMMON_SOURCES}
			)

		if(WIN32)
			set(LOG_SOURCES ${LOG_SOURCES}
				${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemlog/libpmemlog_main.c
				)
		endif()

		if(MSVC)
			FILE(READ ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemlog/libpmemlog.def DEFFILE)
			string(REPLACE "libpmemlog" "pmemlog_112" DEFFILE "${DEFFILE}")
			FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/pmemlog_112.def "${DEFFILE}")
			add_library(pmemlog_112 SHARED ${LOG_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/pmemlog_112.def)
			target_compile_options(pmemlog_112 PRIVATE /FI"${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/windows/include/platform.h")
		else()
			add_library(pmemlog_112 SHARED ${LOG_SOURCES})
		endif()

		target_compile_definitions(pmemlog_112 PRIVATE SRCVERSION="${MAX_STABLE}")
		target_compile_definitions(pmemlog_112 PRIVATE PMDK_UTF8_API)
		target_compile_definitions(pmemlog_112 PRIVATE _PMEMLOG_INTRNL)

		target_include_directories(pmemlog_112 PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/include)
		target_include_directories(pmemlog_112 PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemlog)
		target_include_directories(pmemlog_112 PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common)
		target_include_directories(pmemlog_112 PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core)
		target_include_directories(pmemlog_112 PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/deps/miniasync/src/include)
		target_include_directories(pmemlog_112 PRIVATE ${PMEM_INCLUDE_DIRS})

		if(WIN32)
			target_include_directories(pmemlog_112 PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/windows/include/)
			target_include_directories(pmemlog_112 PRIVATE ${CMAKE_SOURCE_DIR}/include/)
		endif()

		target_link_libraries(pmemlog_112 PRIVATE libpmem-convert)
		target_link_libraries(pmemlog_112 PRIVATE ${CMAKE_DL_LIBS})
		target_link_libraries(pmemlog_112 PRIVATE ${CMAKE_THREAD_LIBS_INIT})

		if(NOT MSVC)
			FILE(READ ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemlog/libpmemlog.link.in LINKFILE)
			if(DEFINED ENV{FAULT_INJECTION})
				string(REPLACE "fault_injection;" "libpmemblk_inject_fault_at;\n\t\tlibpmemblk_fault_injection_enabled;" LINKFILE "${LINKFILE}")
			else()
				string(REPLACE "fault_injection;" "" LINKFILE "${LINKFILE}")
			endif()
			FILE(WRITE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemlog/libpmemlog.link "${LINKFILE}")
			target_link_libraries(pmemlog_112 PRIVATE -Wl,--version-script=${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemlog/libpmemlog.link)
		endif()
	endfunction(build_libpmemlog_112)

	build_libpmemlog_112()

	function(build_pmemspoil)
		set(PMEMSPOIL_SOURCES
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/test/tools/pmemspoil/spoil.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/common.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemblk/btt.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/output.c
			${COMMON_SOURCES}
			)

		if(WIN32)
			set(PMEMSPOIL_SOURCES
				${PMEMSPOIL_SOURCES}
				${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/windows/getopt/getopt.c
				)
		endif()

		add_executable(pmemspoil ${PMEMSPOIL_SOURCES})

		if(WIN32)
			target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/windows/getopt)
			target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/windows/include)
		endif()

		if(MSVC)
			target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/include/)
			target_compile_options(pmemspoil PRIVATE /FI"${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/windows/include/platform.h")
		endif()

		target_compile_definitions(pmemspoil PRIVATE SRCVERSION="${MAX_STABLE}")
		target_compile_definitions(pmemspoil PRIVATE PMDK_UTF8_API)
		target_compile_definitions(pmemspoil PRIVATE LIBDIR="${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")

		target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/include)
		target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common)
		target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core)
		target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemobj)
		target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemlog)
		target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemblk)
		target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool)
		target_include_directories(pmemspoil PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/deps/miniasync/src/include)

		target_link_libraries(pmemspoil PRIVATE ${CMAKE_THREAD_LIBS_INIT})
		target_link_libraries(pmemspoil PRIVATE libpmem-convert)
		target_link_libraries(pmemspoil PRIVATE pmemobj_112)

		if(WIN32)
			# on windows dll and executable must be in the same dir
			add_custom_command(TARGET pmemspoil POST_BUILD
				COMMAND ${CMAKE_COMMAND} -E copy_if_different
				$<TARGET_FILE:libpmem-convert>
				$<TARGET_FILE_DIR:pmemspoil>)
		endif()
	endfunction(build_pmemspoil)

	build_pmemspoil()

	test("spoiled_pool_hdr" spoiled_pool_hdr)

	function(build_pmempool_convert)
		set(PMEMPOOL_SOURCES
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/pmempool.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/check.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/common.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/convert.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/create.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/dump.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/feature.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/info.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/info_blk.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/info_obj.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/info_log.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/output.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/rm.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/synchronize.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool/transform.c

			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core/ravl.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemblk/btt.c

			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemobj/alloc_class.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemobj/bucket.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemobj/container_ravl.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemobj/container_seglists.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemobj/critnib.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemobj/heap.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemobj/memblock.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemobj/memops.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemobj/recycler.c
			${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemobj/ulog.c
			${COMMON_SOURCES}
			)

		if(NOT WIN32)
			set(PMEMPOOL_SOURCES ${PMEMPOOL_SOURCES}
				${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/librpmem/rpmem_util.c)
		endif()

		if(WIN32)
			add_executable(pmempool-convert ${PMEMPOOL_SOURCES} ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/windows/getopt/getopt.c)
			target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/windows/getopt/)
			target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/windows/include/)
			target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/deps/miniasync/src/windows/include)
		else()
			add_executable(pmempool-convert ${PMEMPOOL_SOURCES})
		endif()

		if(MSVC)
			target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/include/)
			target_compile_options(pmempool-convert PRIVATE /FI"${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/windows/include/platform.h")
		endif()

		target_compile_definitions(pmempool-convert PRIVATE SRCVERSION="${MAX_STABLE}")
		target_compile_definitions(pmempool-convert PRIVATE PMDK_UTF8_API)
		target_compile_definitions(pmempool-convert PRIVATE LIBDIR="${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")

		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/include)
		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/common)
		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/core)
		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemlog)
		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemblk)
		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmemobj)
		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmempool)
		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/rpmem_common)
		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/librpmem)
		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/tools/pmempool)
		target_include_directories(pmempool-convert PRIVATE ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/deps/miniasync/src/include)

		target_link_libraries(pmempool-convert PRIVATE ${CMAKE_THREAD_LIBS_INIT})
		target_link_libraries(pmempool-convert PRIVATE ${CMAKE_DL_LIBS})
		target_link_libraries(pmempool-convert PRIVATE libpmem-convert)
		target_link_libraries(pmempool-convert PRIVATE libpmempool-convert)
		target_link_libraries(pmempool-convert PRIVATE pmemobj_112)
		target_link_libraries(pmempool-convert PRIVATE pmemblk_112)
		target_link_libraries(pmempool-convert PRIVATE pmemlog_112)

		if(WIN32)
			# on windows dll and executable must be in the same dir
			add_custom_command(TARGET pmempool-convert POST_BUILD
				COMMAND ${CMAKE_COMMAND} -E copy_if_different
				$<TARGET_FILE:libpmempool-convert>
				$<TARGET_FILE_DIR:pmempool-convert>)
		endif()
	endfunction(build_pmempool_convert)

	build_pmempool_convert()

	test("compare_replicas" compare_replicas)
endif()

if(NOT WIN32)
	if(BUILD_CONVERT_V1)
		add_executable(transaction_10 transaction.c)
		disable_optimization(transaction_10)
		target_include_directories(transaction_10 PRIVATE ${CMAKE_SOURCE_DIR}/${VER10}/src/include)
		target_link_libraries(transaction_10 PRIVATE libpmem-convert)
		target_link_libraries(transaction_10 PRIVATE pmemobj_10)
	endif()

	if(BUILD_CONVERT_V2)
		add_executable(transaction_11 transaction.c)
		disable_optimization(transaction_11)
		target_include_directories(transaction_11 PRIVATE ${CMAKE_SOURCE_DIR}/${VER11}/src/include)
		target_link_libraries(transaction_11 PRIVATE libpmem-convert)
		target_link_libraries(transaction_11 PRIVATE pmemobj_11)
	endif()

	if(BUILD_CONVERT_V3)
		add_executable(transaction_12 transaction.c)
		disable_optimization(transaction_12)
		target_include_directories(transaction_12 PRIVATE ${CMAKE_SOURCE_DIR}/${VER12}/src/include)
		target_link_libraries(transaction_12 PRIVATE libpmem-convert)
		target_link_libraries(transaction_12 PRIVATE pmemobj_12)
	endif()

	if(BUILD_13)
		add_executable(transaction_13 transaction.c)
		disable_optimization(transaction_13)
		target_include_directories(transaction_13 PRIVATE ${CMAKE_SOURCE_DIR}/${VER13}/src/include)
		target_link_libraries(transaction_13 PRIVATE libpmem-convert)
		target_link_libraries(transaction_13 PRIVATE pmemobj_13)
	endif()
endif()

if(BUILD_CONVERT_V4)
	add_executable(transaction_14 transaction.c)
	disable_optimization(transaction_14)
	target_include_directories(transaction_14 PRIVATE ${CMAKE_SOURCE_DIR}/${VER14}/src/include)
	target_compile_definitions(transaction_14 PRIVATE PMEMOBJ_OFFSETOF_WA)
	target_link_libraries(transaction_14 PRIVATE libpmem-convert)
	target_link_libraries(transaction_14 PRIVATE pmemobj_14)
endif()

if(BUILD_15)
	add_executable(transaction_15 transaction.c)
	disable_optimization(transaction_15)
	target_include_directories(transaction_15 PRIVATE ${CMAKE_SOURCE_DIR}/${VER15}/src/include)
	target_compile_definitions(transaction_15 PRIVATE PMEMOBJ_OFFSETOF_WA)
	target_link_libraries(transaction_15 PRIVATE libpmem-convert)
	target_link_libraries(transaction_15 PRIVATE pmemobj_15)
endif()

if(BUILD_CONVERT_V5)
	add_executable(transaction_16 transaction.c)
	disable_optimization(transaction_16)
	target_include_directories(transaction_16 PRIVATE ${CMAKE_SOURCE_DIR}/${VER16}/src/include)
	target_compile_definitions(transaction_16 PRIVATE PMEMOBJ_OFFSETOF_WA)
	target_link_libraries(transaction_16 PRIVATE libpmem-convert)
	target_link_libraries(transaction_16 PRIVATE pmemobj_16)
endif()

if(BUILD_17)
	add_executable(transaction_17 transaction.c)
	disable_optimization(transaction_17)
	target_include_directories(transaction_17 PRIVATE ${CMAKE_SOURCE_DIR}/${VER17}/src/include)
	target_compile_definitions(transaction_17 PRIVATE PMEMOBJ_OFFSETOF_WA)
	target_link_libraries(transaction_17 PRIVATE libpmem-convert)
	target_link_libraries(transaction_17 PRIVATE pmemobj_17)
endif()

if(BUILD_18)
	add_executable(transaction_18 transaction.c)
	disable_optimization(transaction_18)
	target_include_directories(transaction_18 PRIVATE ${CMAKE_SOURCE_DIR}/${VER18}/src/include)
	target_link_libraries(transaction_18 PRIVATE libpmem-convert)
	target_link_libraries(transaction_18 PRIVATE pmemobj_18)
endif()

if(BUILD_19)
	add_executable(transaction_19 transaction.c)
	disable_optimization(transaction_19)
	target_include_directories(transaction_19 PRIVATE ${CMAKE_SOURCE_DIR}/${VER19}/src/include)
	target_link_libraries(transaction_19 PRIVATE libpmem-convert)
	target_link_libraries(transaction_19 PRIVATE pmemobj_19)
endif()

if(BUILD_110)
	add_executable(transaction_110 transaction.c)
	disable_optimization(transaction_110)
	target_include_directories(transaction_110 PRIVATE ${CMAKE_SOURCE_DIR}/${VER110}/src/include)
	target_link_libraries(transaction_110 PRIVATE libpmem-convert)
	target_link_libraries(transaction_110 PRIVATE pmemobj_110)
endif()

if(BUILD_111)
	add_executable(transaction_111 transaction.c)
	disable_optimization(transaction_111)
	target_include_directories(transaction_111 PRIVATE ${CMAKE_SOURCE_DIR}/${VER110}/src/include)
	target_link_libraries(transaction_111 PRIVATE libpmem-convert)
	target_link_libraries(transaction_111 PRIVATE pmemobj_111)
endif()

if(BUILD_CONVERT_V6)
	add_executable(transaction_112 transaction.c)
	disable_optimization(transaction_112)
	target_include_directories(transaction_112 PRIVATE ${CMAKE_SOURCE_DIR}/${VER111}/src/include)
	target_link_libraries(transaction_112 PRIVATE libpmem-convert)
	target_link_libraries(transaction_112 PRIVATE pmemobj_112)
endif()

if(MSVC)
	if(BUILD_CONVERT_V4)
		# project has to be compile as c++ project so we need to change the flag
		SET_SOURCE_FILES_PROPERTIES(transaction.c PROPERTIES LANGUAGE CXX)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET transaction_14 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_14>
			$<TARGET_FILE_DIR:transaction_14>)

		add_custom_command(TARGET transaction_14 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE_DIR:pmemobj_14>/libpmem-convert.dll
			$<TARGET_FILE_DIR:transaction_14>)
	endif()

	if(BUILD_CONVERT_V5)
		# project has to be compile as c++ project so we need to change the flag
		SET_SOURCE_FILES_PROPERTIES(transaction.c PROPERTIES LANGUAGE CXX)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET transaction_16 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_16>
			$<TARGET_FILE_DIR:transaction_16>)

		add_custom_command(TARGET transaction_16 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE_DIR:pmemobj_16>/libpmem-convert.dll
			$<TARGET_FILE_DIR:transaction_16>)
	endif()

	if(BUILD_CONVERT_V6)
		# project has to be compile as c++ project so we need to change the flag
		SET_SOURCE_FILES_PROPERTIES(transaction.c PROPERTIES LANGUAGE CXX)
		# on windows dll and executable must be in the same dir
		add_custom_command(TARGET transaction_112 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_112>
			$<TARGET_FILE_DIR:transaction_112>)

		add_custom_command(TARGET transaction_112 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE_DIR:pmemobj_112>/libpmem-convert.dll
			$<TARGET_FILE_DIR:transaction_112>)
	endif()
endif()

test("cli_test" cli)

add_executable(clean_pool clean.c)
target_include_directories(clean_pool PRIVATE ${LIBPMEMPOOL_INCLUDE_DIRS})
target_link_libraries(clean_pool PRIVATE ${LIBPMEMPOOL_LIBRARIES})
file(WRITE ${TEST_DIR}/../tx_intr.lock "")

if(NOT WIN32)
	if(DEVICE_DAX_PATHS)
		file(WRITE ${TEST_DIR}/../devdax.lock "")
	endif()

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
else()
	if(CMAKE_BUILD_TYPE STREQUAL Debug OR CMAKE_BUILD_TYPE STREQUAL RelWithDebInfo)
		set_cdb_executable()
		if(CDB_EXE)
			test("tx_intr_pool_regfile" tx_intr_pool_regfile)
			test("tx_intr_poolset_local_2regfiles" tx_intr_poolset_local_2regfiles)
			test("tx_intr_poolset_local_regfile" tx_intr_poolset_local_regfile)
			test("tx_intr_poolset_local_regfile_rep_regfile" tx_intr_poolset_local_regfile_rep_regfile)
		else()
			test("tx_intr_pool_regfile_SKIP_BECAUSE_OF_NO_CDB_DEBUGGER" skip_test)
			test("tx_intr_poolset_local_2regfiles_SKIP_BECAUSE_OF_NO_CDB_DEBUGGER" skip_test)
			test("tx_intr_poolset_local_regfile_SKIP_BECAUSE_OF_NO_CDB_DEBUGGER" skip_test)
			test("tx_intr_poolset_local_regfile_rep_regfile_SKIP_BECAUSE_OF_NO_CDB_DEBUGGER" skip_test)
		endif()
	else()
		test("tx_intr_pool_regfile_SKIP_BECAUSE_OF_NO_DEBUG_BUILD_TYPE" skip_test)
		test("tx_intr_poolset_local_2regfiles_SKIP_BECAUSE_OF_NO_DEBUG_BUILD_TYPE" skip_test)
		test("tx_intr_poolset_local_regfile_SKIP_BECAUSE_OF_NO_DEBUG_BUILD_TYPE" skip_test)
		test("tx_intr_poolset_local_regfile_rep_regfile_SKIP_BECAUSE_OF_NO_DEBUG_BUILD_TYPE" skip_test)
	endif()
endif()
