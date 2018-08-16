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
set(MAX_VERSION 1.4 CACHE STRING "Last supported version (major.minor)")

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

function(version_supported ver RESULT)
	if (${MIN_VERSION} VERSION_GREATER ${ver})
		set(${RESULT} 0 PARENT_SCOPE)
		return()
	endif()
	if (${MAX_VERSION} VERSION_GREATER ${ver})
		set(${RESULT} 1 PARENT_SCOPE)
		return()
	endif()
	set(${RESULT} 0 PARENT_SCOPE)
	return()
endfunction(version_supported)

version_supported(1.4 BUILD_CONVERT_14_TO_15)
version_supported(1.3 BUILD_CONVERT_13_TO_14)
version_supported(1.2 BUILD_CONVERT_12_TO_13)
version_supported(1.1 BUILD_CONVERT_11_TO_12)
version_supported(1.0 BUILD_CONVERT_10_TO_11)

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

###################################################### 1.4
if(BUILD_CONVERT_14_TO_15)

	require_libpmem(1.4-rc1)

	set(NVML14 1.4-rc1)

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-${NVML14}.zip)
		message(STATUS "Downloading NVML ${NVML14}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML14}.zip ${CMAKE_SOURCE_DIR}/nvml-${NVML14}.zip
			EXPECTED_HASH SHA256=4600c3e930b793ed90aa43d87616ad2bee4d8c755fd8312d67047c81a4ce2a78)
		message(STATUS "Downloading NVML ${NVML14} done")
	endif()

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-1.4)
		execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${CMAKE_SOURCE_DIR}/nvml-${NVML14}.zip
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
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

	add_library(pmemobj_convert_14_to_15_o OBJECT ${SOURCES_14}
		pmemobj_convert_1.4_to_1.5.c
		nvml-1.4/src/libpmemblk/btt.c
		nvml-1.4/src/tools/pmempool/common.c)

	target_compile_definitions(pmemobj_convert_14_to_15_o PRIVATE SRCVERSION="${NVML14}")
	target_compile_definitions(pmemobj_convert_14_to_15_o PRIVATE USE_LIBDL)
	target_compile_definitions(pmemobj_convert_14_to_15_o PRIVATE _PMEMOBJ_INTRNL)

	target_include_directories(pmemobj_convert_14_to_15_o PRIVATE nvml-1.4/src/include)
	target_include_directories(pmemobj_convert_14_to_15_o PRIVATE nvml-1.4/src/libpmemobj)
	target_include_directories(pmemobj_convert_14_to_15_o PRIVATE nvml-1.4/src/libpmemlog)
	target_include_directories(pmemobj_convert_14_to_15_o PRIVATE nvml-1.4/src/libpmemblk)
	target_include_directories(pmemobj_convert_14_to_15_o PRIVATE nvml-1.4/src/libpmemcto)
	target_include_directories(pmemobj_convert_14_to_15_o PRIVATE nvml-1.4/src/common)
	target_include_directories(pmemobj_convert_14_to_15_o PRIVATE ${PMEM_INCLUDE_DIRS})

	add_library(pmemobj_convert_14_to_15_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_14_to_15_o>)
	target_link_libraries(pmemobj_convert_14_to_15_shared PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_convert_14_to_15_shared PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemobj_convert_14_to_15_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_convert_14_to_15_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert_1.4_to_1.5.map)
	# strip unneeded symbols, requires -fdata-sections -ffunction-sections
	target_link_libraries(pmemobj_convert_14_to_15_shared PRIVATE -Wl,--gc-sections)
	set_target_properties(pmemobj_convert_14_to_15_shared PROPERTIES OUTPUT_NAME pmemobj_convert_14_to_15)

	install(TARGETS pmemobj_convert_14_to_15_shared
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

endif(BUILD_CONVERT_14_TO_15)

###################################################### 1.3
if(BUILD_CONVERT_13_TO_14)

	require_libpmem(1.3)

	set(NVML13 1.3.1)

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-${NVML13}.zip)
		message(STATUS "Downloading NVML ${NVML13}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML13}.zip ${CMAKE_SOURCE_DIR}/nvml-${NVML13}.zip
			EXPECTED_HASH SHA256=4b020df4af1a92e3d0baca8194e6877c9811f3d0c4c10e70595a109ebc794818)
		message(STATUS "Downloading NVML ${NVML13} done")
	endif()

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-1.3)
		execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${CMAKE_SOURCE_DIR}/nvml-${NVML13}.zip
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
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

	add_library(pmemobj_convert_13_to_14_o OBJECT ${SOURCES_13}
		pmemobj_convert_1.3_to_1.4.c)

	target_compile_definitions(pmemobj_convert_13_to_14_o PRIVATE SRCVERSION="${NVML13}")
	target_compile_definitions(pmemobj_convert_13_to_14_o PRIVATE USE_LIBDL)
	target_compile_definitions(pmemobj_convert_13_to_14_o PRIVATE _PMEMOBJ_INTRNL)

	target_include_directories(pmemobj_convert_13_to_14_o PRIVATE nvml-1.3/src/include)
	target_include_directories(pmemobj_convert_13_to_14_o PRIVATE nvml-1.3/src/libpmemobj)
	target_include_directories(pmemobj_convert_13_to_14_o PRIVATE nvml-1.3/src/common)
	target_include_directories(pmemobj_convert_13_to_14_o PRIVATE ${PMEM_INCLUDE_DIRS})

	add_library(pmemobj_convert_13_to_14_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_13_to_14_o>)
	target_link_libraries(pmemobj_convert_13_to_14_shared PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_convert_13_to_14_shared PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemobj_convert_13_to_14_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_convert_13_to_14_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert_1.3_to_1.4.map)
	# strip unneeded symbols, requires -fdata-sections -ffunction-sections
	target_link_libraries(pmemobj_convert_13_to_14_shared PRIVATE -Wl,--gc-sections)
	set_target_properties(pmemobj_convert_13_to_14_shared PROPERTIES OUTPUT_NAME pmemobj_convert_13_to_14)

	install(TARGETS pmemobj_convert_13_to_14_shared
		DESTINATION ${CMAKE_INSTALL_LIBDIR}/pmdk-convert/)

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

