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
set(VERSION_MINOR 6)
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

set(MAX_VERSION 1.6)
set(MAX_STABLE nvml-1.6)

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
elseif (${MIN_VERSION} EQUAL 1.3)
	set(BUILD_13 1)
	set(BUILD_CONVERT_V4 1)
	set(BUILD_CONVERT_V5 1)
	set(BUILD_15 1)
elseif (${MIN_VERSION} EQUAL 1.4)
	set(BUILD_CONVERT_V4 1)
	set(BUILD_CONVERT_V5 1)
	set(BUILD_15 1)
elseif (${MIN_VERSION} EQUAL 1.5)
	set(BUILD_CONVERT_V5 1)
	set(BUILD_15 1)
elseif (${MIN_VERSION} EQUAL 1.6)
	set(BUILD_CONVERT_V5 1)
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
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${ver}.tar.gz ${CMAKE_SOURCE_DIR}/${ver}.tar.gz
			EXPECTED_HASH SHA256=${hash})
		message(STATUS "Downloading ${ver}.tar.gz DONE")
	endif()

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${dstdir})
		message(STATUS "Uncompressing ${ver}.tar.gz")
		uncompress(${ver}.tar.gz)
		message(STATUS "Uncompressing ${ver}.tar.gz DONE")

		file(RENAME ${CMAKE_SOURCE_DIR}/pmdk-${ver} ${CMAKE_SOURCE_DIR}/${dstdir})
	endif()
endfunction()

# convert V5 and PMDK 1.6
if(BUILD_CONVERT_V5)
	set(NVML16 1.6)

	# This hash commit comes from PMDK stable-1.6 branch after pmemobj_next recursion fix.
	# An actual hash commit has a stable SHA256 - this is why we cannot just download stable-1.6.
	# XXX: This needs to be changed to 1.6.1 after PMDK 1.6.1 release.
	get_pmdk(cf5d532da36893334b7ec8db0a2b296151733d0e 16e7f672d8944ad853261b8f90a7d8e807ab2109d058b517775af2f19b1e859f nvml-1.6)

######################################### libpmem
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
	target_compile_definitions(libpmem-convert PRIVATE SRCVERSION="${NVML16}")
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
	set(PMEM_INCLUDE_DIRS ${MAX_STABLE}/src/include)
	set(PMEM_LIBRARIES libpmem-convert)
	install(TARGETS libpmem-convert
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

######################################### libpmem end

	set(SOURCES_16
		nvml-1.6/src/libpmemobj/alloc_class.c
		nvml-1.6/src/libpmemobj/bucket.c
		nvml-1.6/src/libpmemobj/critnib.c
		nvml-1.6/src/libpmemobj/ctl_debug.c
		nvml-1.6/src/libpmemobj/container_ravl.c
		nvml-1.6/src/libpmemobj/container_seglists.c
		nvml-1.6/src/libpmemobj/heap.c
		nvml-1.6/src/libpmemobj/lane.c
		nvml-1.6/src/libpmemobj/libpmemobj.c
		nvml-1.6/src/libpmemobj/list.c
		nvml-1.6/src/libpmemobj/memblock.c
		nvml-1.6/src/libpmemobj/memops.c
		nvml-1.6/src/libpmemobj/obj.c
		nvml-1.6/src/libpmemobj/palloc.c
		nvml-1.6/src/libpmemobj/pmalloc.c
		nvml-1.6/src/libpmemobj/ravl.c
		nvml-1.6/src/libpmemobj/recycler.c
		nvml-1.6/src/libpmemobj/stats.c
		nvml-1.6/src/libpmemobj/sync.c
		nvml-1.6/src/libpmemobj/tx.c
		nvml-1.6/src/libpmemobj/ulog.c

		nvml-1.6/src/common/alloc.c
		nvml-1.6/src/common/badblock.c
		nvml-1.6/src/common/ctl.c
		nvml-1.6/src/common/ctl_cow.c
		nvml-1.6/src/common/ctl_fallocate.c
		nvml-1.6/src/common/ctl_prefault.c
		nvml-1.6/src/common/ctl_sds.c
		nvml-1.6/src/common/file.c
		nvml-1.6/src/common/mmap.c
		nvml-1.6/src/common/os_dimm_none.c
		nvml-1.6/src/common/out.c
		nvml-1.6/src/common/pool_hdr.c
		nvml-1.6/src/common/set.c
		nvml-1.6/src/common/shutdown_state.c
		nvml-1.6/src/common/util.c
		nvml-1.6/src/common/uuid.c
		)

	if(WIN32)
		set(SOURCES_16 ${SOURCES_16}
			nvml-1.6/src/libpmemobj/libpmemobj_main.c
			nvml-1.6/src/common/badblock_none.c
			nvml-1.6/src/common/file_windows.c
			nvml-1.6/src/common/fs_windows.c
			nvml-1.6/src/common/mmap_windows.c
			nvml-1.6/src/common/os_deep_windows.c
			nvml-1.6/src/common/os_windows.c
			nvml-1.6/src/common/os_thread_windows.c
			nvml-1.6/src/common/util_windows.c
			nvml-1.6/src/common/uuid_windows.c
			)
	else()
		set(SOURCES_16 ${SOURCES_16}
			nvml-1.6/src/common/badblock_ndctl.c
			nvml-1.6/src/common/extent_linux.c
			nvml-1.6/src/common/file_posix.c
			nvml-1.6/src/common/fs_posix.c
			nvml-1.6/src/common/mmap_posix.c
			nvml-1.6/src/common/os_deep_linux.c
			nvml-1.6/src/common/os_posix.c
			nvml-1.6/src/common/os_thread_posix.c
			nvml-1.6/src/common/util_posix.c
			nvml-1.6/src/common/uuid_linux.c
			)
	endif()

################################### convert V5 (pmdk 1.6)
	if(WIN32)
		set(CONVERT_V5_SOURCES nvml-1.6/src/windows/getopt/getopt.c)
	endif()

	add_library(pmemobj_convert_v5_o OBJECT ${SOURCES_16} ${CONVERT_V5_SOURCES}
		pmemobj_convert_v5.c
		nvml-1.6/src/libpmemblk/btt.c
		nvml-1.6/src/tools/pmempool/common.c
		nvml-1.6/src/tools/pmempool/output.c)

	target_compile_definitions(pmemobj_convert_v5_o PRIVATE SRCVERSION="${NVML16}")
	target_compile_definitions(pmemobj_convert_v5_o PRIVATE PMDK_UTF8_API)
	target_compile_definitions(pmemobj_convert_v5_o PRIVATE _PMEMOBJ_INTRNL)

	target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.6/src/include)
	target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.6/src/libpmemobj)
	target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.6/src/libpmemlog)
	target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.6/src/libpmemblk)
	target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.6/src/common)
	target_include_directories(pmemobj_convert_v5_o PRIVATE ${PMEM_INCLUDE_DIRS})

	if(MSVC)
		target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.6/src/windows/include/)
		target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.6/src/windows/getopt/)
		target_include_directories(pmemobj_convert_v5_o PRIVATE include/)
		target_compile_options(pmemobj_convert_v5_o PRIVATE /FI"${CMAKE_SOURCE_DIR}/nvml-1.6/src/windows/include/platform.h")
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

	install(TARGETS pmemobj_convert_v5_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)
