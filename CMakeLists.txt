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

cmake_minimum_required(VERSION 3.3)
project(pmdk-convert C CXX)

set(VERSION_MAJOR 1)
set(VERSION_MINOR 7)
set(VERSION_PATCH 0)
#set(VERSION_PRERELEASE rc0)

set(VERSION ${VERSION_MAJOR}.${VERSION_MINOR})
if (VERSION_PATCH GREATER 0)
	set(VERSION ${VERSION}.${VERSION_PATCH})
endif()
if (VERSION_PRERELEASE)
	set(VERSION ${VERSION}-${VERSION_PRERELEASE})
endif()

set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR})

include(FindThreads)

if(WIN32)
	set(MIN_VERSION 1.4 CACHE STRING "First supported version (major.minor)")
else()
	set(MIN_VERSION 1.0 CACHE STRING "First supported version (major.minor)")
endif()

set(MAX_VERSION 1.7)
set(MAX_STABLE 1.7)

if(MIN_VERSION VERSION_GREATER_EQUAL MAX_VERSION)
	message(FATAL_ERROR "ERROR: Minimum PMDK version cannot be greater than or equal to maximum PMDK version")
endif()

STRING(REGEX REPLACE "^([0-9]+)\\.[0-9]+" "\\1" MIN_VERSION_MAJOR "${MIN_VERSION}")
STRING(REGEX REPLACE "^[0-9]+\\.([0-9]+)" "\\1" MIN_VERSION_MINOR "${MIN_VERSION}")

STRING(REGEX REPLACE "^([0-9]+)\\.[0-9]+" "\\1" MAX_VERSION_MAJOR "${MAX_VERSION}")
STRING(REGEX REPLACE "^[0-9]+\\.([0-9]+)" "\\1" MAX_VERSION_MINOR "${MAX_VERSION}")

if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE "RelWithDebInfo")
endif (NOT CMAKE_BUILD_TYPE)

include(CheckCCompilerFlag)
include(GNUInstallDirs)
if(NOT MSVC)
	find_package(PkgConfig QUIET)
endif()

set(CMAKE_C_STANDARD 99)

# Checks whether flag is supported by current C compiler and appends
# it to the relevant cmake variable.
# 1st argument is a flag
# 2nd (optional) argument is a build type (debug, release, relwithdebinfo)
macro(add_c_flag flag)
	string(REPLACE - _ flag2 ${flag})
	string(REPLACE " " _ flag2 ${flag2})
	string(REPLACE = "_" flag2 ${flag2})
	set(check_name "C_HAS_${flag2}")

	check_c_compiler_flag("${flag}" "${check_name}")

	if (${${check_name}})
		if (${ARGC} EQUAL 1)
			set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${flag}")
		else()
			set(CMAKE_C_FLAGS_${ARGV1} "${CMAKE_C_FLAGS_${ARGV1}} ${flag}")
		endif()
	endif()
endmacro()

if(NOT MSVC)
	add_c_flag(-fno-common)
	add_c_flag(-Wall)
	add_c_flag(-Wconversion)
	add_c_flag(-Wmissing-field-initializers)
	add_c_flag(-Wmissing-prototypes)
	add_c_flag(-Wmissing-variable-declarations)
	add_c_flag(-Wpointer-arith)
	add_c_flag(-Wsign-compare)
	add_c_flag(-Wsign-conversion)
	add_c_flag(-Wunused-macros)
	add_c_flag(-Wunreachable-code-return)

	# Place each function or data item into its own section. Will be used to strip unneeded symbols.
	add_c_flag(-fdata-sections)
	add_c_flag(-ffunction-sections)

	add_c_flag(-ggdb DEBUG)
	add_c_flag(-DDEBUG DEBUG)

	add_c_flag(-ggdb RELWITHDEBINFO)
	add_c_flag(-fno-omit-frame-pointer RELWITHDEBINFO)

	check_c_compiler_flag(-Wl,-z,relro LINKER_HAS_RELRO)
	if(LINKER_HAS_RELRO)
		set(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS}  -Wl,-z,relro")
		set(CMAKE_SHARED_LINKER_FLAGS  "${CMAKE_SHARED_LINKER_FLAGS}  -Wl,-z,relro")
	endif()

	check_c_compiler_flag(-Wl,--warn-common LINKER_HAS_WARN_COMMON)
	if(LINKER_HAS_WARN_COMMON)
		set(CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} -Wl,--warn-common")
		set(CMAKE_SHARED_LINKER_FLAGS  "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--warn-common")
	endif()

	add_c_flag("-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2" RELEASE)
endif()

configure_file(
	"${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
	"${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
	IMMEDIATE @ONLY)

add_custom_target(uninstall
	COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)


function(version_supported ver ver_next RESULT)
	if (${MIN_VERSION} VERSION_GREATER ${ver})
		set(${RESULT} 0 PARENT_SCOPE)
		return()
	endif()
	if (${ver_next} VERSION_GREATER ${MAX_VERSION})
		set(${RESULT} 0 PARENT_SCOPE)
		return()
	endif()
	set(${RESULT} 1 PARENT_SCOPE)
	return()
endfunction(version_supported)

# disabled by default:
set(BUILD_13 0)
set(BUILD_15 0)

if (${MIN_VERSION} EQUAL 1.0)
	set(BUILD_CONVERT_V1 1)
	set(BUILD_CONVERT_V2 1)
	set(BUILD_CONVERT_V3 1)
	set(BUILD_13 1)
	set(BUILD_CONVERT_V4 1)
	set(BUILD_CONVERT_V5 1)
	set(BUILD_CONVERT_V6 1)
	set(BUILD_15 1)
elseif (${MIN_VERSION} EQUAL 1.1)
	set(BUILD_CONVERT_V2 1)
	set(BUILD_CONVERT_V3 1)
	set(BUILD_13 1)
	set(BUILD_CONVERT_V4 1)
	set(BUILD_CONVERT_V5 1)
	set(BUILD_15 1)
elseif (${MIN_VERSION} EQUAL 1.2)
	set(BUILD_CONVERT_V3 1)
	set(BUILD_13 1)
	set(BUILD_CONVERT_V4 1)
	set(BUILD_CONVERT_V5 1)
	set(BUILD_15 1)
	set(BUILD_CONVERT_V6 1)
elseif (${MIN_VERSION} EQUAL 1.3)
	set(BUILD_13 1)
	set(BUILD_CONVERT_V4 1)
	set(BUILD_CONVERT_V5 1)
	set(BUILD_15 1)
	set(BUILD_CONVERT_V6 1)
elseif (${MIN_VERSION} EQUAL 1.4)
	set(BUILD_CONVERT_V4 1)
	set(BUILD_CONVERT_V5 1)
	set(BUILD_15 1)
	set(BUILD_CONVERT_V6 1)
elseif (${MIN_VERSION} EQUAL 1.5)
	set(BUILD_CONVERT_V5 1)
	set(BUILD_15 1)
	set(BUILD_CONVERT_V6 1)
elseif (${MIN_VERSION} EQUAL 1.6)
	set(BUILD_CONVERT_V5 1)
	set(BUILD_CONVERT_V6 1)
elseif (${MIN_VERSION} EQUAL 1.7)
	set(BUILD_CONVERT_V6 1)
endif()

add_executable(check_license EXCLUDE_FROM_ALL utils/check_license/check-license.c)

# Generates cstyle-$name target and attaches it as a dependency of global
# "cstyle" target. This target verifies C style of files in current source dir.
# If more arguments are used, then they are used as files to be checked
# instead.
# ${name} must be unique.
function(add_cstyle name)
	if(${ARGC} EQUAL 1)
		add_custom_target(cstyle-${name}
			COMMAND ${PERL_EXECUTABLE}
			${CMAKE_SOURCE_DIR}/utils/cstyle
			${CMAKE_CURRENT_SOURCE_DIR}/*.c
			${CMAKE_CURRENT_SOURCE_DIR}/*.h)
	else()
		add_custom_target(cstyle-${name}
			COMMAND ${PERL_EXECUTABLE}
			${CMAKE_SOURCE_DIR}/utils/cstyle ${ARGN})
	endif()
	add_dependencies(cstyle cstyle-${name})
endfunction()

# Generates check-whitespace-$name target and attaches it as a dependency
# of global "check-whitespace" target. This target verifies C files in current
# source dir do not have any whitespace errors.
# If more arguments are used, then they are used as files to be checked
# instead.
# ${name} must be unique.
function(add_check_whitespace name)
	if(${ARGC} EQUAL 1)
		add_custom_target(check-whitespace-${name}
			COMMAND ${PERL_EXECUTABLE}
			${CMAKE_SOURCE_DIR}/utils/check_whitespace
			${CMAKE_CURRENT_SOURCE_DIR}/*.c
			${CMAKE_CURRENT_SOURCE_DIR}/*.h)
	else()
		add_custom_target(check-whitespace-${name}
			COMMAND ${PERL_EXECUTABLE}
			${CMAKE_SOURCE_DIR}/utils/check_whitespace ${ARGN})
	endif()
	add_dependencies(check-whitespace check-whitespace-${name})
endfunction()

add_custom_target(checkers ALL)
add_custom_target(cstyle)
add_custom_target(check-whitespace)
add_custom_target(check-license
	COMMAND ${CMAKE_SOURCE_DIR}/utils/check_license/check-headers.sh
	${CMAKE_SOURCE_DIR}
	${CMAKE_BINARY_DIR}/check_license
	${CMAKE_SOURCE_DIR}/LICENSE
	-a)
add_custom_target(md2man
	COMMAND ${CMAKE_SOURCE_DIR}/utils/md2man/md2man.sh
	${CMAKE_SOURCE_DIR}/doc/pmdk-convert/pmdk-convert.1.md
	${CMAKE_SOURCE_DIR}/utils/md2man/default.man
	${CMAKE_SOURCE_DIR}/doc/generated/pmdk-convert.1
	)

if (NOT WIN32)
	install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/doc/generated/pmdk-convert.1
		DESTINATION ${CMAKE_INSTALL_MANDIR}/man1)
endif()

add_dependencies(check-license check_license)

add_cstyle(main)
add_cstyle(check_license ${CMAKE_SOURCE_DIR}/utils/check_license/*.c)

add_check_whitespace(check_license ${CMAKE_SOURCE_DIR}/utils/check_license/*.c)
add_check_whitespace(src)
add_check_whitespace(other
	${CMAKE_SOURCE_DIR}/utils/check_license/*.sh
	${CMAKE_SOURCE_DIR}/README.md
	${CMAKE_SOURCE_DIR}/CMakeLists.txt
	${CMAKE_SOURCE_DIR}/tests/CMakeLists.txt
	${CMAKE_SOURCE_DIR}/*.cmake
	${CMAKE_SOURCE_DIR}/tests/*.cmake
	#			${CMAKE_SOURCE_DIR}/utils/*.sh
	#			${CMAKE_SOURCE_DIR}/*.spec
	#			${CMAKE_SOURCE_DIR}/debian/*
	#			${CMAKE_SOURCE_DIR}/debian/*/*
	#			${CMAKE_SOURCE_DIR}/doc/*.md
	)

