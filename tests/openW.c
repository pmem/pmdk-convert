// SPDX-License-Identifier: BSD-3-Clause
/* Copyright 2018, Intel Corporation */

#include <stdio.h>
#include <stdlib.h>

#include "libpmemobj.h"

int
wmain(int argc, wchar_t *argv[])
{
	if (argc < 2) {
		fprintf(stderr, "Usage: %S pool_file\n", argv[0]);
		exit(1);
	}

	PMEMobjpool *pop = pmemobj_openW(argv[1], L"test");
	if (!pop) {
		fprintf(stderr, "pmemobj_open failed: %S\n",
				pmemobj_errormsgW());
		exit(2);
	}

	pmemobj_close(pop);
	return 0;
}