#################################### convert V5 end

	if(MSVC)
		FILE(READ nvml-1.6/src/libpmemobj/libpmemobj.def DEFFILE)
		string(REPLACE "libpmemobj" "pmemobj_16" DEFFILE "${DEFFILE}")
		FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_16.def "${DEFFILE}")
		add_library(pmemobj_16 SHARED ${SOURCES_16} ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_16.def)
		target_compile_options(pmemobj_16 PRIVATE /FI"${CMAKE_SOURCE_DIR}/nvml-1.6/src/windows/include/platform.h")
	else()
		add_library(pmemobj_16 SHARED ${SOURCES_16})
		disable_optimization(pmemobj_16)
	endif()

	target_compile_definitions(pmemobj_16 PRIVATE SRCVERSION="${NVML16}")
	target_compile_definitions(pmemobj_16 PRIVATE PMDK_UTF8_API)
	target_compile_definitions(pmemobj_16 PRIVATE _PMEMOBJ_INTRNL)

	target_include_directories(pmemobj_16 PRIVATE nvml-1.6/src/include)
	target_include_directories(pmemobj_16 PRIVATE nvml-1.6/src/libpmemobj)
	target_include_directories(pmemobj_16 PRIVATE nvml-1.6/src/common)
	target_include_directories(pmemobj_16 PRIVATE ${PMEM_INCLUDE_DIRS})

	if(WIN32)
		target_include_directories(pmemobj_16 PRIVATE nvml-1.6/src/windows/include/)
		target_include_directories(pmemobj_16 PRIVATE include/)
	endif()

	target_link_libraries(pmemobj_16 PRIVATE libpmem-convert)
	target_link_libraries(pmemobj_16 PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemobj_16 PRIVATE ${CMAKE_THREAD_LIBS_INIT})

	if(NOT MSVC)
		FILE(READ ${MAX_STABLE}/src/libpmemobj/libpmemobj.link.in LINKFILE)
		string(REPLACE "fault_injection;" "" LINKFILE "${LINKFILE}")
		FILE(WRITE ${MAX_STABLE}/src/libpmemobj/libpmemobj.link "${LINKFILE}")
		target_link_libraries(pmemobj_16 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/nvml-1.6/src/libpmemobj/libpmemobj.link)
	endif()

######################################### libpmempool
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

	target_compile_definitions(libpmempool-convert PRIVATE SRCVERSION="${MAX_VERSION}")
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
	set(LIBPMEMPOOL_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/${MAX_STABLE}/src/include)
	set(LIBPMEMPOOL_LIBRARIES libpmempool-convert)

######################################### libpmempool end
endif(BUILD_CONVERT_V5)