option(DEVELOPER_MODE "enable developer checks" OFF)
if(DEVELOPER_MODE)
	add_dependencies(checkers cstyle)
	add_dependencies(checkers check-whitespace)
	add_dependencies(checkers check-license)
endif(DEVELOPER_MODE)

function(uncompress file)
	execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${CMAKE_SOURCE_DIR}/${file}
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		RESULT_VARIABLE RET)
	if(RET)
		message(FATAL_ERROR "Couldn't uncompress ${file}")
	endif()
endfunction()

function(get_pmdk ver hash dstdir)
	set(pkg ${CMAKE_SOURCE_DIR}/${ver}.tar.gz)

	if (EXISTS ${pkg})
		file(SHA256 ${pkg} pkg_hash)
		if (NOT ${pkg_hash} STREQUAL ${hash})
			message(STATUS "Hash for version ${ver} doesn't match the expected value.")
			if (EXISTS ${CMAKE_SOURCE_DIR}/${dstdir})
				message(STATUS "Removing ${CMAKE_SOURCE_DIR}/${dstdir}.")
				file(REMOVE_RECURSE ${CMAKE_SOURCE_DIR}/${dstdir})
			endif()
			message(STATUS "Removing ${pkg}.")
			file(REMOVE ${pkg})
		endif()
	endif()

	if (NOT EXISTS ${pkg})
		if (EXISTS ${CMAKE_SOURCE_DIR}/${dstdir})
			message(STATUS "Removing ${CMAKE_SOURCE_DIR}/${dstdir}.")
			file(REMOVE_RECURSE ${CMAKE_SOURCE_DIR}/${dstdir})
		endif()

		message(STATUS "Downloading ${ver}.tar.gz")
		if (${ver} STREQUAL "1.0" OR ${ver} STREQUAL "1.1")
			file(DOWNLOAD https://github.com/pmem/pmdk/archive/${ver}.tar.gz ${CMAKE_SOURCE_DIR}/${ver}.tar.gz
				EXPECTED_HASH SHA256=${hash})
		else()
			file(DOWNLOAD https://github.com/pmem/pmdk/releases/download/${ver}/pmdk-${ver}.tar.gz ${CMAKE_SOURCE_DIR}/${ver}.tar.gz
				EXPECTED_HASH SHA256=${hash})
		endif()
		message(STATUS "Downloading ${ver}.tar.gz DONE")
	endif()

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${dstdir})
		message(STATUS "Uncompressing ${ver}.tar.gz")
		uncompress(${ver}.tar.gz)
		message(STATUS "Uncompressing ${ver}.tar.gz DONE")

		file(RENAME ${CMAKE_SOURCE_DIR}/pmdk-${ver} ${CMAKE_SOURCE_DIR}/${dstdir})
	endif()
endfunction()


