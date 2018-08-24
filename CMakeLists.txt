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

cmake_minimum_required(VERSION 3.3)
project(pmdk-convert C)

set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

include(FindThreads)

set(MIN_VERSION 1.0 CACHE STRING "First supported version (major.minor)")
set(MAX_VERSION 1.5 CACHE STRING "Last supported version (major.minor)")

STRING(REGEX REPLACE "^([0-9]+)\\.[0-9]+" "\\1" MIN_VERSION_MAJOR "${MIN_VERSION}")
STRING(REGEX REPLACE "^[0-9]+\\.([0-9]+)" "\\1" MIN_VERSION_MINOR "${MIN_VERSION}")

STRING(REGEX REPLACE "^([0-9]+)\\.[0-9]+" "\\1" MAX_VERSION_MAJOR "${MAX_VERSION}")
STRING(REGEX REPLACE "^[0-9]+\\.([0-9]+)" "\\1" MAX_VERSION_MINOR "${MAX_VERSION}")

if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE "RelWithDebInfo")
endif (NOT CMAKE_BUILD_TYPE)

include(CheckCCompilerFlag)
include(GNUInstallDirs)
find_package(PkgConfig QUIET)

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

add_c_flag(-ggdb DEBUG)
add_c_flag(-DDEBUG DEBUG)

add_c_flag(-ggdb RELWITHDEBINFO)
add_c_flag(-fno-omit-frame-pointer RELWITHDEBINFO)

add_c_flag("-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2" RELEASE)

configure_file(
	"${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
	"${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
	IMMEDIATE @ONLY)