######################################### pmdk 1.5
if(BUILD_15)
	set(NVML15 1.5.1)

	get_pmdk(${NVML15} 501f27e341248e206c8632d7c12007dc7690583f90e081569d6d5786fa3bf1f1 nvml-1.5)

	set(SOURCES_15
		nvml-1.5/src/libpmemobj/alloc_class.c
		nvml-1.5/src/libpmemobj/bucket.c
		nvml-1.5/src/libpmemobj/ctl_debug.c
		nvml-1.5/src/libpmemobj/container_ravl.c
		nvml-1.5/src/libpmemobj/container_seglists.c
		nvml-1.5/src/libpmemobj/cuckoo.c
		nvml-1.5/src/libpmemobj/heap.c
		nvml-1.5/src/libpmemobj/lane.c
		nvml-1.5/src/libpmemobj/libpmemobj.c
		nvml-1.5/src/libpmemobj/list.c
		nvml-1.5/src/libpmemobj/memblock.c
		nvml-1.5/src/libpmemobj/memops.c
		nvml-1.5/src/libpmemobj/obj.c
		nvml-1.5/src/libpmemobj/palloc.c
		nvml-1.5/src/libpmemobj/pmalloc.c
		nvml-1.5/src/libpmemobj/ravl.c
		nvml-1.5/src/libpmemobj/recycler.c
		nvml-1.5/src/libpmemobj/stats.c
		nvml-1.5/src/libpmemobj/sync.c
		nvml-1.5/src/libpmemobj/tx.c
		nvml-1.5/src/libpmemobj/ulog.c

		nvml-1.5/src/common/badblock.c
		nvml-1.5/src/common/ctl.c
		nvml-1.5/src/common/ctl_prefault.c
		nvml-1.5/src/common/ctl_sds.c
		nvml-1.5/src/common/file.c
		nvml-1.5/src/common/mmap.c
		nvml-1.5/src/common/os_dimm_none.c
		nvml-1.5/src/common/out.c
		nvml-1.5/src/common/pool_hdr.c
		nvml-1.5/src/common/set.c
		nvml-1.5/src/common/shutdown_state.c
		nvml-1.5/src/common/util.c
		nvml-1.5/src/common/uuid.c
		)

	if(WIN32)
		set(SOURCES_15 ${SOURCES_15}
			nvml-1.5/src/libpmemobj/libpmemobj_main.c
			nvml-1.5/src/common/badblock_none.c
			nvml-1.5/src/common/file_windows.c
			nvml-1.5/src/common/fs_windows.c
			nvml-1.5/src/common/mmap_windows.c
			nvml-1.5/src/common/os_deep_windows.c
			nvml-1.5/src/common/os_windows.c
			nvml-1.5/src/common/os_thread_windows.c
			nvml-1.5/src/common/util_windows.c
			nvml-1.5/src/common/uuid_windows.c
			)
	else()
		set(SOURCES_15 ${SOURCES_15}
			nvml-1.5/src/common/badblock_ndctl.c
			nvml-1.5/src/common/extent_linux.c
			nvml-1.5/src/common/file_posix.c
			nvml-1.5/src/common/fs_posix.c
			nvml-1.5/src/common/mmap_posix.c
			nvml-1.5/src/common/os_deep_linux.c
			nvml-1.5/src/common/os_posix.c
			nvml-1.5/src/common/os_thread_posix.c
			nvml-1.5/src/common/util_posix.c
			nvml-1.5/src/common/uuid_linux.c
			)
	endif()

	if(MSVC)
		FILE(READ nvml-1.5/src/libpmemobj/libpmemobj.def DEFFILE)
		string(REPLACE "libpmemobj" "pmemobj_15" DEFFILE "${DEFFILE}")
		FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_15.def "${DEFFILE}")
		add_library(pmemobj_15 SHARED ${SOURCES_15} ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_15.def)
		target_compile_options(pmemobj_15 PRIVATE /FI"${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/include/platform.h")
	else()
		add_library(pmemobj_15 SHARED ${SOURCES_15})
		disable_optimization(pmemobj_15)
	endif()

	target_compile_definitions(pmemobj_15 PRIVATE SRCVERSION="${NVML15}")
	target_compile_definitions(pmemobj_15 PRIVATE PMDK_UTF8_API)
	target_compile_definitions(pmemobj_15 PRIVATE _PMEMOBJ_INTRNL)

	target_include_directories(pmemobj_15 PRIVATE nvml-1.5/src/include)
	target_include_directories(pmemobj_15 PRIVATE nvml-1.5/src/libpmemobj)
	target_include_directories(pmemobj_15 PRIVATE nvml-1.5/src/common)
	target_include_directories(pmemobj_15 PRIVATE ${PMEM_INCLUDE_DIRS})

	if(WIN32)
		target_include_directories(pmemobj_15 PRIVATE nvml-1.5/src/windows/include/)
		target_include_directories(pmemobj_15 PRIVATE include/)
	endif()

	target_link_libraries(pmemobj_15 PRIVATE libpmem-convert)
	target_link_libraries(pmemobj_15 PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemobj_15 PRIVATE ${CMAKE_THREAD_LIBS_INIT})

	if(NOT MSVC)
		target_link_libraries(pmemobj_15 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/nvml-1.5/src/libpmemobj/libpmemobj.map)
	endif()

