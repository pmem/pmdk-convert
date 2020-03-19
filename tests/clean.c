// SPDX-License-Identifier: BSD-3-Clause
/* Copyright 2018, Intel Corporation */

#include <stdio.h>
#include <stdlib.h>

#include <libpmempool.h>

int
main(int argc, char *argv[])
{
	if (argc < 2) {
		fprintf(stderr, "Usage: %s pool_file\n", argv[0]);
		exit(1);
	}

	const char *path = argv[1];
	int ret = pmempool_rm(path, 0);
	if (ret) {
		fprintf(stderr, "pmempool_rm failed: %s\n",
				pmempool_errormsg());
		exit(1);
	}

	return 0;
}
