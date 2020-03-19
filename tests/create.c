// SPDX-License-Identifier: BSD-3-Clause
/* Copyright 2018, Intel Corporation */

#include <stdio.h>
#include <stdlib.h>

#include "libpmemobj.h"

int
main(int argc, char *argv[])
{
	if (argc < 2) {
		fprintf(stderr, "Usage: %s pool_file [size in MB]\n", argv[0]);
		exit(1);
	}

	size_t sz = 0;
	if (argc >= 3)
		sz = (size_t)atoi(argv[2]) * 1024 * 1024;

	PMEMobjpool *pop = pmemobj_create(argv[1], "test", sz, 0755);
	if (!pop) {
		fprintf(stderr, "pmemobj_create failed: %s\n",
				pmemobj_errormsg());
		exit(2);
	}

	pmemobj_close(pop);
	return 0;
}