endif()

###################################################### 1.4
if(BUILD_CONVERT_V4)

	set(NVML14 1.4.2)

	get_pmdk(${NVML14} df7e658e75d28cd80f6d2ff7b9fc9ae2885d52f8923fdbacecfd46215115fb4c nvml-1.4)

	set(SOURCES_14
		nvml-1.4/src/libpmemobj/alloc_class.c
		nvml-1.4/src/libpmemobj/bucket.c
		nvml-1.4/src/libpmemobj/container_ravl.c
		nvml-1.4/src/libpmemobj/container_seglists.c
		nvml-1.4/src/libpmemobj/ctl.c
		nvml-1.4/src/libpmemobj/ctl_global.c
		nvml-1.4/src/libpmemobj/cuckoo.c
		nvml-1.4/src/libpmemobj/heap.c
		nvml-1.4/src/libpmemobj/lane.c
		nvml-1.4/src/libpmemobj/libpmemobj.c
		nvml-1.4/src/libpmemobj/list.c
		nvml-1.4/src/libpmemobj/memblock.c
		nvml-1.4/src/libpmemobj/memops.c
		nvml-1.4/src/libpmemobj/obj.c
		nvml-1.4/src/libpmemobj/palloc.c
		nvml-1.4/src/libpmemobj/pmalloc.c
		nvml-1.4/src/libpmemobj/pvector.c
		nvml-1.4/src/libpmemobj/ravl.c
		nvml-1.4/src/libpmemobj/recycler.c
		nvml-1.4/src/libpmemobj/redo.c
		nvml-1.4/src/libpmemobj/ringbuf.c
		nvml-1.4/src/libpmemobj/stats.c
		nvml-1.4/src/libpmemobj/sync.c
		nvml-1.4/src/libpmemobj/tx.c

		nvml-1.4/src/common/file.c
		nvml-1.4/src/common/mmap.c
		nvml-1.4/src/common/os_dimm_none.c
		nvml-1.4/src/common/out.c
		nvml-1.4/src/common/pool_hdr.c
		nvml-1.4/src/common/set.c
		nvml-1.4/src/common/shutdown_state.c
		nvml-1.4/src/common/util.c
		nvml-1.4/src/common/uuid.c
		)

	if(WIN32)
		set(SOURCES_14 ${SOURCES_14}
			nvml-1.4/src/libpmemobj/libpmemobj_main.c
			nvml-1.4/src/common/file_windows.c
			nvml-1.4/src/common/fs_windows.c
			nvml-1.4/src/common/mmap_windows.c
			nvml-1.4/src/common/os_deep_windows.c
			nvml-1.4/src/common/os_windows.c
			nvml-1.4/src/common/os_thread_windows.c
			nvml-1.4/src/common/util_windows.c
			nvml-1.4/src/common/uuid_windows.c
			)
	else()
		set(SOURCES_14 ${SOURCES_14}
			nvml-1.4/src/common/file_posix.c
			nvml-1.4/src/common/fs_posix.c
			nvml-1.4/src/common/mmap_posix.c
			nvml-1.4/src/common/os_deep_linux.c
			nvml-1.4/src/common/os_posix.c
			nvml-1.4/src/common/os_thread_posix.c
			nvml-1.4/src/common/util_posix.c
			nvml-1.4/src/common/uuid_linux.c
			)
	endif()


	if(WIN32)
		set(CONVERT_V4_SOURCES nvml-1.4/src/windows/getopt/getopt.c)
	endif()

	add_library(pmemobj_convert_v4_o OBJECT ${SOURCES_14} ${CONVERT_V4_SOURCES}
		pmemobj_convert_v4.c
		nvml-1.4/src/libpmemblk/btt.c
		nvml-1.4/src/tools/pmempool/common.c
		nvml-1.4/src/tools/pmempool/output.c)


	target_compile_definitions(pmemobj_convert_v4_o PRIVATE SRCVERSION="${NVML14}")
	target_compile_definitions(pmemobj_convert_v4_o PRIVATE PMDK_UTF8_API)
	target_compile_definitions(pmemobj_convert_v4_o PRIVATE _PMEMOBJ_INTRNL)

	target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/include)
	target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/libpmemobj)
	target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/libpmemlog)
	target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/libpmemblk)
	target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/libpmemcto)
	target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/common)
	target_include_directories(pmemobj_convert_v4_o PRIVATE ${PMEM_INCLUDE_DIRS})

	if(MSVC)
		target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/windows/include/)
		target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/windows/getopt/)
		target_include_directories(pmemobj_convert_v4_o PRIVATE include/)
		target_compile_options(pmemobj_convert_v4_o PRIVATE /FI"${CMAKE_SOURCE_DIR}/nvml-1.4/src/windows/include/platform.h")
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

	install(TARGETS pmemobj_convert_v4_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	if(MSVC)
		FILE(READ nvml-1.4/src/libpmemobj/libpmemobj.def DEFFILE)
		string(REPLACE "libpmemobj" "pmemobj_14" DEFFILE "${DEFFILE}")
		FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_14.def "${DEFFILE}")
		add_library(pmemobj_14 SHARED ${SOURCES_14} ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_14.def)
		target_compile_options(pmemobj_14 PRIVATE /FI"${CMAKE_SOURCE_DIR}/nvml-1.4/src/windows/include/platform.h")
	else()
		add_library(pmemobj_14 SHARED ${SOURCES_14})
		disable_optimization(pmemobj_14)
	endif()

	target_compile_definitions(pmemobj_14 PRIVATE SRCVERSION="${NVML14}")
	target_compile_definitions(pmemobj_14 PRIVATE PMDK_UTF8_API)
	target_compile_definitions(pmemobj_14 PRIVATE _PMEMOBJ_INTRNL)

	target_include_directories(pmemobj_14 PRIVATE nvml-1.4/src/include)
	target_include_directories(pmemobj_14 PRIVATE nvml-1.4/src/libpmemobj)
	target_include_directories(pmemobj_14 PRIVATE nvml-1.4/src/common)
	target_include_directories(pmemobj_14 PRIVATE ${PMEM_INCLUDE_DIRS})

	if(WIN32)
		target_include_directories(pmemobj_14 PRIVATE nvml-1.4/src/windows/include/)
		target_include_directories(pmemobj_14 PRIVATE include/)
	endif()

	target_link_libraries(pmemobj_14 PRIVATE libpmem-convert)
	target_link_libraries(pmemobj_14 PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemobj_14 PRIVATE ${CMAKE_THREAD_LIBS_INIT})

	if(NOT MSVC)
		target_link_libraries(pmemobj_14 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/nvml-1.4/src/libpmemobj/libpmemobj.map)
	endif()

