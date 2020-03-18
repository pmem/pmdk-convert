# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018, Intel Corporation

include(CheckCCompilerFlag)

# Disables optimizations for target in release mode
function(disable_optimization target)
	check_c_compiler_flag(-O0 OPTIMIZATION_FLAG)
	if(${OPTIMIZATION_FLAG})
		target_compile_options(${target} PRIVATE "$<$<CONFIG:RELEASE>:-O0>")
		target_compile_options(${target} PRIVATE
								"$<$<CONFIG:RELWITHDEBINFO>:-O0>")
		target_compile_options(${target} PRIVATE "$<$<CONFIG:MINSIZEREL>:-O0>")
	endif()
endfunction()
