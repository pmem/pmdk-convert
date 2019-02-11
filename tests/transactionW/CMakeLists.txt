set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -TP") #changing the flag for transaction windows project

if(BUILD_CONVERT_V1)
		add_executable(transaction_10 transactionW.c)
		# disable_optimization(transaction_10)
		target_include_directories(transaction_10 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.0/src/include)
		target_link_libraries(transaction_10 PRIVATE libpmem-convert)
		target_link_libraries(transaction_10 PRIVATE pmemobj_10)
	endif()

	if(BUILD_CONVERT_V2)
		add_executable(transaction_11 transactionW.c)
		# disable_optimization(transaction_11)
		target_include_directories(transaction_11 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.1/src/include)
		target_link_libraries(transaction_11 PRIVATE libpmem-convert)
		target_link_libraries(transaction_11 PRIVATE pmemobj_11)
	endif()

	if(BUILD_CONVERT_V3)
		add_executable(transaction_12 transactionW.c)
		# disable_optimization(transaction_12)
		target_include_directories(transaction_12 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.2/src/include)
		target_link_libraries(transaction_12 PRIVATE libpmem-convert)
		target_link_libraries(transaction_12 PRIVATE pmemobj_12)
	endif()

	if(BUILD_13)

		add_executable(transaction_13 transactionW.c)
		# disable_optimization(transaction_13)
		target_include_directories(transaction_13 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.3/src/include)
		target_link_libraries(transaction_13 PRIVATE libpmem-convert)
		target_link_libraries(transaction_13 PRIVATE pmemobj_13)
	endif()

	if(BUILD_CONVERT_V4)
		add_executable(transaction_14 transactionW.c)
		# disable_optimization(transaction_14)
		target_include_directories(transaction_14  PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.4/src/include)
		target_link_libraries(transaction_14 PRIVATE libpmem-convert)
		target_link_libraries(transaction_14 PRIVATE pmemobj_14)
		
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
		add_executable(transaction_15 transactionW.c)
		# disable_optimization(transaction_15)
		target_include_directories(transaction_15 PRIVATE ${CMAKE_SOURCE_DIR}/nvml-1.5/src/include)
		target_link_libraries(transaction_15 PRIVATE libpmem-convert)
		target_link_libraries(transaction_15 PRIVATE pmemobj_15)
		
		add_custom_command(TARGET transaction_15 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE:pmemobj_15>
			$<TARGET_FILE_DIR:transaction_15>)

		add_custom_command(TARGET transaction_15 POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different
			$<TARGET_FILE_DIR:pmemobj_15>/libpmem-convert.dll
			$<TARGET_FILE_DIR:transaction_15>)
		
	endif()