endif(BUILD_CONVERT_V4)

###################################################### 1.3 (tests only)
if(BUILD_13)

	set(NVML13 1.3.1)

	get_pmdk(${NVML13} 0e2a3edbd72e56074c07455f20db4dd981c915c46932efa7902e2d4cbff072c9 nvml-1.3)

	set(SOURCES_13
		nvml-1.3/src/libpmemobj/alloc_class.c
		nvml-1.3/src/libpmemobj/bucket.c
		nvml-1.3/src/libpmemobj/container_ctree.c
		nvml-1.3/src/libpmemobj/container_seglists.c
		nvml-1.3/src/libpmemobj/ctl.c
		nvml-1.3/src/libpmemobj/ctl_global.c
		nvml-1.3/src/libpmemobj/ctree.c
		nvml-1.3/src/libpmemobj/cuckoo.c
		nvml-1.3/src/libpmemobj/heap.c
		nvml-1.3/src/libpmemobj/lane.c
		nvml-1.3/src/libpmemobj/libpmemobj.c
		nvml-1.3/src/libpmemobj/list.c
		nvml-1.3/src/libpmemobj/memblock.c
		nvml-1.3/src/libpmemobj/memops.c
		nvml-1.3/src/libpmemobj/obj.c
		nvml-1.3/src/libpmemobj/palloc.c
		nvml-1.3/src/libpmemobj/pmalloc.c
		nvml-1.3/src/libpmemobj/pvector.c
		nvml-1.3/src/libpmemobj/recycler.c
		nvml-1.3/src/libpmemobj/redo.c
		nvml-1.3/src/libpmemobj/ringbuf.c
		nvml-1.3/src/libpmemobj/sync.c
		nvml-1.3/src/libpmemobj/tx.c

		nvml-1.3/src/common/file.c
		nvml-1.3/src/common/mmap.c
		nvml-1.3/src/common/out.c
		nvml-1.3/src/common/pool_hdr.c
		nvml-1.3/src/common/set.c
		nvml-1.3/src/common/util.c
		nvml-1.3/src/common/uuid.c
		)

	if(WIN32)
		set(SOURCES_13 ${SOURCES_13}
			nvml-1.3/src/libpmemobj/libpmemobj_main.c
			nvml-1.3/src/common/file_windows.c
			nvml-1.3/src/common/mmap_windows.c
			nvml-1.3/src/common/os_windows.c
			nvml-1.3/src/common/os_thread_windows.c
			nvml-1.3/src/common/pool_hdr_windows.c
			nvml-1.3/src/common/util_windows.c
			nvml-1.3/src/common/uuid_windows.c
			)
	else()
		set(SOURCES_13 ${SOURCES_13}
			nvml-1.3/src/common/file_linux.c
			nvml-1.3/src/common/mmap_linux.c
			nvml-1.3/src/common/os_linux.c
			nvml-1.3/src/common/os_thread_linux.c
			nvml-1.3/src/common/pool_hdr_linux.c
			nvml-1.3/src/common/util_linux.c
			nvml-1.3/src/common/uuid_linux.c
			)
	endif()

	if(MSVC)
		FILE(READ nvml-1.3/src/libpmemobj/libpmemobj.def DEFFILE)
		string(REPLACE "libpmemobj" "pmemobj_13" DEFFILE "${DEFFILE}")
		FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_13.def "${DEFFILE}")
		add_library(pmemobj_13 SHARED ${SOURCES_13} ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_13.def ${CMAKE_CURRENT_BINARY_DIR}/pmemobj_13.def)
		target_compile_options(pmemobj_13 PRIVATE /FI"${CMAKE_SOURCE_DIR}/nvml-1.3/src/windows/include/platform.h")
	else()
		add_library(pmemobj_13 SHARED ${SOURCES_13})
		disable_optimization(pmemobj_13)
	endif()

	target_compile_definitions(pmemobj_13 PRIVATE SRCVERSION="${NVML13}")
	target_compile_definitions(pmemobj_13 PRIVATE NVML_UTF8_API)
	target_compile_definitions(pmemobj_13 PRIVATE _PMEMOBJ_INTRNL)

	target_include_directories(pmemobj_13 PRIVATE nvml-1.3/src/include)
	target_include_directories(pmemobj_13 PRIVATE nvml-1.3/src/libpmemobj)
	target_include_directories(pmemobj_13 PRIVATE nvml-1.3/src/common)
	target_include_directories(pmemobj_13 PRIVATE ${PMEM_INCLUDE_DIRS})

	if(WIN32)
		target_include_directories(pmemobj_13 PRIVATE nvml-1.3/src/windows/include/)
		target_include_directories(pmemobj_13 PRIVATE include/)
	endif()

	target_link_libraries(pmemobj_13 PRIVATE libpmem-convert)
	target_link_libraries(pmemobj_13 PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemobj_13 PRIVATE ${CMAKE_THREAD_LIBS_INIT})

	if(NOT MSVC)
		target_link_libraries(pmemobj_13 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/nvml-1.3/src/libpmemobj/libpmemobj.map)
	endif()