add_custom_target(uninstall
	COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

macro(require_libpmem ver)
	if(PKG_CONFIG_FOUND)
		pkg_check_modules(PMEM REQUIRED libpmem>=${ver})
	else()
		find_package(PMEM REQUIRED)
	endif()
	link_directories(${PMEM_LIBRARY_DIRS})
endmacro()

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

version_supported(1.4 1.5 BUILD_CONVERT_V4)
version_supported(1.2 1.4 BUILD_CONVERT_V3)
version_supported(1.1 1.2 BUILD_CONVERT_V2)
version_supported(1.0 1.1 BUILD_CONVERT_V1)

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

###################################################### 1.4
if(BUILD_CONVERT_V4)

	require_libpmem(1.4)

	set(NVML14 1.4.2)

	set(pkg nvml-${NVML14}.tar.gz)
	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${pkg})
		message(STATUS "Downloading NVML ${NVML14}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML14}.tar.gz ${CMAKE_SOURCE_DIR}/${pkg}
			EXPECTED_HASH SHA256=df7e658e75d28cd80f6d2ff7b9fc9ae2885d52f8923fdbacecfd46215115fb4c)
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
		nvml-1.4/src/common/file_posix.c
		nvml-1.4/src/common/fs_posix.c
		nvml-1.4/src/common/mmap.c
		nvml-1.4/src/common/mmap_posix.c
		nvml-1.4/src/common/os_deep_linux.c
		nvml-1.4/src/common/os_dimm_none.c
		nvml-1.4/src/common/os_posix.c
		nvml-1.4/src/common/os_thread_posix.c
		nvml-1.4/src/common/out.c
		nvml-1.4/src/common/pool_hdr.c
		nvml-1.4/src/common/set.c
		nvml-1.4/src/common/shutdown_state.c
		nvml-1.4/src/common/util.c
		nvml-1.4/src/common/util_posix.c
		nvml-1.4/src/common/uuid.c
		nvml-1.4/src/common/uuid_linux.c
		)

	if(WIN32)
		set(SOURCES_14 ${SOURCES_14} nvml-1.4/src/libpmemobj/libpmemobj_main.c)
	endif()

	add_library(pmemobj_convert_v4_o OBJECT ${SOURCES_14}
		pmemobj_convert_v4.c
		nvml-1.4/src/libpmemblk/btt.c
		nvml-1.4/src/tools/pmempool/common.c)

	target_compile_definitions(pmemobj_convert_v4_o PRIVATE SRCVERSION="${NVML14}")
	target_compile_definitions(pmemobj_convert_v4_o PRIVATE USE_LIBDL)
	target_compile_definitions(pmemobj_convert_v4_o PRIVATE _PMEMOBJ_INTRNL)

	target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/include)
	target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/libpmemobj)
	target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/libpmemlog)
	target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/libpmemblk)
	target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/libpmemcto)
	target_include_directories(pmemobj_convert_v4_o PRIVATE nvml-1.4/src/common)
	target_include_directories(pmemobj_convert_v4_o PRIVATE ${PMEM_INCLUDE_DIRS})

	add_library(pmemobj_convert_v4_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_v4_o>)
	target_link_libraries(pmemobj_convert_v4_shared PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_convert_v4_shared PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemobj_convert_v4_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_convert_v4_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert.map)
	# strip unneeded symbols, requires -fdata-sections -ffunction-sections
	target_link_libraries(pmemobj_convert_v4_shared PRIVATE -Wl,--gc-sections)
	set_target_properties(pmemobj_convert_v4_shared PROPERTIES OUTPUT_NAME pmemobj_convert_v4)

	install(TARGETS pmemobj_convert_v4_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	add_library(pmemobj_14 SHARED ${SOURCES_14})
	target_compile_definitions(pmemobj_14 PRIVATE SRCVERSION="${NVML14}")
	target_compile_definitions(pmemobj_14 PRIVATE USE_LIBDL)
	target_compile_definitions(pmemobj_14 PRIVATE _PMEMOBJ_INTRNL)

	target_include_directories(pmemobj_14 PRIVATE nvml-1.4/src/include)
	target_include_directories(pmemobj_14 PRIVATE nvml-1.4/src/libpmemobj)
	target_include_directories(pmemobj_14 PRIVATE nvml-1.4/src/common)
	target_include_directories(pmemobj_14 PRIVATE ${PMEM_INCLUDE_DIRS})
	target_link_libraries(pmemobj_14 PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_14 PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemobj_14 PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_14 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/nvml-1.4/src/libpmemobj/libpmemobj.map)

endif(BUILD_CONVERT_V4)

###################################################### 1.3 (tests only)
if(BUILD_CONVERT_V4)

	require_libpmem(1.3)

	set(NVML13 1.3.1)

	set(pkg nvml-${NVML13}.tar.gz)
	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${pkg})
		message(STATUS "Downloading NVML ${NVML13}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML13}.tar.gz ${CMAKE_SOURCE_DIR}/${pkg}
			EXPECTED_HASH SHA256=0e2a3edbd72e56074c07455f20db4dd981c915c46932efa7902e2d4cbff072c9)
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
		nvml-1.3/src/common/file_linux.c
		nvml-1.3/src/common/mmap.c
		nvml-1.3/src/common/mmap_linux.c
		nvml-1.3/src/common/os_linux.c
		nvml-1.3/src/common/os_thread_linux.c
		nvml-1.3/src/common/out.c
		nvml-1.3/src/common/pool_hdr.c
		nvml-1.3/src/common/pool_hdr_linux.c
		nvml-1.3/src/common/set.c
		nvml-1.3/src/common/util.c
		nvml-1.3/src/common/uuid.c
		nvml-1.3/src/common/uuid_linux.c
		nvml-1.3/src/common/util_linux.c
		)

	if(WIN32)
		set(SOURCES_13 ${SOURCES_13} nvml-1.3/src/libpmemobj/libpmemobj_main.c)
	endif()

	add_library(pmemobj_13 SHARED ${SOURCES_13})
	target_compile_definitions(pmemobj_13 PRIVATE SRCVERSION="${NVML13}")
	target_compile_definitions(pmemobj_13 PRIVATE USE_LIBDL)
	target_compile_definitions(pmemobj_13 PRIVATE _PMEMOBJ_INTRNL)

	target_include_directories(pmemobj_13 PRIVATE nvml-1.3/src/include)
	target_include_directories(pmemobj_13 PRIVATE nvml-1.3/src/libpmemobj)
	target_include_directories(pmemobj_13 PRIVATE nvml-1.3/src/common)
	target_include_directories(pmemobj_13 PRIVATE ${PMEM_INCLUDE_DIRS})
	target_link_libraries(pmemobj_13 PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_13 PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemobj_13 PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_13 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/nvml-1.3/src/libpmemobj/libpmemobj.map)

endif(BUILD_CONVERT_V4)

###################################################### 1.2

