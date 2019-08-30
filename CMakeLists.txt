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
project(pmdk-convert C)

set(VERSION_MAJOR 1)
set(VERSION_MINOR 5)
set(VERSION_PATCH 2)
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

set(MAX_VERSION 1.5)

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
	if (${ver_next} VERSION_GREATER ${MAX_VERSION} )
		set(${RESULT} 0 PARENT_SCOPE)
		return()
	endif()
	set(${RESULT} 1 PARENT_SCOPE)
	return()
endfunction(version_supported)

version_supported(1.5 1.5 BUILD_CONVERT_V5)
version_supported(1.4 1.5 BUILD_CONVERT_V4)
version_supported(1.2 1.4 BUILD_CONVERT_V3)
version_supported(1.1 1.2 BUILD_CONVERT_V2)
version_supported(1.0 1.1 BUILD_CONVERT_V1)

if (NOT ${MIN_VERSION} VERSION_GREATER "1.3")
	set(BUILD_13 1)
else()
	set(BUILD_13 0)
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

if(BUILD_CONVERT_V5)
	set(NVML15 1.5.2)

	set(pkg nvml-${NVML15}.tar.gz)
	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${pkg})
		message(STATUS "Downloading NVML ${NVML15}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML15}.tar.gz ${CMAKE_SOURCE_DIR}/${pkg}
			EXPECTED_HASH SHA256=a72691971a98b8472b26271f19d69e6c9b849c1ca42124ea2e2bd8c3fcdff1b1)
		message(STATUS "Downloading NVML ${NVML15} done")
	endif()

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-1.5)
		uncompress(${pkg})
		file(RENAME ${CMAKE_SOURCE_DIR}/pmdk-${NVML15} ${CMAKE_SOURCE_DIR}/nvml-1.5)
	endif()


	set(LIBPMEM_SOURCES
		nvml-1.5/src/common/file.c
		nvml-1.5/src/common/mmap.c
		nvml-1.5/src/common/out.c
		nvml-1.5/src/common/util.c
		nvml-1.5/src/libpmem/libpmem.c
		nvml-1.5/src/libpmem/memops_generic.c
		nvml-1.5/src/libpmem/pmem.c
		)
	if (CMAKE_SYSTEM_PROCESSOR STREQUAL x86_64
		OR CMAKE_SYSTEM_PROCESSOR STREQUAL amd64
		OR CMAKE_SYSTEM_PROCESSOR STREQUAL AMD64)
		set(LIBPMEM_SOURCES ${LIBPMEM_SOURCES}
			nvml-1.5/src/libpmem/x86_64/init.c
			nvml-1.5/src/libpmem/x86_64/cpu.c
			)
	elseif (CMAKE_SYSTEM_PROCESSOR STREQUAL aarch64)
		set(LIBPMEM_SOURCES ${LIBPMEM_SOURCES}
			nvml-1.5/src/libpmem/aarch64/init.c
			)
	else()
		message(FATAL_ERROR "Unknown architecture ${CMAKE_SYSTEM_PROCESSOR}")
	endif()
	if(WIN32)
		set(LIBPMEM_SOURCES ${LIBPMEM_SOURCES}
			nvml-1.5/src/libpmem/libpmem_main.c
			nvml-1.5/src/libpmem/pmem_windows.c
			nvml-1.5/src/windows/win_mmap.c
			nvml-1.5/src/common/file_windows.c
			nvml-1.5/src/common/fs_windows.c
			nvml-1.5/src/common/mmap_windows.c
			nvml-1.5/src/common/os_auto_flush_windows.c
			nvml-1.5/src/common/os_deep_windows.c
			nvml-1.5/src/common/os_windows.c
			nvml-1.5/src/common/os_thread_windows.c
			nvml-1.5/src/common/util_windows.c
			)
	else()
		set(LIBPMEM_SOURCES ${LIBPMEM_SOURCES}
			nvml-1.5/src/libpmem/pmem_posix.c
			nvml-1.5/src/common/file_posix.c
			nvml-1.5/src/common/fs_posix.c
			nvml-1.5/src/common/mmap_posix.c
			nvml-1.5/src/common/os_auto_flush_linux.c
			nvml-1.5/src/common/os_deep_linux.c
			nvml-1.5/src/common/os_posix.c
			nvml-1.5/src/common/os_thread_posix.c
			nvml-1.5/src/common/util_posix.c
			)
	endif()

	if(MSVC)
		FILE(READ nvml-1.5/src/libpmem/libpmem.def DEFFILE)
		string(REPLACE "libpmem" "libpmem-convert" DEFFILE "${DEFFILE}")
		FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/libpmem.def "${DEFFILE}")
		add_library(libpmem-convert SHARED ${LIBPMEM_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/libpmem.def)
		target_link_libraries(libpmem-convert PRIVATE ntdll.lib)
	else()
		add_library(libpmem-convert SHARED ${LIBPMEM_SOURCES})
		target_link_libraries(libpmem-convert PRIVATE -Wl,--version-script=${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmem/libpmem.map)
	endif()

	# remove lib prefix from library name
	set_target_properties(libpmem-convert PROPERTIES PREFIX "")
	target_compile_definitions(libpmem-convert PRIVATE SRCVERSION="${NVML15}")
	target_compile_definitions(libpmem-convert PRIVATE PMDK_UTF8_API)
	target_compile_definitions(libpmem-convert PRIVATE _PMEMOBJ_INTRNL)
	target_compile_definitions(libpmem-convert PRIVATE SSE2_AVAILABLE=0)
	target_compile_definitions(libpmem-convert PRIVATE AVX_AVAILABLE=0)
	target_compile_definitions(libpmem-convert PRIVATE AVX512F_AVAILABLE=0)

	target_include_directories(libpmem-convert PRIVATE nvml-1.5/src/include)
	target_include_directories(libpmem-convert PRIVATE nvml-1.5/src/common)
	target_include_directories(libpmem-convert PRIVATE nvml-1.5/src/libpmem)

	if(MSVC)
		target_include_directories(libpmem-convert PRIVATE nvml-1.5/src/windows/include/)
		target_include_directories(libpmem-convert PRIVATE include/)
		target_compile_options(libpmem-convert PRIVATE /FI"${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/include/platform.h")
	endif()

	target_link_libraries(libpmem-convert PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	set(PMEM_INCLUDE_DIRS nvml-1.5/src/include)
	set(PMEM_LIBRARIES libpmem-convert)
	install(TARGETS libpmem-convert
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

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

	if(WIN32)
		set(CONVERT_V5_SOURCES nvml-1.5/src/windows/getopt/getopt.c)
	endif()

	add_library(pmemobj_convert_v5_o OBJECT ${SOURCES_15} ${CONVERT_V5_SOURCES}
		pmemobj_convert_v5.c
		nvml-1.5/src/libpmemblk/btt.c
		nvml-1.5/src/tools/pmempool/common.c
		nvml-1.5/src/tools/pmempool/output.c)

	target_compile_definitions(pmemobj_convert_v5_o PRIVATE SRCVERSION="${NVML15}")
	target_compile_definitions(pmemobj_convert_v5_o PRIVATE PMDK_UTF8_API)
	target_compile_definitions(pmemobj_convert_v5_o PRIVATE _PMEMOBJ_INTRNL)

	target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.5/src/include)
	target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.5/src/libpmemobj)
	target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.5/src/libpmemlog)
	target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.5/src/libpmemblk)
	target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.5/src/libpmemcto)
	target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.5/src/common)
	target_include_directories(pmemobj_convert_v5_o PRIVATE ${PMEM_INCLUDE_DIRS})

	if(MSVC)
		target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.5/src/windows/include/)
		target_include_directories(pmemobj_convert_v5_o PRIVATE nvml-1.5/src/windows/getopt/)
		target_include_directories(pmemobj_convert_v5_o PRIVATE include/)
		target_compile_options(pmemobj_convert_v5_o PRIVATE /FI"${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/include/platform.h")
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

	set(LIBPMEMPOOL_SOURCES
		nvml-1.5/src/libpmempool/check_backup.c
		nvml-1.5/src/libpmempool/check_bad_blocks.c
		nvml-1.5/src/libpmempool/check_blk.c
		nvml-1.5/src/libpmempool/check_btt_info.c
		nvml-1.5/src/libpmempool/check_btt_map_flog.c
		nvml-1.5/src/libpmempool/check.c
		nvml-1.5/src/libpmempool/check_log.c
		nvml-1.5/src/libpmempool/check_pool_hdr.c
		nvml-1.5/src/libpmempool/check_sds.c
		nvml-1.5/src/libpmempool/check_util.c
		nvml-1.5/src/libpmempool/check_write.c
		nvml-1.5/src/libpmempool/feature.c
		nvml-1.5/src/libpmempool/libpmempool.c
		nvml-1.5/src/libpmempool/pool.c
		nvml-1.5/src/libpmempool/replica.c
		nvml-1.5/src/libpmempool/rm.c
		nvml-1.5/src/libpmempool/sync.c
		nvml-1.5/src/libpmempool/transform.c

		nvml-1.5/src/libpmemblk/btt.c

		nvml-1.5/src/common/badblock.c
		nvml-1.5/src/common/file.c
		nvml-1.5/src/common/mmap.c
		nvml-1.5/src/common/pool_hdr.c
		nvml-1.5/src/common/out.c
		nvml-1.5/src/common/os_dimm_none.c
		nvml-1.5/src/common/set.c
		nvml-1.5/src/common/shutdown_state.c
		nvml-1.5/src/common/util.c
		nvml-1.5/src/common/uuid.c
		)

	if(WIN32)
		set(LIBPMEMPOOL_SOURCES ${LIBPMEMPOOL_SOURCES}
			nvml-1.5/src/libpmempool/libpmempool_main.c
			nvml-1.5/src/common/badblock_none.c
			nvml-1.5/src/common/file_windows.c
			nvml-1.5/src/common/fs_windows.c
			nvml-1.5/src/common/mmap_windows.c
			nvml-1.5/src/common/os_deep_windows.c
			nvml-1.5/src/common/os_thread_windows.c
			nvml-1.5/src/common/os_windows.c
			nvml-1.5/src/common/util_windows.c
			nvml-1.5/src/common/uuid_windows.c
			)
	else()
		set(LIBPMEMPOOL_SOURCES ${LIBPMEMPOOL_SOURCES}
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
		FILE(READ nvml-1.5/src/libpmempool/libpmempool.def DEFFILE)
		string(REPLACE "libpmempool" "libpmempool-convert" DEFFILE "${DEFFILE}")
		FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/libpmempool.def "${DEFFILE}")
		add_library(libpmempool-convert SHARED ${LIBPMEMPOOL_SOURCES} ${CMAKE_CURRENT_BINARY_DIR}/libpmempool.def)
	else()
		add_library(libpmempool-convert SHARED ${LIBPMEMPOOL_SOURCES})
		target_link_libraries(libpmempool-convert PRIVATE -Wl,--version-script=${CMAKE_SOURCE_DIR}/nvml-1.5/src/libpmempool/libpmempool.map)
	endif()
	target_link_libraries(libpmempool-convert PRIVATE libpmem-convert)

	target_compile_definitions(libpmempool-convert PRIVATE SRCVERSION="${NVML15}")
	target_compile_definitions(libpmempool-convert PRIVATE PMDK_UTF8_API)

	target_include_directories(libpmempool-convert PRIVATE nvml-1.5/src/include)
	target_include_directories(libpmempool-convert PRIVATE nvml-1.5/src/common)
	target_include_directories(libpmempool-convert PRIVATE nvml-1.5/src/libpmempool)
	target_include_directories(libpmempool-convert PRIVATE nvml-1.5/src/libpmemblk)
	target_include_directories(libpmempool-convert PRIVATE nvml-1.5/src/libpmemcto)
	target_include_directories(libpmempool-convert PRIVATE nvml-1.5/src/libpmemlog)
	target_include_directories(libpmempool-convert PRIVATE nvml-1.5/src/libpmemobj)

	if(MSVC)
		target_include_directories(libpmempool-convert PRIVATE nvml-1.5/src/windows/include/)
		target_include_directories(libpmempool-convert PRIVATE include/)
		target_compile_options(libpmempool-convert PRIVATE /FI"${CMAKE_SOURCE_DIR}/nvml-1.5/src/windows/include/platform.h")
	endif()

	target_link_libraries(libpmempool-convert PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	set(LIBPMEMPOOL_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/nvml-1.5/src/include)
	set(LIBPMEMPOOL_LIBRARIES libpmempool-convert)

endif(BUILD_CONVERT_V5)

###################################################### 1.4
if(BUILD_CONVERT_V4)

	set(NVML14 1.4.3)

	set(pkg nvml-${NVML14}.tar.gz)
	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${pkg})
		message(STATUS "Downloading NVML ${NVML14}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML14}.tar.gz ${CMAKE_SOURCE_DIR}/${pkg}
			EXPECTED_HASH SHA256=93a8ba7383fa02dfd176d50aff56ace6bbac86bbaf26b8b1949ee703a4ec3a31)
		message(STATUS "Downloading NVML ${NVML14} done")
	endif()

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-1.4)
		uncompress(${pkg})
		file(RENAME ${CMAKE_SOURCE_DIR}/pmdk-${NVML14} ${CMAKE_SOURCE_DIR}/nvml-1.4)
	endif()

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

	set(NVML13 1.3.3)

	set(pkg nvml-${NVML13}.tar.gz)
	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${pkg})
		message(STATUS "Downloading NVML ${NVML13}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML13}.tar.gz ${CMAKE_SOURCE_DIR}/${pkg}
			EXPECTED_HASH SHA256=5d46497bb151e6a36e801aed45bfef0d068c55cb2267329053e7489e01742f47)
		message(STATUS "Downloading NVML ${NVML13} done")
	endif()

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-1.3)
		uncompress(${pkg})

		file(RENAME ${CMAKE_SOURCE_DIR}/pmdk-${NVML13} ${CMAKE_SOURCE_DIR}/nvml-1.3)
	endif()

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

	set(NVML12 1.2.4)

	set(pkg nvml-${NVML12}.tar.gz)
	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${pkg})
		message(STATUS "Downloading NVML ${NVML12}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML12}.tar.gz ${CMAKE_SOURCE_DIR}/${pkg}
			EXPECTED_HASH SHA256=aa57b4d969a7582ad5897b5e979b3f2a4015ace7777388227826a65dbf626edd)
		message(STATUS "Downloading NVML ${NVML12} done")
	endif()

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-1.2)
		uncompress(${pkg})

		file(RENAME ${CMAKE_SOURCE_DIR}/pmdk-${NVML12} ${CMAKE_SOURCE_DIR}/nvml-1.2)
	endif()

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

	set(pkg nvml-${NVML11}.tar.gz)
	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${pkg})
		message(STATUS "Downloading NVML ${NVML11}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML11}.tar.gz ${CMAKE_SOURCE_DIR}/${pkg}
			EXPECTED_HASH SHA256=2d51a356bf0bd61b0259844894223305d5d825af68d51a07aa1d2bc926b65c43)
		message(STATUS "Downloading NVML ${NVML11} done")
	endif()

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-1.1)
		uncompress(${pkg})

		file(RENAME ${CMAKE_SOURCE_DIR}/pmdk-${NVML11} ${CMAKE_SOURCE_DIR}/nvml-1.1)
	endif()

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

	set(pkg nvml-${NVML10}.tar.gz)
	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${pkg})
		message(STATUS "Downloading NVML ${NVML10}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML10}.tar.gz ${CMAKE_SOURCE_DIR}/${pkg}
			EXPECTED_HASH SHA256=e9c9ed72168047f65fae72808933bfeafd965ed3237ab3fbfb199c362bf5b773)
		message(STATUS "Downloading NVML ${NVML10} done")
	endif()

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-1.0)
		uncompress(${pkg})

		file(RENAME ${CMAKE_SOURCE_DIR}/pmdk-${NVML10} ${CMAKE_SOURCE_DIR}/nvml-1.0)
	endif()

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
