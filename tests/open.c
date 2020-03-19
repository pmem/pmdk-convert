// SPDX-License-Identifier: BSD-3-Clause
/* Copyright 2018, Intel Corporation */

#include <stdio.h>
#include <stdlib.h>

#include "libpmemobj.h"

int
main(int argc, char *argv[])
{
	if (argc < 2) {
		fprintf(stderr, "Usage: %s pool_file\n", argv[0]);
		exit(1);
	}

	PMEMobjpool *pop = pmemobj_open(argv[1], "test");
	if (!pop) {
		fprintf(stderr, "pmemobj_open failed: %s\n",
				pmemobj_errormsg());
		exit(2);
	}

	pmemobj_close(pop);
	return 0;
}