endif(BUILD_13)

###################################################### 1.2

if(BUILD_CONVERT_V3)

	set(NVML12 1.2.3)

	get_pmdk(${NVML12} 7a2c03661a122079906f700d053f9260f9814d18d49218c1b5a8332b17023fc7 nvml-1.2)

	set(SOURCES_12
		nvml-1.2/src/libpmemobj/bucket.c
		nvml-1.2/src/libpmemobj/ctree.c
		nvml-1.2/src/libpmemobj/cuckoo.c
		nvml-1.2/src/libpmemobj/heap.c
		nvml-1.2/src/libpmemobj/lane.c
		nvml-1.2/src/libpmemobj/libpmemobj.c
		nvml-1.2/src/libpmemobj/list.c
		nvml-1.2/src/libpmemobj/memblock.c
		nvml-1.2/src/libpmemobj/memops.c
		nvml-1.2/src/libpmemobj/obj.c
		nvml-1.2/src/libpmemobj/palloc.c
		nvml-1.2/src/libpmemobj/pmalloc.c
		nvml-1.2/src/libpmemobj/pvector.c
		nvml-1.2/src/libpmemobj/redo.c
		nvml-1.2/src/libpmemobj/sync.c
		nvml-1.2/src/libpmemobj/tx.c

		nvml-1.2/src/common/file.c
		nvml-1.2/src/common/file_linux.c
		nvml-1.2/src/common/mmap.c
		nvml-1.2/src/common/mmap_linux.c
		nvml-1.2/src/common/out.c
		nvml-1.2/src/common/pool_hdr.c
		nvml-1.2/src/common/pool_hdr_linux.c
		nvml-1.2/src/common/set.c
		nvml-1.2/src/common/util.c
		nvml-1.2/src/common/uuid.c
		nvml-1.2/src/common/uuid_linux.c
		nvml-1.2/src/common/util_linux.c
		)

	if(WIN32)
		set(SOURCES_12 ${SOURCES_12} nvml-1.2/src/libpmemobj/libpmemobj_main.c)
	endif()

	add_library(pmemobj_convert_v3_o OBJECT ${SOURCES_12}
		pmemobj_convert_v3.c
		nvml-1.2/src/libpmemblk/btt.c
		nvml-1.2/src/tools/pmempool/common.c)

	target_compile_definitions(pmemobj_convert_v3_o PRIVATE SRCVERSION="${NVML12}")
	target_include_directories(pmemobj_convert_v3_o PRIVATE nvml-1.2/src/include)
	target_include_directories(pmemobj_convert_v3_o PRIVATE nvml-1.2/src/libpmemobj)
	target_include_directories(pmemobj_convert_v3_o PRIVATE nvml-1.2/src/libpmemlog)
	target_include_directories(pmemobj_convert_v3_o PRIVATE nvml-1.2/src/libpmemblk)
	target_include_directories(pmemobj_convert_v3_o PRIVATE nvml-1.2/src/common)
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

	install(TARGETS pmemobj_convert_v3_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	add_library(pmemobj_12 SHARED ${SOURCES_12})
	disable_optimization(pmemobj_12)
	target_compile_definitions(pmemobj_12 PRIVATE SRCVERSION="${NVML12}")
	target_include_directories(pmemobj_12 PRIVATE nvml-1.2/src/include)
	target_include_directories(pmemobj_12 PRIVATE nvml-1.2/src/libpmemobj)
	target_include_directories(pmemobj_12 PRIVATE nvml-1.2/src/common)
	target_include_directories(pmemobj_12 PRIVATE ${PMEM_INCLUDE_DIRS})
	target_link_libraries(pmemobj_12 PRIVATE libpmem-convert)
	target_link_libraries(pmemobj_12 PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemobj_12 PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_12 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/nvml-1.2/src/libpmemobj/libpmemobj.map)

endif(BUILD_CONVERT_V3)

###################################################### 1.1

if(BUILD_CONVERT_V2)

	set(NVML11 1.1)

	get_pmdk(${NVML11} 2d51a356bf0bd61b0259844894223305d5d825af68d51a07aa1d2bc926b65c43 nvml-1.1)

	set(SOURCES_11
		nvml-1.1/src/libpmemobj/bucket.c
		nvml-1.1/src/libpmemobj/ctree.c
		nvml-1.1/src/libpmemobj/cuckoo.c
		nvml-1.1/src/libpmemobj/heap.c
		nvml-1.1/src/libpmemobj/lane.c
		nvml-1.1/src/libpmemobj/libpmemobj.c
		nvml-1.1/src/libpmemobj/list.c
		nvml-1.1/src/libpmemobj/memblock.c
		nvml-1.1/src/libpmemobj/memops.c
		nvml-1.1/src/libpmemobj/obj.c
		nvml-1.1/src/libpmemobj/pmalloc.c
		nvml-1.1/src/libpmemobj/pvector.c
		nvml-1.1/src/libpmemobj/redo.c
		nvml-1.1/src/libpmemobj/sync.c
		nvml-1.1/src/libpmemobj/tx.c

		nvml-1.1/src/common/out.c
		nvml-1.1/src/common/set.c
		nvml-1.1/src/common/set_linux.c
		nvml-1.1/src/common/util.c
		nvml-1.1/src/common/util_linux.c
		)

	if(WIN32)
		set(SOURCES_11 ${SOURCES_11} nvml-1.1/src/libpmemobj/libpmemobj_main.c)
	endif()

	add_library(pmemobj_convert_v2_o OBJECT ${SOURCES_11}
		pmemobj_convert_v2.c
		nvml-1.1/src/libpmemblk/btt.c
		nvml-1.1/src/tools/pmempool/common.c
		)

	target_compile_definitions(pmemobj_convert_v2_o PRIVATE SRCVERSION="${NVML11}")

	target_include_directories(pmemobj_convert_v2_o PRIVATE nvml-1.1/src/include)
	target_include_directories(pmemobj_convert_v2_o PRIVATE nvml-1.1/src/libpmemobj)
	target_include_directories(pmemobj_convert_v2_o PRIVATE nvml-1.1/src/libpmemlog)
	target_include_directories(pmemobj_convert_v2_o PRIVATE nvml-1.1/src/libpmemblk)
	target_include_directories(pmemobj_convert_v2_o PRIVATE nvml-1.1/src/common)
	target_include_directories(pmemobj_convert_v2_o PRIVATE ${PMEM_INCLUDE_DIRS})

	add_library(pmemobj_convert_v2_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_v2_o>)
	target_link_libraries(pmemobj_convert_v2_shared PRIVATE libpmem-convert)
	target_link_libraries(pmemobj_convert_v2_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_convert_v2_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert.map)
	# strip unneeded symbols, requires -fdata-sections -ffunction-sections
	target_link_libraries(pmemobj_convert_v2_shared PRIVATE -Wl,--gc-sections)

	set_target_properties(pmemobj_convert_v2_shared PROPERTIES OUTPUT_NAME pmemobj_convert_v2)
	set_target_properties(pmemobj_convert_v2_shared PROPERTIES PREFIX "")

	install(TARGETS pmemobj_convert_v2_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	add_library(pmemobj_11 SHARED ${SOURCES_11})
	disable_optimization(pmemobj_11)
	target_compile_definitions(pmemobj_11 PRIVATE SRCVERSION="${NVML11}")

	target_include_directories(pmemobj_11 PRIVATE nvml-1.1/src/include)
	target_include_directories(pmemobj_11 PRIVATE nvml-1.1/src/libpmemobj)
	target_include_directories(pmemobj_11 PRIVATE nvml-1.1/src/common)
	target_include_directories(pmemobj_11 PRIVATE ${PMEM_INCLUDE_DIRS})

	target_link_libraries(pmemobj_11 PRIVATE libpmem-convert)
	target_link_libraries(pmemobj_11 PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_11 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/nvml-1.1/src/libpmemobj/libpmemobj.map)

endif(BUILD_CONVERT_V2)

###################################################### 1.0

if(BUILD_CONVERT_V1)

	set(NVML10 1.0)

	get_pmdk(${NVML10} e9c9ed72168047f65fae72808933bfeafd965ed3237ab3fbfb199c362bf5b773 nvml-1.0)

	set(SOURCES_10
		nvml-1.0/src/libpmemobj/bucket.c
		nvml-1.0/src/libpmemobj/ctree.c
		nvml-1.0/src/libpmemobj/cuckoo.c
		nvml-1.0/src/libpmemobj/heap.c
		nvml-1.0/src/libpmemobj/lane.c
		nvml-1.0/src/libpmemobj/libpmemobj.c
		nvml-1.0/src/libpmemobj/list.c
		nvml-1.0/src/libpmemobj/memops.c
		nvml-1.0/src/libpmemobj/obj.c
		nvml-1.0/src/libpmemobj/pmalloc.c
		nvml-1.0/src/libpmemobj/redo.c
		nvml-1.0/src/libpmemobj/sync.c
		nvml-1.0/src/libpmemobj/tx.c

		nvml-1.0/src/common/out.c
		nvml-1.0/src/common/set.c
		nvml-1.0/src/common/util.c
		)

	add_library(pmemobj_convert_v1_o OBJECT ${SOURCES_10}
		pmemobj_convert_v1.c
		nvml-1.0/src/tools/pmempool/common.c)

	target_compile_definitions(pmemobj_convert_v1_o PRIVATE SRCVERSION="${NVML10}")

	target_include_directories(pmemobj_convert_v1_o PRIVATE nvml-1.0/src/include)
	target_include_directories(pmemobj_convert_v1_o PRIVATE nvml-1.0/src/libpmemobj)
	target_include_directories(pmemobj_convert_v1_o PRIVATE nvml-1.0/src/libpmemlog)
	target_include_directories(pmemobj_convert_v1_o PRIVATE nvml-1.0/src/libpmemblk)
	target_include_directories(pmemobj_convert_v1_o PRIVATE nvml-1.0/src/common)
	target_include_directories(pmemobj_convert_v1_o PRIVATE ${PMEM_INCLUDE_DIRS})

	add_library(pmemobj_convert_v1_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_v1_o>)
	target_link_libraries(pmemobj_convert_v1_shared PRIVATE libpmem-convert)
	target_link_libraries(pmemobj_convert_v1_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_convert_v1_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert.map)
	# strip unneeded symbols, requires -fdata-sections -ffunction-sections
	target_link_libraries(pmemobj_convert_v1_shared PRIVATE -Wl,--gc-sections)

	set_target_properties(pmemobj_convert_v1_shared PROPERTIES OUTPUT_NAME pmemobj_convert_v1)
	set_target_properties(pmemobj_convert_v1_shared PROPERTIES PREFIX "")

	install(TARGETS pmemobj_convert_v1_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	add_library(pmemobj_10 SHARED ${SOURCES_10})
	disable_optimization(pmemobj_10)
	target_compile_definitions(pmemobj_10 PRIVATE SRCVERSION="${NVML10}")

	target_include_directories(pmemobj_10 PRIVATE nvml-1.0/src/include)
	target_include_directories(pmemobj_10 PRIVATE nvml-1.0/src/libpmemobj)
	target_include_directories(pmemobj_10 PRIVATE nvml-1.0/src/common)
	target_include_directories(pmemobj_10 PRIVATE ${PMEM_INCLUDE_DIRS})
	target_link_libraries(pmemobj_10 PRIVATE libpmem-convert)
	target_link_libraries(pmemobj_10 PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_10 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/nvml-1.0/src/libpmemobj/libpmemobj.map)

endif(BUILD_CONVERT_V1)

###################################################### everything else
if (WIN32)
	add_executable(pmdk-convert pmdk-convert.c nvml-${MAX_VERSION}/src/windows/getopt/getopt.c)
	target_include_directories(pmdk-convert PRIVATE nvml-${MAX_VERSION}/src/windows/getopt/)
	target_include_directories(pmdk-convert PRIVATE nvml-${MAX_VERSION}/src/windows/include/)
else()
	add_executable(pmdk-convert pmdk-convert.c)
endif()

target_compile_definitions(pmdk-convert PRIVATE LIBDIR="${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
target_compile_definitions(pmdk-convert PRIVATE MIN_VERSION_MAJOR=${MIN_VERSION_MAJOR})
target_compile_definitions(pmdk-convert PRIVATE MIN_VERSION_MINOR=${MIN_VERSION_MINOR})
target_compile_definitions(pmdk-convert PRIVATE MAX_VERSION_MAJOR=${MAX_VERSION_MAJOR})
target_compile_definitions(pmdk-convert PRIVATE MAX_VERSION_MINOR=${MAX_VERSION_MINOR})
target_link_libraries(pmdk-convert PRIVATE ${CMAKE_DL_LIBS})
target_link_libraries(pmdk-convert PRIVATE ${CMAKE_THREAD_LIBS_INIT})

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