endif(BUILD_CONVERT_13_TO_14)

###################################################### 1.2

if(BUILD_CONVERT_12_TO_13)

	require_libpmem(1.2)

	set(NVML12 1.2.3)

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-${NVML12}.zip)
		message(STATUS "Downloading NVML ${NVML12}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML12}.zip ${CMAKE_SOURCE_DIR}/nvml-${NVML12}.zip
			EXPECTED_HASH SHA256=a6491d2cea750370ed534bdbc2f4d90a7eec61171da18f7034db97852fa8e3fc)
		message(STATUS "Downloading NVML ${NVML12} done")
	endif()

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-1.2)
		execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${CMAKE_SOURCE_DIR}/nvml-${NVML12}.zip
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
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

	add_library(pmemobj_convert_12_to_13_o OBJECT ${SOURCES_12}
		pmemobj_convert_1.2_to_1.3.c
		nvml-1.2/src/libpmemblk/btt.c
		nvml-1.2/src/tools/pmempool/common.c)

	target_compile_definitions(pmemobj_convert_12_to_13_o PRIVATE SRCVERSION="${NVML12}")
	target_compile_definitions(pmemobj_convert_12_to_13_o PRIVATE USE_LIBDL)

	target_include_directories(pmemobj_convert_12_to_13_o PRIVATE nvml-1.2/src/include)
	target_include_directories(pmemobj_convert_12_to_13_o PRIVATE nvml-1.2/src/libpmemobj)
	target_include_directories(pmemobj_convert_12_to_13_o PRIVATE nvml-1.2/src/libpmemlog)
	target_include_directories(pmemobj_convert_12_to_13_o PRIVATE nvml-1.2/src/libpmemblk)
	target_include_directories(pmemobj_convert_12_to_13_o PRIVATE nvml-1.2/src/common)
	target_include_directories(pmemobj_convert_12_to_13_o PRIVATE ${PMEM_INCLUDE_DIRS})

	add_library(pmemobj_convert_12_to_13_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_12_to_13_o>)
	target_link_libraries(pmemobj_convert_12_to_13_shared PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_convert_12_to_13_shared PRIVATE ${CMAKE_DL_LIBS})
	target_link_libraries(pmemobj_convert_12_to_13_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_convert_12_to_13_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert_1.2_to_1.3.map)
	# strip unneeded symbols, requires -fdata-sections -ffunction-sections
	target_link_libraries(pmemobj_convert_12_to_13_shared PRIVATE -Wl,--gc-sections)

	set_target_properties(pmemobj_convert_12_to_13_shared PROPERTIES OUTPUT_NAME pmemobj_convert_12_to_13)

	install(TARGETS pmemobj_convert_12_to_13_shared
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

endif(BUILD_CONVERT_12_TO_13)

###################################################### 1.1

if(BUILD_CONVERT_11_TO_12)

	require_libpmem(1.1)

	set(NVML11 1.1)

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-${NVML11}.zip)
		message(STATUS "Downloading NVML ${NVML11}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML11}.zip ${CMAKE_SOURCE_DIR}/nvml-${NVML11}.zip
			EXPECTED_HASH SHA256=7ec5d967653de86ac502793ed58d951ecd5643e06d84568d659cf4bdee946bd7)
		message(STATUS "Downloading NVML ${NVML11} done")
	endif()

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-1.1)
		execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${CMAKE_SOURCE_DIR}/nvml-${NVML11}.zip
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
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

	add_library(pmemobj_convert_11_to_12_o OBJECT ${SOURCES_11}
		pmemobj_convert_1.1_to_1.2.c
		nvml-1.1/src/libpmemblk/btt.c
		nvml-1.1/src/tools/pmempool/common.c
		)

	target_compile_definitions(pmemobj_convert_11_to_12_o PRIVATE SRCVERSION="${NVML11}")

	target_include_directories(pmemobj_convert_11_to_12_o PRIVATE nvml-1.1/src/include)
	target_include_directories(pmemobj_convert_11_to_12_o PRIVATE nvml-1.1/src/libpmemobj)
	target_include_directories(pmemobj_convert_11_to_12_o PRIVATE nvml-1.1/src/libpmemlog)
	target_include_directories(pmemobj_convert_11_to_12_o PRIVATE nvml-1.1/src/libpmemblk)
	target_include_directories(pmemobj_convert_11_to_12_o PRIVATE nvml-1.1/src/common)
	target_include_directories(pmemobj_convert_11_to_12_o PRIVATE ${PMEM_INCLUDE_DIRS})

	add_library(pmemobj_convert_11_to_12_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_11_to_12_o>)
	target_link_libraries(pmemobj_convert_11_to_12_shared PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_convert_11_to_12_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_convert_11_to_12_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert_1.1_to_1.2.map)
	# strip unneeded symbols, requires -fdata-sections -ffunction-sections
	target_link_libraries(pmemobj_convert_11_to_12_shared PRIVATE -Wl,--gc-sections)

	set_target_properties(pmemobj_convert_11_to_12_shared PROPERTIES OUTPUT_NAME pmemobj_convert_11_to_12)

	install(TARGETS pmemobj_convert_11_to_12_shared
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

endif(BUILD_CONVERT_11_TO_12)

###################################################### 1.0

if(BUILD_CONVERT_10_TO_11)

	require_libpmem(1.0)

	set(NVML10 1.0)

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-${NVML10}.zip)
		message(STATUS "Downloading NVML ${NVML10}")
		file(DOWNLOAD https://github.com/pmem/pmdk/archive/${NVML10}.zip ${CMAKE_SOURCE_DIR}/nvml-${NVML10}.zip
			EXPECTED_HASH SHA256=944eef87b18a409cb953cf81b07e2f9d49ef9db621e0d5f27acbb2628c0bc4d3)
		message(STATUS "Downloading NVML ${NVML10} done")
	endif()

	if(NOT EXISTS ${CMAKE_SOURCE_DIR}/nvml-1.0)
		execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${CMAKE_SOURCE_DIR}/nvml-${NVML10}.zip
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
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

	add_library(pmemobj_convert_10_to_11_o OBJECT ${SOURCES_10}
		pmemobj_convert_1.0_to_1.1.c
		nvml-1.0/src/tools/pmempool/common.c)

	target_compile_definitions(pmemobj_convert_10_to_11_o PRIVATE SRCVERSION="${NVML10}")

	target_include_directories(pmemobj_convert_10_to_11_o PRIVATE nvml-1.0/src/include)
	target_include_directories(pmemobj_convert_10_to_11_o PRIVATE nvml-1.0/src/libpmemobj)
	target_include_directories(pmemobj_convert_10_to_11_o PRIVATE nvml-1.0/src/libpmemlog)
	target_include_directories(pmemobj_convert_10_to_11_o PRIVATE nvml-1.0/src/libpmemblk)
	target_include_directories(pmemobj_convert_10_to_11_o PRIVATE nvml-1.0/src/common)
	target_include_directories(pmemobj_convert_10_to_11_o PRIVATE ${PMEM_INCLUDE_DIRS})

	add_library(pmemobj_convert_10_to_11_shared SHARED $<TARGET_OBJECTS:pmemobj_convert_10_to_11_o>)
	target_link_libraries(pmemobj_convert_10_to_11_shared PRIVATE ${PMEM_LIBRARIES})
	target_link_libraries(pmemobj_convert_10_to_11_shared PRIVATE ${CMAKE_THREAD_LIBS_INIT})
	target_link_libraries(pmemobj_convert_10_to_11_shared PRIVATE -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/pmemobj_convert_1.0_to_1.1.map)
	# strip unneeded symbols, requires -fdata-sections -ffunction-sections
	target_link_libraries(pmemobj_convert_10_to_11_shared PRIVATE -Wl,--gc-sections)

	set_target_properties(pmemobj_convert_10_to_11_shared PROPERTIES OUTPUT_NAME pmemobj_convert_10_to_11)

	install(TARGETS pmemobj_convert_10_to_11_shared
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

endif(BUILD_CONVERT_10_TO_11)

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
