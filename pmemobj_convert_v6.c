// SPDX-License-Identifier: BSD-3-Clause
/* Copyright 2019, Intel Corporation */

#include <errno.h>

#include "libpmemobj.h"
#include "pmemobj_convert.h"

/*
 * pmemobj_convert - convert a pool to the next layout version
 */
const char *
pmemobj_convert(const char *path, unsigned force)
{
	errno = ENOTSUP;
	return "Conversion to layout v7 is not implemented yet";
}

/*
 * pmemobj_convert_try_open - return if a pool is openable by this pmdk verison
 */
int
pmemobj_convert_try_open(char *path)
{
	PMEMobjpool *pop = pmemobj_open(path, NULL);

	if (!pop)
		return 1;

	pmemobj_close(pop);
	return 0;
}