if(BUILD_CONVERT_V6)
	set(VER17 1.7)

	get_pmdk(${VER17} 865ce1b422bc83109cb4a63dcff8fd1077eea3617e668faf6a043208d8be03ca ${VER17})

	function(build_libpmem_convert)
		set(LIBPMEM_SOURCES
			${MAX_STABLE}/src/common/alloc.c
			${MAX_STABLE}/src/common/file.c
			${MAX_STABLE}/src/common/mmap.c
			${MAX_STABLE}/src/common/out.c
			${MAX_STABLE}/src/common/util.c
			${MAX_STABLE}/src/libpmem/libpmem.c
			${MAX_STABLE}/src/libpmem/memops_generic.c
			${MAX_STABLE}/src/libpmem/pmem.c
			)
		if (CMAKE_SYSTEM_PROCESSOR STREQUAL x86_64
			OR CMAKE_SYSTEM_PROCESSOR STREQUAL amd64
			OR CMAKE_SYSTEM_PROCESSOR STREQUAL AMD64)
			set(LIBPMEM_SOURCES ${LIBPMEM_SOURCES}
				${MAX_STABLE}/src/libpmem/x86_64/init.c
				${MAX_STABLE}/src/libpmem/x86_64/cpu.c
				)
		elseif (CMAKE_SYSTEM_PROCESSOR STREQUAL aarch64)
			set(LIBPMEM_SOURCES ${LIBPMEM_SOURCES}
				${MAX_STABLE}/src/libpmem/aarch64/init.c
				)
		else()
			message(FATAL_ERROR "Unknown architecture ${CMAKE_SYSTEM_PROCESSOR}")
		endif()

		if(WIN32)
			set(LIBPMEM_SOURCES ${LIBPMEM_SOURCES}
				${MAX_STABLE}/src/libpmem/libpmem_main.c
				${MAX_STABLE}/src/libpmem/pmem_windows.c
				${MAX_STABLE}/src/windows/win_mmap.c
				${MAX_STABLE}/src/common/file_windows.c
				${MAX_STABLE}/src/common/fs_windows.c
				${MAX_STABLE}/src/common/mmap_windows.c
				${MAX_STABLE}/src/common/os_auto_flush_windows.c
				${MAX_STABLE}/src/common/os_deep_windows.c
				${MAX_STABLE}/src/common/os_windows.c
				${MAX_STABLE}/src/common/os_thread_windows.c
				${MAX_STABLE}/src/common/util_windows.c
				)
		else()
			set(LIBPMEM_SOURCES ${LIBPMEM_SOURCES}
				${MAX_STABLE}/src/libpmem/pmem_posix.c
				${MAX_STABLE}/src/common/file_posix.c
				${MAX_STABLE}/src/common/fs_posix.c
				${MAX_STABLE}/src/common/mmap_posix.c
				${MAX_STABLE}/src/common/os_auto_flush_linux.c
				${MAX_STABLE}/src/common/os_deep_linux.c
				${MAX_STABLE}/src/common/os_posix.c
				${MAX_STABLE}/src/common/os_thread_posix.c
				${MAX_STABLE}/src/common/util_posix.c
				)
		endif()

		if(MSVC)
			FILE(READ ${MAX_STABLE}/src/libpmem/libpmem.def DEFFILE)
			string(REPLACE "libpmem" "libpmem-convert" DEFFILE "${DEFFILE}")
			FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/libpmem.def "${DEFFILE}")
			add_library(libpmem-convert SHARED ${LIBPMEM_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/libpmem.def)
			target_link_libraries(libpmem-convert PRIVATE ntdll.lib)
		else()
			add_library(libpmem-convert SHARED ${LIBPMEM_SOURCES})
			FILE(READ ${MAX_STABLE}/src/libpmem/libpmem.link.in LINKFILE)
			string(REPLACE "fault_injection;" "" LINKFILE "${LINKFILE}")
			FILE(WRITE ${MAX_STABLE}/src/libpmem/libpmem.link "${LINKFILE}")
			target_link_libraries(libpmem-convert PRIVATE -Wl,--version-script=${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmem/libpmem.link)
		endif()

		# remove lib prefix from library name
		set_target_properties(libpmem-convert PROPERTIES PREFIX "")
		target_compile_definitions(libpmem-convert PRIVATE SRCVERSION="${MAX_STABLE}")
		target_compile_definitions(libpmem-convert PRIVATE PMDK_UTF8_API)
		target_compile_definitions(libpmem-convert PRIVATE _PMEMOBJ_INTRNL)
		target_compile_definitions(libpmem-convert PRIVATE SSE2_AVAILABLE=0)
		target_compile_definitions(libpmem-convert PRIVATE AVX_AVAILABLE=0)
		target_compile_definitions(libpmem-convert PRIVATE AVX512F_AVAILABLE=0)

		target_include_directories(libpmem-convert PRIVATE ${MAX_STABLE}/src/include)
		target_include_directories(libpmem-convert PRIVATE ${MAX_STABLE}/src/common)
		target_include_directories(libpmem-convert PRIVATE ${MAX_STABLE}/src/libpmem)

		if(MSVC)
			target_include_directories(libpmem-convert PRIVATE ${MAX_STABLE}/src/windows/include/)
			target_include_directories(libpmem-convert PRIVATE include/)
			target_compile_options(libpmem-convert PRIVATE /FI"${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/windows/include/platform.h")
		endif()

		target_link_libraries(libpmem-convert PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	endfunction(build_libpmem_convert)

	build_libpmem_convert()

	set(PMEM_INCLUDE_DIRS ${MAX_STABLE}/src/include)
	set(PMEM_LIBRARIES libpmem-convert)
	install(TARGETS libpmem-convert
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	function(build_libpmempool_convert)
		set(LIBPMEMPOOL_SOURCES
			${MAX_STABLE}/src/libpmempool/check_backup.c
			${MAX_STABLE}/src/libpmempool/check_bad_blocks.c
			${MAX_STABLE}/src/libpmempool/check_blk.c
			${MAX_STABLE}/src/libpmempool/check_btt_info.c
			${MAX_STABLE}/src/libpmempool/check_btt_map_flog.c
			${MAX_STABLE}/src/libpmempool/check.c
			${MAX_STABLE}/src/libpmempool/check_log.c
			${MAX_STABLE}/src/libpmempool/check_pool_hdr.c
			${MAX_STABLE}/src/libpmempool/check_sds.c
			${MAX_STABLE}/src/libpmempool/check_util.c
			${MAX_STABLE}/src/libpmempool/check_write.c
			${MAX_STABLE}/src/libpmempool/feature.c
			${MAX_STABLE}/src/libpmempool/libpmempool.c
			${MAX_STABLE}/src/libpmempool/pool.c
			${MAX_STABLE}/src/libpmempool/replica.c
			${MAX_STABLE}/src/libpmempool/rm.c
			${MAX_STABLE}/src/libpmempool/sync.c
			${MAX_STABLE}/src/libpmempool/transform.c

			${MAX_STABLE}/src/libpmemblk/btt.c

			${MAX_STABLE}/src/common/alloc.c
			${MAX_STABLE}/src/common/badblock.c
			${MAX_STABLE}/src/common/file.c
			${MAX_STABLE}/src/common/mmap.c
			${MAX_STABLE}/src/common/pool_hdr.c
			${MAX_STABLE}/src/common/out.c
			${MAX_STABLE}/src/common/os_dimm_none.c
			${MAX_STABLE}/src/common/set.c
			${MAX_STABLE}/src/common/shutdown_state.c
			${MAX_STABLE}/src/common/util.c
			${MAX_STABLE}/src/common/uuid.c
			)

		if(WIN32)
			set(LIBPMEMPOOL_SOURCES ${LIBPMEMPOOL_SOURCES}
				${MAX_STABLE}/src/libpmempool/libpmempool_main.c
				${MAX_STABLE}/src/common/badblock_none.c
				${MAX_STABLE}/src/common/file_windows.c
				${MAX_STABLE}/src/common/fs_windows.c
				${MAX_STABLE}/src/common/mmap_windows.c
				${MAX_STABLE}/src/common/os_deep_windows.c
				${MAX_STABLE}/src/common/os_thread_windows.c
				${MAX_STABLE}/src/common/os_windows.c
				${MAX_STABLE}/src/common/util_windows.c
				${MAX_STABLE}/src/common/uuid_windows.c
				)
		else()
			set(LIBPMEMPOOL_SOURCES ${LIBPMEMPOOL_SOURCES}
				${MAX_STABLE}/src/common/badblock_ndctl.c
				${MAX_STABLE}/src/common/extent_linux.c
				${MAX_STABLE}/src/common/file_posix.c
				${MAX_STABLE}/src/common/fs_posix.c
				${MAX_STABLE}/src/common/mmap_posix.c
				${MAX_STABLE}/src/common/os_deep_linux.c
				${MAX_STABLE}/src/common/os_posix.c
				${MAX_STABLE}/src/common/os_thread_posix.c
				${MAX_STABLE}/src/common/util_posix.c
				${MAX_STABLE}/src/common/uuid_linux.c
				)
		endif()

		if(MSVC)
			FILE(READ ${MAX_STABLE}/src/libpmempool/libpmempool.def DEFFILE)
			string(REPLACE "libpmempool" "libpmempool-convert" DEFFILE "${DEFFILE}")
			FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/libpmempool.def "${DEFFILE}")
			add_library(libpmempool-convert SHARED ${LIBPMEMPOOL_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/libpmempool.def)
		else()
			FILE(READ ${MAX_STABLE}/src/libpmempool/libpmempool.link.in LINKFILE)
			string(REPLACE "fault_injection;" "" LINKFILE "${LINKFILE}")
			FILE(WRITE ${MAX_STABLE}/src/libpmempool/libpmempool.link "${LINKFILE}")

			add_library(libpmempool-convert SHARED ${LIBPMEMPOOL_SOURCES})
			target_link_libraries(libpmempool-convert PRIVATE -Wl,--version-script=${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/libpmempool/libpmempool.link)
		endif()
		target_link_libraries(libpmempool-convert PRIVATE libpmem-convert)

		target_compile_definitions(libpmempool-convert PRIVATE SRCVERSION="${MAX_STABLE}")
		target_compile_definitions(libpmempool-convert PRIVATE PMDK_UTF8_API)

		target_include_directories(libpmempool-convert PRIVATE ${MAX_STABLE}/src/include)
		target_include_directories(libpmempool-convert PRIVATE ${MAX_STABLE}/src/common)
		target_include_directories(libpmempool-convert PRIVATE ${MAX_STABLE}/src/libpmempool)
		target_include_directories(libpmempool-convert PRIVATE ${MAX_STABLE}/src/libpmemblk)
		target_include_directories(libpmempool-convert PRIVATE ${MAX_STABLE}/src/libpmemlog)
		target_include_directories(libpmempool-convert PRIVATE ${MAX_STABLE}/src/libpmemobj)

		if(MSVC)
			target_include_directories(libpmempool-convert PRIVATE ${MAX_STABLE}/src/windows/include/)
			target_include_directories(libpmempool-convert PRIVATE include/)
			target_compile_options(libpmempool-convert PRIVATE /FI"${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/windows/include/platform.h")
		endif()

		target_link_libraries(libpmempool-convert PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	endfunction(build_libpmempool_convert)

	build_libpmempool_convert()

	set(LIBPMEMPOOL_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/include)
	set(LIBPMEMPOOL_LIBRARIES libpmempool-convert)

	set(SOURCES_17
		${VER17}/src/libpmemobj/alloc_class.c
		${VER17}/src/libpmemobj/bucket.c
		${VER17}/src/libpmemobj/critnib.c
		${VER17}/src/libpmemobj/ctl_debug.c
		${VER17}/src/libpmemobj/container_ravl.c
		${VER17}/src/libpmemobj/container_seglists.c
		${VER17}/src/libpmemobj/heap.c
		${VER17}/src/libpmemobj/lane.c
		${VER17}/src/libpmemobj/libpmemobj.c
		${VER17}/src/libpmemobj/list.c
		${VER17}/src/libpmemobj/memblock.c
		${VER17}/src/libpmemobj/memops.c
		${VER17}/src/libpmemobj/obj.c
		${VER17}/src/libpmemobj/palloc.c
		${VER17}/src/libpmemobj/pmalloc.c
		${VER17}/src/libpmemobj/ravl.c
		${VER17}/src/libpmemobj/recycler.c
		${VER17}/src/libpmemobj/stats.c
		${VER17}/src/libpmemobj/sync.c
		${VER17}/src/libpmemobj/tx.c
		${VER17}/src/libpmemobj/ulog.c

		${VER17}/src/common/alloc.c
		${VER17}/src/common/badblock.c
		${VER17}/src/common/ctl.c
		${VER17}/src/common/ctl_cow.c
		${VER17}/src/common/ctl_fallocate.c
		${VER17}/src/common/ctl_prefault.c
		${VER17}/src/common/ctl_sds.c
		${VER17}/src/common/file.c
		${VER17}/src/common/mmap.c
		${VER17}/src/common/os_dimm_none.c
		${VER17}/src/common/out.c
		${VER17}/src/common/pool_hdr.c
		${VER17}/src/common/set.c
		${VER17}/src/common/shutdown_state.c
		${VER17}/src/common/util.c
		${VER17}/src/common/uuid.c
		)

	if(WIN32)
		set(SOURCES_17 ${SOURCES_17}
			${VER17}/src/libpmemobj/libpmemobj_main.c
			${VER17}/src/common/badblock_none.c
			${VER17}/src/common/file_windows.c
			${VER17}/src/common/fs_windows.c
			${VER17}/src/common/mmap_windows.c
			${VER17}/src/common/os_deep_windows.c
			${VER17}/src/common/os_windows.c
			${VER17}/src/common/os_thread_windows.c
			${VER17}/src/common/util_windows.c
			${VER17}/src/common/uuid_windows.c
			)
	else()
		set(SOURCES_17 ${SOURCES_17}
			${VER17}/src/common/badblock_ndctl.c
			${VER17}/src/common/extent_linux.c
			${VER17}/src/common/file_posix.c
			${VER17}/src/common/fs_posix.c
			${VER17}/src/common/mmap_posix.c
			${VER17}/src/common/os_deep_linux.c
			${VER17}/src/common/os_posix.c
			${VER17}/src/common/os_thread_posix.c
			${VER17}/src/common/util_posix.c
			${VER17}/src/common/uuid_linux.c
			)
	endif()

	function(build_convert_v6)
		if(WIN32)
			set(CONVERT_V6_SOURCES ${VER17}/src/windows/getopt/getopt.c)
		endif()

		add_library(pmemobj_convert_v6_o OBJECT ${SOURCES_17} ${CONVERT_V6_SOURCES}
			pmemobj_convert_v6.c
			${VER17}/src/libpmemblk/btt.c
			${VER17}/src/tools/pmempool/common.c
			${VER17}/src/tools/pmempool/output.c)

		target_compile_definitions(pmemobj_convert_v6_o PRIVATE SRCVERSION="${VER17}")
		target_compile_definitions(pmemobj_convert_v6_o PRIVATE PMDK_UTF8_API)
		target_compile_definitions(pmemobj_convert_v6_o PRIVATE _PMEMOBJ_INTRNL)

		target_include_directories(pmemobj_convert_v6_o PRIVATE ${VER17}/src/include)
		target_include_directories(pmemobj_convert_v6_o PRIVATE ${VER17}/src/libpmemobj)
		target_include_directories(pmemobj_convert_v6_o PRIVATE ${VER17}/src/libpmemlog)
		target_include_directories(pmemobj_convert_v6_o PRIVATE ${VER17}/src/libpmemblk)
		target_include_directories(pmemobj_convert_v6_o PRIVATE ${VER17}/src/common)
		target_include_directories(pmemobj_convert_v6_o PRIVATE ${PMEM_INCLUDE_DIRS})

		if(MSVC)
			target_include_directories(pmemobj_convert_v6_o PRIVATE ${VER17}/src/windows/include/)
			target_include_directories(pmemobj_convert_v6_o PRIVATE ${VER17}/src/windows/getopt/)
			target_include_directories(pmemobj_convert_v6_o PRIVATE include/)
			target_compile_options(pmemobj_convert_v6_o PRIVATE /FI"${CMAKE_SOURCE_DIR}/${VER17}/src/windows/include/platform.h")
		endif()

		if(MSVC)
			add_library(pmemobj_convert_v6_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_v6_o> ${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert_v6.def)
		else()
			add_library(pmemobj_convert_v6_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_v6_o>)
			target_link_libraries(pmemobj_convert_v6_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert.map)
		endif()

		target_link_libraries(pmemobj_convert_v6_shared PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_convert_v6_shared PRIVATE ${CMAKE_DL_LIBS})
		target_link_libraries(pmemobj_convert_v6_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
		if(NOT MSVC)
			# strip unneeded symbols, requires -fdata-sections -ffunction-sections
			target_link_libraries(pmemobj_convert_v6_shared PRIVATE -Wl,--gc-sections)
		endif()

		set_target_properties(pmemobj_convert_v6_shared PROPERTIES OUTPUT_NAME pmemobj_convert_v6)
		# remove lib prefix from library name
		set_target_properties(pmemobj_convert_v6_shared PROPERTIES PREFIX "")
	endfunction(build_convert_v6)

	build_convert_v6()

	install(TARGETS pmemobj_convert_v6_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	function(build_libpmemobj_17)
		if(MSVC)
			FILE(READ ${VER17}/src/libpmemobj/libpmemobj.def DEFFILE)
			string(REPLACE "libpmemobj" "pmemobj_17" DEFFILE "${DEFFILE}")
			FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_17.def "${DEFFILE}")
			add_library(pmemobj_17 SHARED ${SOURCES_17} ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_17.def)
			target_compile_options(pmemobj_17 PRIVATE /FI"${CMAKE_SOURCE_DIR}/${VER17}/src/windows/include/platform.h")
		else()
			add_library(pmemobj_17 SHARED ${SOURCES_17})
			disable_optimization(pmemobj_17)
		endif()

		target_compile_definitions(pmemobj_17 PRIVATE SRCVERSION="${VER17}")
		target_compile_definitions(pmemobj_17 PRIVATE PMDK_UTF8_API)
		target_compile_definitions(pmemobj_17 PRIVATE _PMEMOBJ_INTRNL)

		target_include_directories(pmemobj_17 PRIVATE ${VER17}/src/include)
		target_include_directories(pmemobj_17 PRIVATE ${VER17}/src/libpmemobj)
		target_include_directories(pmemobj_17 PRIVATE ${VER17}/src/common)
		target_include_directories(pmemobj_17 PRIVATE ${PMEM_INCLUDE_DIRS})

		if(WIN32)
			target_include_directories(pmemobj_17 PRIVATE ${VER17}/src/windows/include/)
			target_include_directories(pmemobj_17 PRIVATE include/)
		endif()

		target_link_libraries(pmemobj_17 PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_17 PRIVATE ${CMAKE_DL_LIBS})
		target_link_libraries(pmemobj_17 PRIVATE ${CMAKE_THREAD_LIBS_INIT})

		if(NOT MSVC)
			FILE(READ ${VER17}/src/libpmemobj/libpmemobj.link.in LINKFILE)
			string(REPLACE "fault_injection;" "" LINKFILE "${LINKFILE}")
			FILE(WRITE ${VER17}/src/libpmemobj/libpmemobj.link "${LINKFILE}")
			target_link_libraries(pmemobj_17 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/${VER17}/src/libpmemobj/libpmemobj.link)
		endif()
	endfunction(build_libpmemobj_17)

	build_libpmemobj_17()

endif(BUILD_CONVERT_V6)

# convert V5 and PMDK 1.6
if(BUILD_CONVERT_V5)
	set(VER16 1.6.1)

	get_pmdk(${VER16} f263c8301f86ddf8bc5e020909ac52350baedba5c169a1a3a7786df64f129446 ${VER16})

	set(SOURCES_16
		${VER16}/src/libpmemobj/alloc_class.c
		${VER16}/src/libpmemobj/bucket.c
		${VER16}/src/libpmemobj/critnib.c
		${VER16}/src/libpmemobj/ctl_debug.c
		${VER16}/src/libpmemobj/container_ravl.c
		${VER16}/src/libpmemobj/container_seglists.c
		${VER16}/src/libpmemobj/heap.c
		${VER16}/src/libpmemobj/lane.c
		${VER16}/src/libpmemobj/libpmemobj.c
		${VER16}/src/libpmemobj/list.c
		${VER16}/src/libpmemobj/memblock.c
		${VER16}/src/libpmemobj/memops.c
		${VER16}/src/libpmemobj/obj.c
		${VER16}/src/libpmemobj/palloc.c
		${VER16}/src/libpmemobj/pmalloc.c
		${VER16}/src/libpmemobj/ravl.c
		${VER16}/src/libpmemobj/recycler.c
		${VER16}/src/libpmemobj/stats.c
		${VER16}/src/libpmemobj/sync.c
		${VER16}/src/libpmemobj/tx.c
		${VER16}/src/libpmemobj/ulog.c

		${VER16}/src/common/alloc.c
		${VER16}/src/common/badblock.c
		${VER16}/src/common/ctl.c
		${VER16}/src/common/ctl_cow.c
		${VER16}/src/common/ctl_fallocate.c
		${VER16}/src/common/ctl_prefault.c
		${VER16}/src/common/ctl_sds.c
		${VER16}/src/common/file.c
		${VER16}/src/common/mmap.c
		${VER16}/src/common/os_dimm_none.c
		${VER16}/src/common/out.c
		${VER16}/src/common/pool_hdr.c
		${VER16}/src/common/set.c
		${VER16}/src/common/shutdown_state.c
		${VER16}/src/common/util.c
		${VER16}/src/common/uuid.c
		)

	if(WIN32)
		set(SOURCES_16 ${SOURCES_16}
			${VER16}/src/libpmemobj/libpmemobj_main.c
			${VER16}/src/common/badblock_none.c
			${VER16}/src/common/file_windows.c
			${VER16}/src/common/fs_windows.c
			${VER16}/src/common/mmap_windows.c
			${VER16}/src/common/os_deep_windows.c
			${VER16}/src/common/os_windows.c
			${VER16}/src/common/os_thread_windows.c
			${VER16}/src/common/util_windows.c
			${VER16}/src/common/uuid_windows.c
			)
	else()
		set(SOURCES_16 ${SOURCES_16}
			${VER16}/src/common/badblock_ndctl.c
			${VER16}/src/common/extent_linux.c
			${VER16}/src/common/file_posix.c
			${VER16}/src/common/fs_posix.c
			${VER16}/src/common/mmap_posix.c
			${VER16}/src/common/os_deep_linux.c
			${VER16}/src/common/os_posix.c
			${VER16}/src/common/os_thread_posix.c
			${VER16}/src/common/util_posix.c
			${VER16}/src/common/uuid_linux.c
			)
	endif()

	function(build_convert_v5)
		if(WIN32)
			set(CONVERT_V5_SOURCES ${VER16}/src/windows/getopt/getopt.c)
		endif()

		add_library(pmemobj_convert_v5_o OBJECT ${SOURCES_16} ${CONVERT_V5_SOURCES}
			pmemobj_convert_v5.c
			${VER16}/src/libpmemblk/btt.c
			${VER16}/src/tools/pmempool/common.c
			${VER16}/src/tools/pmempool/output.c)

		target_compile_definitions(pmemobj_convert_v5_o PRIVATE SRCVERSION="${VER16}")
		target_compile_definitions(pmemobj_convert_v5_o PRIVATE PMDK_UTF8_API)
		target_compile_definitions(pmemobj_convert_v5_o PRIVATE _PMEMOBJ_INTRNL)

		target_include_directories(pmemobj_convert_v5_o PRIVATE ${VER16}/src/include)
		target_include_directories(pmemobj_convert_v5_o PRIVATE ${VER16}/src/libpmemobj)
		target_include_directories(pmemobj_convert_v5_o PRIVATE ${VER16}/src/libpmemlog)
		target_include_directories(pmemobj_convert_v5_o PRIVATE ${VER16}/src/libpmemblk)
		target_include_directories(pmemobj_convert_v5_o PRIVATE ${VER16}/src/common)
		target_include_directories(pmemobj_convert_v5_o PRIVATE ${VER16}/src/tools/pmempool)
		target_include_directories(pmemobj_convert_v5_o PRIVATE ${PMEM_INCLUDE_DIRS})

		if(MSVC)
			target_include_directories(pmemobj_convert_v5_o PRIVATE ${VER16}/src/windows/include/)
			target_include_directories(pmemobj_convert_v5_o PRIVATE ${VER16}/src/windows/getopt/)
			target_include_directories(pmemobj_convert_v5_o PRIVATE include/)
			target_compile_options(pmemobj_convert_v5_o PRIVATE /FI"${CMAKE_SOURCE_DIR}/${VER16}/src/windows/include/platform.h")
		endif()

		if(MSVC)
			add_library(pmemobj_convert_v5_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_v5_o> ${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert_v5.def)
		else()
			add_library(pmemobj_convert_v5_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_v5_o>)
			target_link_libraries(pmemobj_convert_v5_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert.map)
		endif()

		target_link_libraries(pmemobj_convert_v5_shared PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_convert_v5_shared PRIVATE ${CMAKE_DL_LIBS})
		target_link_libraries(pmemobj_convert_v5_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
		if(NOT MSVC)
			# strip unneeded symbols, requires -fdata-sections -ffunction-sections
			target_link_libraries(pmemobj_convert_v5_shared PRIVATE -Wl,--gc-sections)
		endif()

		set_target_properties(pmemobj_convert_v5_shared PROPERTIES OUTPUT_NAME pmemobj_convert_v5)
		# remove lib prefix from library name
		set_target_properties(pmemobj_convert_v5_shared PROPERTIES PREFIX "")
	endfunction(build_convert_v5)

	build_convert_v5()

	install(TARGETS pmemobj_convert_v5_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	function(build_libpmemobj_16)
		if(MSVC)
			FILE(READ ${VER16}/src/libpmemobj/libpmemobj.def DEFFILE)
			string(REPLACE "libpmemobj" "pmemobj_16" DEFFILE "${DEFFILE}")
			FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_16.def "${DEFFILE}")
			add_library(pmemobj_16 SHARED ${SOURCES_16} ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_16.def)
			target_compile_options(pmemobj_16 PRIVATE /FI"${CMAKE_SOURCE_DIR}/${VER16}/src/windows/include/platform.h")
		else()
			add_library(pmemobj_16 SHARED ${SOURCES_16})
			disable_optimization(pmemobj_16)
		endif()

		target_compile_definitions(pmemobj_16 PRIVATE SRCVERSION="${VER16}")
		target_compile_definitions(pmemobj_16 PRIVATE PMDK_UTF8_API)
		target_compile_definitions(pmemobj_16 PRIVATE _PMEMOBJ_INTRNL)

		target_include_directories(pmemobj_16 PRIVATE ${VER16}/src/include)
		target_include_directories(pmemobj_16 PRIVATE ${VER16}/src/libpmemobj)
		target_include_directories(pmemobj_16 PRIVATE ${VER16}/src/common)
		target_include_directories(pmemobj_16 PRIVATE ${PMEM_INCLUDE_DIRS})

		if(WIN32)
			target_include_directories(pmemobj_16 PRIVATE ${VER16}/src/windows/include/)
			target_include_directories(pmemobj_16 PRIVATE include/)
		endif()

		target_link_libraries(pmemobj_16 PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_16 PRIVATE ${CMAKE_DL_LIBS})
		target_link_libraries(pmemobj_16 PRIVATE ${CMAKE_THREAD_LIBS_INIT})

		if(NOT MSVC)
			FILE(READ ${VER16}/src/libpmemobj/libpmemobj.link.in LINKFILE)
			string(REPLACE "fault_injection;" "" LINKFILE "${LINKFILE}")
			FILE(WRITE ${VER16}/src/libpmemobj/libpmemobj.link "${LINKFILE}")
			target_link_libraries(pmemobj_16 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/${VER16}/src/libpmemobj/libpmemobj.link)
		endif()
	endfunction(build_libpmemobj_16)

	build_libpmemobj_16()
endif(BUILD_CONVERT_V5)

###################################################### 1.5
if(BUILD_15)
	set(VER15 1.5.2)

	get_pmdk(${VER15} a72691971a98b8472b26271f19d69e6c9b849c1ca42124ea2e2bd8c3fcdff1b1 ${VER15})

	set(SOURCES_15
		${VER15}/src/libpmemobj/alloc_class.c
		${VER15}/src/libpmemobj/bucket.c
		${VER15}/src/libpmemobj/ctl_debug.c
		${VER15}/src/libpmemobj/container_ravl.c
		${VER15}/src/libpmemobj/container_seglists.c
		${VER15}/src/libpmemobj/cuckoo.c
		${VER15}/src/libpmemobj/heap.c
		${VER15}/src/libpmemobj/lane.c
		${VER15}/src/libpmemobj/libpmemobj.c
		${VER15}/src/libpmemobj/list.c
		${VER15}/src/libpmemobj/memblock.c
		${VER15}/src/libpmemobj/memops.c
		${VER15}/src/libpmemobj/obj.c
		${VER15}/src/libpmemobj/palloc.c
		${VER15}/src/libpmemobj/pmalloc.c
		${VER15}/src/libpmemobj/ravl.c
		${VER15}/src/libpmemobj/recycler.c
		${VER15}/src/libpmemobj/stats.c
		${VER15}/src/libpmemobj/sync.c
		${VER15}/src/libpmemobj/tx.c
		${VER15}/src/libpmemobj/ulog.c

		${VER15}/src/common/badblock.c
		${VER15}/src/common/ctl.c
		${VER15}/src/common/ctl_prefault.c
		${VER15}/src/common/ctl_sds.c
		${VER15}/src/common/file.c
		${VER15}/src/common/mmap.c
		${VER15}/src/common/os_dimm_none.c
		${VER15}/src/common/out.c
		${VER15}/src/common/pool_hdr.c
		${VER15}/src/common/set.c
		${VER15}/src/common/shutdown_state.c
		${VER15}/src/common/util.c
		${VER15}/src/common/uuid.c
		)

	if(WIN32)
		set(SOURCES_15 ${SOURCES_15}
			${VER15}/src/libpmemobj/libpmemobj_main.c
			${VER15}/src/common/badblock_none.c
			${VER15}/src/common/file_windows.c
			${VER15}/src/common/fs_windows.c
			${VER15}/src/common/mmap_windows.c
			${VER15}/src/common/os_deep_windows.c
			${VER15}/src/common/os_windows.c
			${VER15}/src/common/os_thread_windows.c
			${VER15}/src/common/util_windows.c
			${VER15}/src/common/uuid_windows.c
			)
	else()
		set(SOURCES_15 ${SOURCES_15}
			${VER15}/src/common/badblock_ndctl.c
			${VER15}/src/common/extent_linux.c
			${VER15}/src/common/file_posix.c
			${VER15}/src/common/fs_posix.c
			${VER15}/src/common/mmap_posix.c
			${VER15}/src/common/os_deep_linux.c
			${VER15}/src/common/os_posix.c
			${VER15}/src/common/os_thread_posix.c
			${VER15}/src/common/util_posix.c
			${VER15}/src/common/uuid_linux.c
			)
	endif()

	function(build_libpmemobj_15)
		if(MSVC)
			FILE(READ ${VER15}/src/libpmemobj/libpmemobj.def DEFFILE)
			string(REPLACE "libpmemobj" "pmemobj_15" DEFFILE "${DEFFILE}")
			FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_15.def "${DEFFILE}")
			add_library(pmemobj_15 SHARED ${SOURCES_15} ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_15.def)
			target_compile_options(pmemobj_15 PRIVATE /FI"${CMAKE_SOURCE_DIR}/${VER15}/src/windows/include/platform.h")
		else()
			add_library(pmemobj_15 SHARED ${SOURCES_15})
			disable_optimization(pmemobj_15)
		endif()

		target_compile_definitions(pmemobj_15 PRIVATE SRCVERSION="${VER15}")
		target_compile_definitions(pmemobj_15 PRIVATE PMDK_UTF8_API)
		target_compile_definitions(pmemobj_15 PRIVATE _PMEMOBJ_INTRNL)

		target_include_directories(pmemobj_15 PRIVATE ${VER15}/src/include)
		target_include_directories(pmemobj_15 PRIVATE ${VER15}/src/libpmemobj)
		target_include_directories(pmemobj_15 PRIVATE ${VER15}/src/common)
		target_include_directories(pmemobj_15 PRIVATE ${PMEM_INCLUDE_DIRS})

		if(WIN32)
			target_include_directories(pmemobj_15 PRIVATE ${VER15}/src/windows/include/)
			target_include_directories(pmemobj_15 PRIVATE include/)
		endif()

		target_link_libraries(pmemobj_15 PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_15 PRIVATE ${CMAKE_DL_LIBS})
		target_link_libraries(pmemobj_15 PRIVATE ${CMAKE_THREAD_LIBS_INIT})

		if(NOT MSVC)
			target_link_libraries(pmemobj_15 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/${VER15}/src/libpmemobj/libpmemobj.map)
		endif()
	endfunction(build_libpmemobj_15)

	build_libpmemobj_15()
endif()

###################################################### 1.4
if(BUILD_CONVERT_V4)

	set(VER14 1.4.3)

	get_pmdk(${VER14} 93a8ba7383fa02dfd176d50aff56ace6bbac86bbaf26b8b1949ee703a4ec3a31 ${VER14})

	set(SOURCES_14
		${VER14}/src/libpmemobj/alloc_class.c
		${VER14}/src/libpmemobj/bucket.c
		${VER14}/src/libpmemobj/container_ravl.c
		${VER14}/src/libpmemobj/container_seglists.c
		${VER14}/src/libpmemobj/ctl.c
		${VER14}/src/libpmemobj/ctl_global.c
		${VER14}/src/libpmemobj/cuckoo.c
		${VER14}/src/libpmemobj/heap.c
		${VER14}/src/libpmemobj/lane.c
		${VER14}/src/libpmemobj/libpmemobj.c
		${VER14}/src/libpmemobj/list.c
		${VER14}/src/libpmemobj/memblock.c
		${VER14}/src/libpmemobj/memops.c
		${VER14}/src/libpmemobj/obj.c
		${VER14}/src/libpmemobj/palloc.c
		${VER14}/src/libpmemobj/pmalloc.c
		${VER14}/src/libpmemobj/pvector.c
		${VER14}/src/libpmemobj/ravl.c
		${VER14}/src/libpmemobj/recycler.c
		${VER14}/src/libpmemobj/redo.c
		${VER14}/src/libpmemobj/ringbuf.c
		${VER14}/src/libpmemobj/stats.c
		${VER14}/src/libpmemobj/sync.c
		${VER14}/src/libpmemobj/tx.c

		${VER14}/src/common/file.c
		${VER14}/src/common/mmap.c
		${VER14}/src/common/os_dimm_none.c
		${VER14}/src/common/out.c
		${VER14}/src/common/pool_hdr.c
		${VER14}/src/common/set.c
		${VER14}/src/common/shutdown_state.c
		${VER14}/src/common/util.c
		${VER14}/src/common/uuid.c
		)

	if(WIN32)
		set(SOURCES_14 ${SOURCES_14}
			${VER14}/src/libpmemobj/libpmemobj_main.c
			${VER14}/src/common/file_windows.c
			${VER14}/src/common/fs_windows.c
			${VER14}/src/common/mmap_windows.c
			${VER14}/src/common/os_deep_windows.c
			${VER14}/src/common/os_windows.c
			${VER14}/src/common/os_thread_windows.c
			${VER14}/src/common/util_windows.c
			${VER14}/src/common/uuid_windows.c
			)
	else()
		set(SOURCES_14 ${SOURCES_14}
			${VER14}/src/common/file_posix.c
			${VER14}/src/common/fs_posix.c
			${VER14}/src/common/mmap_posix.c
			${VER14}/src/common/os_deep_linux.c
			${VER14}/src/common/os_posix.c
			${VER14}/src/common/os_thread_posix.c
			${VER14}/src/common/util_posix.c
			${VER14}/src/common/uuid_linux.c
			)
	endif()


	if(WIN32)
		set(CONVERT_V4_SOURCES ${VER14}/src/windows/getopt/getopt.c)
	endif()

	function(build_convert_v4)
		add_library(pmemobj_convert_v4_o OBJECT ${SOURCES_14} ${CONVERT_V4_SOURCES}
			pmemobj_convert_v4.c
			${VER14}/src/libpmemblk/btt.c
			${VER14}/src/tools/pmempool/common.c
			${VER14}/src/tools/pmempool/output.c)

		target_compile_definitions(pmemobj_convert_v4_o PRIVATE SRCVERSION="${VER14}")
		target_compile_definitions(pmemobj_convert_v4_o PRIVATE PMDK_UTF8_API)
		target_compile_definitions(pmemobj_convert_v4_o PRIVATE _PMEMOBJ_INTRNL)

		target_include_directories(pmemobj_convert_v4_o PRIVATE ${VER14}/src/include)
		target_include_directories(pmemobj_convert_v4_o PRIVATE ${VER14}/src/libpmemobj)
		target_include_directories(pmemobj_convert_v4_o PRIVATE ${VER14}/src/libpmemlog)
		target_include_directories(pmemobj_convert_v4_o PRIVATE ${VER14}/src/libpmemblk)
		target_include_directories(pmemobj_convert_v4_o PRIVATE ${VER14}/src/libpmemcto)
		target_include_directories(pmemobj_convert_v4_o PRIVATE ${VER14}/src/common)
		target_include_directories(pmemobj_convert_v4_o PRIVATE ${VER14}/src/tools/pmempool)
		target_include_directories(pmemobj_convert_v4_o PRIVATE ${PMEM_INCLUDE_DIRS})

		if(MSVC)
			target_include_directories(pmemobj_convert_v4_o PRIVATE ${VER14}/src/windows/include/)
			target_include_directories(pmemobj_convert_v4_o PRIVATE ${VER14}/src/windows/getopt/)
			target_include_directories(pmemobj_convert_v4_o PRIVATE include/)
			target_compile_options(pmemobj_convert_v4_o PRIVATE /FI"${CMAKE_SOURCE_DIR}/${VER14}/src/windows/include/platform.h")
		endif()

		if(MSVC)
			add_library(pmemobj_convert_v4_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_v4_o> ${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert_v4.def)
		else()
			add_library(pmemobj_convert_v4_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_v4_o>)
			target_link_libraries(pmemobj_convert_v4_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert.map)
		endif()

		target_link_libraries(pmemobj_convert_v4_shared PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_convert_v4_shared PRIVATE ${CMAKE_DL_LIBS})
		target_link_libraries(pmemobj_convert_v4_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
		if(NOT MSVC)
			# strip unneeded symbols, requires -fdata-sections -ffunction-sections
			target_link_libraries(pmemobj_convert_v4_shared PRIVATE -Wl,--gc-sections)
		endif()

		set_target_properties(pmemobj_convert_v4_shared PROPERTIES OUTPUT_NAME pmemobj_convert_v4)
		# remove lib prefix from library name
		set_target_properties(pmemobj_convert_v4_shared PROPERTIES PREFIX "")
	endfunction(build_convert_v4)

	build_convert_v4()

	install(TARGETS pmemobj_convert_v4_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	function(build_libpmemobj_14)
		if(MSVC)
			FILE(READ ${VER14}/src/libpmemobj/libpmemobj.def DEFFILE)
			string(REPLACE "libpmemobj" "pmemobj_14" DEFFILE "${DEFFILE}")
			FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_14.def "${DEFFILE}")
			add_library(pmemobj_14 SHARED ${SOURCES_14} ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_14.def)
			target_compile_options(pmemobj_14 PRIVATE /FI"${CMAKE_SOURCE_DIR}/${VER14}/src/windows/include/platform.h")
		else()
			add_library(pmemobj_14 SHARED ${SOURCES_14})
			disable_optimization(pmemobj_14)
		endif()

		target_compile_definitions(pmemobj_14 PRIVATE SRCVERSION="${VER14}")
		target_compile_definitions(pmemobj_14 PRIVATE PMDK_UTF8_API)
		target_compile_definitions(pmemobj_14 PRIVATE _PMEMOBJ_INTRNL)

		target_include_directories(pmemobj_14 PRIVATE ${VER14}/src/include)
		target_include_directories(pmemobj_14 PRIVATE ${VER14}/src/libpmemobj)
		target_include_directories(pmemobj_14 PRIVATE ${VER14}/src/common)
		target_include_directories(pmemobj_14 PRIVATE ${PMEM_INCLUDE_DIRS})

		if(WIN32)
			target_include_directories(pmemobj_14 PRIVATE ${VER14}/src/windows/include/)
			target_include_directories(pmemobj_14 PRIVATE include/)
		endif()

		target_link_libraries(pmemobj_14 PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_14 PRIVATE ${CMAKE_DL_LIBS})
		target_link_libraries(pmemobj_14 PRIVATE ${CMAKE_THREAD_LIBS_INIT})

		if(NOT MSVC)
			target_link_libraries(pmemobj_14 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/${VER14}/src/libpmemobj/libpmemobj.map)
		endif()
	endfunction(build_libpmemobj_14)

	build_libpmemobj_14()
endif(BUILD_CONVERT_V4)

###################################################### 1.3 (tests only)
if(BUILD_13)

	set(VER13 1.3.3)

	get_pmdk(${VER13} 5d46497bb151e6a36e801aed45bfef0d068c55cb2267329053e7489e01742f47 ${VER13})

	set(SOURCES_13
		${VER13}/src/libpmemobj/alloc_class.c
		${VER13}/src/libpmemobj/bucket.c
		${VER13}/src/libpmemobj/container_ctree.c
		${VER13}/src/libpmemobj/container_seglists.c
		${VER13}/src/libpmemobj/ctl.c
		${VER13}/src/libpmemobj/ctl_global.c
		${VER13}/src/libpmemobj/ctree.c
		${VER13}/src/libpmemobj/cuckoo.c
		${VER13}/src/libpmemobj/heap.c
		${VER13}/src/libpmemobj/lane.c
		${VER13}/src/libpmemobj/libpmemobj.c
		${VER13}/src/libpmemobj/list.c
		${VER13}/src/libpmemobj/memblock.c
		${VER13}/src/libpmemobj/memops.c
		${VER13}/src/libpmemobj/obj.c
		${VER13}/src/libpmemobj/palloc.c
		${VER13}/src/libpmemobj/pmalloc.c
		${VER13}/src/libpmemobj/pvector.c
		${VER13}/src/libpmemobj/recycler.c
		${VER13}/src/libpmemobj/redo.c
		${VER13}/src/libpmemobj/ringbuf.c
		${VER13}/src/libpmemobj/sync.c
		${VER13}/src/libpmemobj/tx.c

		${VER13}/src/common/file.c
		${VER13}/src/common/mmap.c
		${VER13}/src/common/out.c
		${VER13}/src/common/pool_hdr.c
		${VER13}/src/common/set.c
		${VER13}/src/common/util.c
		${VER13}/src/common/uuid.c
		)

	if(WIN32)
		set(SOURCES_13 ${SOURCES_13}
			${VER13}/src/libpmemobj/libpmemobj_main.c
			${VER13}/src/common/file_windows.c
			${VER13}/src/common/mmap_windows.c
			${VER13}/src/common/os_windows.c
			${VER13}/src/common/os_thread_windows.c
			${VER13}/src/common/pool_hdr_windows.c
			${VER13}/src/common/util_windows.c
			${VER13}/src/common/uuid_windows.c
			)
	else()
		set(SOURCES_13 ${SOURCES_13}
			${VER13}/src/common/file_linux.c
			${VER13}/src/common/mmap_linux.c
			${VER13}/src/common/os_linux.c
			${VER13}/src/common/os_thread_linux.c
			${VER13}/src/common/pool_hdr_linux.c
			${VER13}/src/common/util_linux.c
			${VER13}/src/common/uuid_linux.c
			)
	endif()

	function(build_libpmemobj_13)
		if(MSVC)
			FILE(READ ${VER13}/src/libpmemobj/libpmemobj.def DEFFILE)
			string(REPLACE "libpmemobj" "pmemobj_13" DEFFILE "${DEFFILE}")
			FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_13.def "${DEFFILE}")
			add_library(pmemobj_13 SHARED ${SOURCES_13} ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_13.def ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_13.def)
			target_compile_options(pmemobj_13 PRIVATE /FI"${CMAKE_SOURCE_DIR}/${VER13}/src/windows/include/platform.h")
		else()
			add_library(pmemobj_13 SHARED ${SOURCES_13})
			disable_optimization(pmemobj_13)
		endif()

		target_compile_definitions(pmemobj_13 PRIVATE SRCVERSION="${VER13}")
		target_compile_definitions(pmemobj_13 PRIVATE NVML_UTF8_API)
		target_compile_definitions(pmemobj_13 PRIVATE _PMEMOBJ_INTRNL)

		target_include_directories(pmemobj_13 PRIVATE ${VER13}/src/include)
		target_include_directories(pmemobj_13 PRIVATE ${VER13}/src/libpmemobj)
		target_include_directories(pmemobj_13 PRIVATE ${VER13}/src/common)
		target_include_directories(pmemobj_13 PRIVATE ${PMEM_INCLUDE_DIRS})

		if(WIN32)
			target_include_directories(pmemobj_13 PRIVATE ${VER13}/src/windows/include/)
			target_include_directories(pmemobj_13 PRIVATE include/)
		endif()

		target_link_libraries(pmemobj_13 PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_13 PRIVATE ${CMAKE_DL_LIBS})
		target_link_libraries(pmemobj_13 PRIVATE ${CMAKE_THREAD_LIBS_INIT})

		if(NOT MSVC)
			target_link_libraries(pmemobj_13 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/${VER13}/src/libpmemobj/libpmemobj.map)
		endif()
	endfunction(build_libpmemobj_13)

	build_libpmemobj_13()
endif(BUILD_13)

###################################################### 1.2

if(BUILD_CONVERT_V3)

	set(VER12 1.2.4)

	get_pmdk(${VER12} aa57b4d969a7582ad5897b5e979b3f2a4015ace7777388227826a65dbf626edd ${VER12})

	set(SOURCES_12
		${VER12}/src/libpmemobj/bucket.c
		${VER12}/src/libpmemobj/ctree.c
		${VER12}/src/libpmemobj/cuckoo.c
		${VER12}/src/libpmemobj/heap.c
		${VER12}/src/libpmemobj/lane.c
		${VER12}/src/libpmemobj/libpmemobj.c
		${VER12}/src/libpmemobj/list.c
		${VER12}/src/libpmemobj/memblock.c
		${VER12}/src/libpmemobj/memops.c
		${VER12}/src/libpmemobj/obj.c
		${VER12}/src/libpmemobj/palloc.c
		${VER12}/src/libpmemobj/pmalloc.c
		${VER12}/src/libpmemobj/pvector.c
		${VER12}/src/libpmemobj/redo.c
		${VER12}/src/libpmemobj/sync.c
		${VER12}/src/libpmemobj/tx.c

		${VER12}/src/common/file.c
		${VER12}/src/common/file_linux.c
		${VER12}/src/common/mmap.c
		${VER12}/src/common/mmap_linux.c
		${VER12}/src/common/out.c
		${VER12}/src/common/pool_hdr.c
		${VER12}/src/common/pool_hdr_linux.c
		${VER12}/src/common/set.c
		${VER12}/src/common/util.c
		${VER12}/src/common/uuid.c
		${VER12}/src/common/uuid_linux.c
		${VER12}/src/common/util_linux.c
		)

	if(WIN32)
		set(SOURCES_12 ${SOURCES_12} ${VER12}/src/libpmemobj/libpmemobj_main.c)
	endif()

	function(build_convert_v3)
		add_library(pmemobj_convert_v3_o OBJECT ${SOURCES_12}
			pmemobj_convert_v3.c
			${VER12}/src/libpmemblk/btt.c
			${VER12}/src/tools/pmempool/common.c)

		target_compile_definitions(pmemobj_convert_v3_o PRIVATE SRCVERSION="${VER12}")
		target_include_directories(pmemobj_convert_v3_o PRIVATE ${VER12}/src/include)
		target_include_directories(pmemobj_convert_v3_o PRIVATE ${VER12}/src/libpmemobj)
		target_include_directories(pmemobj_convert_v3_o PRIVATE ${VER12}/src/libpmemlog)
		target_include_directories(pmemobj_convert_v3_o PRIVATE ${VER12}/src/libpmemblk)
		target_include_directories(pmemobj_convert_v3_o PRIVATE ${VER12}/src/common)
		target_include_directories(pmemobj_convert_v3_o PRIVATE ${VER12}/src/tools/pmempool)
		target_include_directories(pmemobj_convert_v3_o PRIVATE ${PMEM_INCLUDE_DIRS})

		add_library(pmemobj_convert_v3_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_v3_o>)
		target_link_libraries(pmemobj_convert_v3_shared PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_convert_v3_shared PRIVATE ${CMAKE_DL_LIBS})
		target_link_libraries(pmemobj_convert_v3_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
		target_link_libraries(pmemobj_convert_v3_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert.map)
		# strip unneeded symbols, requires -fdata-sections -ffunction-sections
		target_link_libraries(pmemobj_convert_v3_shared PRIVATE -Wl,--gc-sections)

		set_target_properties(pmemobj_convert_v3_shared PROPERTIES OUTPUT_NAME pmemobj_convert_v3)
		set_target_properties(pmemobj_convert_v3_shared PROPERTIES PREFIX "")
	endfunction(build_convert_v3)

	build_convert_v3()

	install(TARGETS pmemobj_convert_v3_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	function(build_libpmemobj_12)
		add_library(pmemobj_12 SHARED ${SOURCES_12})
		disable_optimization(pmemobj_12)
		target_compile_definitions(pmemobj_12 PRIVATE SRCVERSION="${VER12}")
		target_include_directories(pmemobj_12 PRIVATE ${VER12}/src/include)
		target_include_directories(pmemobj_12 PRIVATE ${VER12}/src/libpmemobj)
		target_include_directories(pmemobj_12 PRIVATE ${VER12}/src/common)
		target_include_directories(pmemobj_12 PRIVATE ${PMEM_INCLUDE_DIRS})
		target_link_libraries(pmemobj_12 PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_12 PRIVATE ${CMAKE_DL_LIBS})
		target_link_libraries(pmemobj_12 PRIVATE ${CMAKE_THREAD_LIBS_INIT})
		target_link_libraries(pmemobj_12 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/${VER12}/src/libpmemobj/libpmemobj.map)
	endfunction(build_libpmemobj_12)

	build_libpmemobj_12()
endif(BUILD_CONVERT_V3)

###################################################### 1.1

if(BUILD_CONVERT_V2)

	set(VER11 1.1)

	get_pmdk(${VER11} 2d51a356bf0bd61b0259844894223305d5d825af68d51a07aa1d2bc926b65c43 ${VER11})

	set(SOURCES_11
		${VER11}/src/libpmemobj/bucket.c
		${VER11}/src/libpmemobj/ctree.c
		${VER11}/src/libpmemobj/cuckoo.c
		${VER11}/src/libpmemobj/heap.c
		${VER11}/src/libpmemobj/lane.c
		${VER11}/src/libpmemobj/libpmemobj.c
		${VER11}/src/libpmemobj/list.c
		${VER11}/src/libpmemobj/memblock.c
		${VER11}/src/libpmemobj/memops.c
		${VER11}/src/libpmemobj/obj.c
		${VER11}/src/libpmemobj/pmalloc.c
		${VER11}/src/libpmemobj/pvector.c
		${VER11}/src/libpmemobj/redo.c
		${VER11}/src/libpmemobj/sync.c
		${VER11}/src/libpmemobj/tx.c

		${VER11}/src/common/out.c
		${VER11}/src/common/set.c
		${VER11}/src/common/set_linux.c
		${VER11}/src/common/util.c
		${VER11}/src/common/util_linux.c
		)

	if(WIN32)
		set(SOURCES_11 ${SOURCES_11} ${VER11}/src/libpmemobj/libpmemobj_main.c)
	endif()

	function(build_convert_v2)
		add_library(pmemobj_convert_v2_o OBJECT ${SOURCES_11}
			pmemobj_convert_v2.c
			${VER11}/src/libpmemblk/btt.c
			${VER11}/src/tools/pmempool/common.c
			)

		target_compile_definitions(pmemobj_convert_v2_o PRIVATE SRCVERSION="${VER11}")

		target_include_directories(pmemobj_convert_v2_o PRIVATE ${VER11}/src/include)
		target_include_directories(pmemobj_convert_v2_o PRIVATE ${VER11}/src/libpmemobj)
		target_include_directories(pmemobj_convert_v2_o PRIVATE ${VER11}/src/libpmemlog)
		target_include_directories(pmemobj_convert_v2_o PRIVATE ${VER11}/src/libpmemblk)
		target_include_directories(pmemobj_convert_v2_o PRIVATE ${VER11}/src/common)
		target_include_directories(pmemobj_convert_v2_o PRIVATE ${VER11}/src/tools/pmempool)
		target_include_directories(pmemobj_convert_v2_o PRIVATE ${PMEM_INCLUDE_DIRS})

		add_library(pmemobj_convert_v2_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_v2_o>)
		target_link_libraries(pmemobj_convert_v2_shared PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_convert_v2_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
		target_link_libraries(pmemobj_convert_v2_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert.map)
		# strip unneeded symbols, requires -fdata-sections -ffunction-sections
		target_link_libraries(pmemobj_convert_v2_shared PRIVATE -Wl,--gc-sections)

		set_target_properties(pmemobj_convert_v2_shared PROPERTIES OUTPUT_NAME pmemobj_convert_v2)
		set_target_properties(pmemobj_convert_v2_shared PROPERTIES PREFIX "")
	endfunction(build_convert_v2)

	build_convert_v2()

	install(TARGETS pmemobj_convert_v2_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	function(build_libpmemobj_11)
		add_library(pmemobj_11 SHARED ${SOURCES_11})
		disable_optimization(pmemobj_11)
		target_compile_definitions(pmemobj_11 PRIVATE SRCVERSION="${VER11}")

		target_include_directories(pmemobj_11 PRIVATE ${VER11}/src/include)
		target_include_directories(pmemobj_11 PRIVATE ${VER11}/src/libpmemobj)
		target_include_directories(pmemobj_11 PRIVATE ${VER11}/src/common)
		target_include_directories(pmemobj_11 PRIVATE ${PMEM_INCLUDE_DIRS})

		target_link_libraries(pmemobj_11 PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_11 PRIVATE ${CMAKE_THREAD_LIBS_INIT})
		target_link_libraries(pmemobj_11 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/${VER11}/src/libpmemobj/libpmemobj.map)
	endfunction(build_libpmemobj_11)

	build_libpmemobj_11()
endif(BUILD_CONVERT_V2)

###################################################### 1.0

if(BUILD_CONVERT_V1)

	set(VER10 1.0)

	get_pmdk(${VER10} e9c9ed72168047f65fae72808933bfeafd965ed3237ab3fbfb199c362bf5b773 ${VER10})

	set(SOURCES_10
		${VER10}/src/libpmemobj/bucket.c
		${VER10}/src/libpmemobj/ctree.c
		${VER10}/src/libpmemobj/cuckoo.c
		${VER10}/src/libpmemobj/heap.c
		${VER10}/src/libpmemobj/lane.c
		${VER10}/src/libpmemobj/libpmemobj.c
		${VER10}/src/libpmemobj/list.c
		${VER10}/src/libpmemobj/memops.c
		${VER10}/src/libpmemobj/obj.c
		${VER10}/src/libpmemobj/pmalloc.c
		${VER10}/src/libpmemobj/redo.c
		${VER10}/src/libpmemobj/sync.c
		${VER10}/src/libpmemobj/tx.c

		${VER10}/src/common/out.c
		${VER10}/src/common/set.c
		${VER10}/src/common/util.c
		)

	function(build_convert_v1)
		add_library(pmemobj_convert_v1_o OBJECT ${SOURCES_10}
			pmemobj_convert_v1.c
			${VER10}/src/tools/pmempool/common.c)

		target_compile_definitions(pmemobj_convert_v1_o PRIVATE SRCVERSION="${VER10}")

		target_include_directories(pmemobj_convert_v1_o PRIVATE ${VER10}/src/include)
		target_include_directories(pmemobj_convert_v1_o PRIVATE ${VER10}/src/libpmemobj)
		target_include_directories(pmemobj_convert_v1_o PRIVATE ${VER10}/src/libpmemlog)
		target_include_directories(pmemobj_convert_v1_o PRIVATE ${VER10}/src/libpmemblk)
		target_include_directories(pmemobj_convert_v1_o PRIVATE ${VER10}/src/common)
		target_include_directories(pmemobj_convert_v1_o PRIVATE ${VER10}/src/tools/pmempool)
		target_include_directories(pmemobj_convert_v1_o PRIVATE ${PMEM_INCLUDE_DIRS})

		add_library(pmemobj_convert_v1_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_v1_o>)
		target_link_libraries(pmemobj_convert_v1_shared PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_convert_v1_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
		target_link_libraries(pmemobj_convert_v1_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert.map)
		# strip unneeded symbols, requires -fdata-sections -ffunction-sections
		target_link_libraries(pmemobj_convert_v1_shared PRIVATE -Wl,--gc-sections)

		set_target_properties(pmemobj_convert_v1_shared PROPERTIES OUTPUT_NAME pmemobj_convert_v1)
		set_target_properties(pmemobj_convert_v1_shared PROPERTIES PREFIX "")
	endfunction(build_convert_v1)

	build_convert_v1()

	install(TARGETS pmemobj_convert_v1_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	function(build_libpmemobj_10)
		add_library(pmemobj_10 SHARED ${SOURCES_10})
		disable_optimization(pmemobj_10)
		target_compile_definitions(pmemobj_10 PRIVATE SRCVERSION="${VER10}")

		target_include_directories(pmemobj_10 PRIVATE ${VER10}/src/include)
		target_include_directories(pmemobj_10 PRIVATE ${VER10}/src/libpmemobj)
		target_include_directories(pmemobj_10 PRIVATE ${VER10}/src/common)
		target_include_directories(pmemobj_10 PRIVATE ${PMEM_INCLUDE_DIRS})
		target_link_libraries(pmemobj_10 PRIVATE libpmem-convert)
		target_link_libraries(pmemobj_10 PRIVATE ${CMAKE_THREAD_LIBS_INIT})
		target_link_libraries(pmemobj_10 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/${VER10}/src/libpmemobj/libpmemobj.map)
	endfunction(build_libpmemobj_10)

	build_libpmemobj_10()

endif(BUILD_CONVERT_V1)

###################################################### everything else
function(build_pmdk_convert)
	if (WIN32)
		add_executable(pmdk-convert pmdk-convert.c ${MAX_STABLE}/src/windows/getopt/getopt.c)
		target_include_directories(pmdk-convert PRIVATE ${MAX_STABLE}/src/windows/getopt/)
		target_include_directories(pmdk-convert PRIVATE ${MAX_STABLE}/src/windows/include/)
	else()
		add_executable(pmdk-convert pmdk-convert.c)
	endif()

	target_compile_definitions(pmdk-convert PRIVATE LIBDIR="${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
	target_compile_definitions(pmdk-convert PRIVATE MIN_VERSION_MAJOR=${MIN_VERSION_MAJOR})
	target_compile_definitions(pmdk-convert PRIVATE MIN_VERSION_MINOR=${MIN_VERSION_MINOR})
	target_compile_definitions(pmdk-convert PRIVATE MAX_VERSION_MAJOR=${MAX_VERSION_MAJOR})
	target_compile_definitions(pmdk-convert PRIVATE MAX_VERSION_MINOR=${MAX_VERSION_MINOR})
	target_compile_definitions(pmdk-convert PRIVATE VERSION_MAJOR=${VERSION_MAJOR})
	target_compile_definitions(pmdk-convert PRIVATE VERSION_MINOR=${VERSION_MINOR})
	target_compile_definitions(pmdk-convert PRIVATE VERSION_PATCH=${VERSION_PATCH})
	target_compile_definitions(pmdk-convert PRIVATE VERSION_PRERELEASE="${VERSION_PRERELEASE}")
	target_link_libraries(pmdk-convert PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmdk-convert PRIVATE ${CMAKE_THREAD_LIBS_INIT})
endfunction()

build_pmdk_convert()

install(TARGETS pmdk-convert
	DESTINATION ${CMAKE_INSTALL_BINDIR}
	PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

option(TRACE_TESTS
	"more verbose test outputs" OFF)
enable_testing()
add_subdirectory(tests)

if(NOT "${CPACK_GENERATOR}" STREQUAL "")
	include(${CMAKE_SOURCE_DIR}/packages.cmake)
endif()