if(BUILD_CONVERT_V3)

	require_libpmem(1.2)

	set(NVML12 1.2.3)

	set(pkg nvml-${NVML12}.tar.gz)
	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${pkg})
		message(STATUS "Downloading NVML ${NVML12}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML12}.tar.gz ${CMAKE_SOURCE_DIR}/${pkg}
			EXPECTED_HASH SHA256=7a2c03661a122079906f700d053f9260f9814d18d49218c1b5a8332b17023fc7)
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
	target_compile_definitions(pmemobj_convert_v3_o PRIVATE USE_LIBDL)

	target_include_directories(pmemobj_convert_v3_o PRIVATE nvml-1.2/src/include)
	target_include_directories(pmemobj_convert_v3_o PRIVATE nvml-1.2/src/libpmemobj)
	target_include_directories(pmemobj_convert_v3_o PRIVATE nvml-1.2/src/libpmemlog)
	target_include_directories(pmemobj_convert_v3_o PRIVATE nvml-1.2/src/libpmemblk)
	target_include_directories(pmemobj_convert_v3_o PRIVATE nvml-1.2/src/common)
	target_include_directories(pmemobj_convert_v3_o PRIVATE ${PMEM_INCLUDE_DIRS})

	add_library(pmemobj_convert_v3_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_v3_o>)
	target_link_libraries(pmemobj_convert_v3_shared PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_convert_v3_shared PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemobj_convert_v3_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_convert_v3_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert.map)
	# strip unneeded symbols, requires -fdata-sections -ffunction-sections
	target_link_libraries(pmemobj_convert_v3_shared PRIVATE -Wl,--gc-sections)

	set_target_properties(pmemobj_convert_v3_shared PROPERTIES OUTPUT_NAME pmemobj_convert_v3)

	install(TARGETS pmemobj_convert_v3_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	add_library(pmemobj_12 SHARED ${SOURCES_12})
	target_compile_definitions(pmemobj_12 PRIVATE SRCVERSION="${NVML12}")
	target_compile_definitions(pmemobj_12 PRIVATE USE_LIBDL)

	target_include_directories(pmemobj_12 PRIVATE nvml-1.2/src/include)
	target_include_directories(pmemobj_12 PRIVATE nvml-1.2/src/libpmemobj)
	target_include_directories(pmemobj_12 PRIVATE nvml-1.2/src/common)
	target_include_directories(pmemobj_12 PRIVATE ${PMEM_INCLUDE_DIRS})
	target_link_libraries(pmemobj_12 PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_12 PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemobj_12 PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_12 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/nvml-1.2/src/libpmemobj/libpmemobj.map)

endif(BUILD_CONVERT_V3)

###################################################### 1.1

if(BUILD_CONVERT_V2)

	require_libpmem(1.1)

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
	target_link_libraries(pmemobj_convert_v2_shared PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_convert_v2_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_convert_v2_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert.map)
	# strip unneeded symbols, requires -fdata-sections -ffunction-sections
	target_link_libraries(pmemobj_convert_v2_shared PRIVATE -Wl,--gc-sections)

	set_target_properties(pmemobj_convert_v2_shared PROPERTIES OUTPUT_NAME pmemobj_convert_v2)

	install(TARGETS pmemobj_convert_v2_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	add_library(pmemobj_11 SHARED ${SOURCES_11})
	target_compile_definitions(pmemobj_11 PRIVATE SRCVERSION="${NVML11}")

	target_include_directories(pmemobj_11 PRIVATE nvml-1.1/src/include)
	target_include_directories(pmemobj_11 PRIVATE nvml-1.1/src/libpmemobj)
	target_include_directories(pmemobj_11 PRIVATE nvml-1.1/src/common)
	target_include_directories(pmemobj_11 PRIVATE ${PMEM_INCLUDE_DIRS})

	target_link_libraries(pmemobj_11 PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_11 PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_11 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/nvml-1.1/src/libpmemobj/libpmemobj.map)

endif(BUILD_CONVERT_V2)

###################################################### 1.0

if(BUILD_CONVERT_V1)

	require_libpmem(1.0)

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
	target_link_libraries(pmemobj_convert_v1_shared PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_convert_v1_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_convert_v1_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert.map)
	# strip unneeded symbols, requires -fdata-sections -ffunction-sections
	target_link_libraries(pmemobj_convert_v1_shared PRIVATE -Wl,--gc-sections)

	set_target_properties(pmemobj_convert_v1_shared PROPERTIES OUTPUT_NAME pmemobj_convert_v1)

	install(TARGETS pmemobj_convert_v1_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

	add_library(pmemobj_10 SHARED ${SOURCES_10})
	target_compile_definitions(pmemobj_10 PRIVATE SRCVERSION="${NVML10}")

	target_include_directories(pmemobj_10 PRIVATE nvml-1.0/src/include)
	target_include_directories(pmemobj_10 PRIVATE nvml-1.0/src/libpmemobj)
	target_include_directories(pmemobj_10 PRIVATE nvml-1.0/src/common)
	target_include_directories(pmemobj_10 PRIVATE ${PMEM_INCLUDE_DIRS})
	target_link_libraries(pmemobj_10 PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_10 PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_10 PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/nvml-1.0/src/libpmemobj/libpmemobj.map)

endif(BUILD_CONVERT_V1)

###################################################### everything else

add_executable(pmdk-convert pmdk-convert.c)
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
