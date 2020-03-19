// SPDX-License-Identifier: BSD-3-Clause
/* Copyright 2018-2019, Intel Corporation */

#ifndef PMEMOBJ_CONVERT_H
#define PMEMOBJ_CONVERT_H

#include <stdarg.h>
#include <stdio.h>

#define QUEST_FAIL_SAFETY  (1U << 0)
#define QUEST_12_PMEMMUTEX (1U << 1)

#ifdef __GNUC__
#define FORMAT_PRINTF(a, b) __attribute__((__format__(__printf__, (a), (b))))
#else
#define FORMAT_PRINTF(a, b)
#endif

/*
 * get_error -- returns formatted error message, using statically allocated
 * buffer
 */
FORMAT_PRINTF(1, 2)
static inline const char *
get_error(const char *format, ...)
{
	static char errstr[500];
	int ret;
	va_list ap;

	va_start(ap, format);
	ret = vsnprintf(errstr, sizeof(errstr), format, ap);
	va_end(ap);
	if (ret < 0)
		sprintf(errstr, "vsnsprintf error %d (%d)", ret, errno);
	else if (ret >= (int)sizeof(errstr))
		sprintf(errstr + sizeof(errstr) - 20, "... (truncated)");

	return errstr;
}


const char *pmemobj_convert(const char *path, unsigned force);
int pmemobj_convert_try_open(char *path);

#endif
