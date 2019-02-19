/*
 * Copyright 2018-2019, Intel Corporation
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in
 *       the documentation and/or other materials provided with the
 *       distribution.
 *
 *     * Neither the name of the copyright holder nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
