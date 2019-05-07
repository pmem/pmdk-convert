/*
 * Copyright 2014-2019, Intel Corporation
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

#include <assert.h>
#include <endian.h>
#include <errno.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>

#include "libpmem.h"

#include "pmemobj_convert.h"
#include "libpmemobj.h"
#include "common.h"
#include "output.h"

/*
 * outv_err_vargs -- print error message
 */
void
outv_err_vargs(const char *fmt, va_list ap)
{
	fprintf(stderr, "error: ");
	vfprintf(stderr, fmt, ap);
	if (!strchr(fmt, '\n'))
		fprintf(stderr, "\n");
}

/*
 * outv_err -- print error message
 */
void
outv_err(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	outv_err_vargs(fmt, ap);
	va_end(ap);
}

/*
 * pmemobj_convert - convert a pool to the next layout version
 */
const char *
pmemobj_convert(const char *path, unsigned force)
{
	/* open the pool and perform recovery */
	PMEMobjpool *pop = pmemobj_open(path, NULL);
	if (!pop)
		return pmemobj_errormsg();

	/* now recovery state is clean, so we can zero it out */
	struct lane_layout *lanes =
			(struct lane_layout *)((char *)pop + pop->lanes_offset);
	memset(lanes, 0, pop->nlanes * sizeof(struct lane_layout));
	pmemobj_persist(pop, lanes, pop->nlanes * sizeof(struct lane_layout));

	pmemobj_close(pop);

	const char *ret = NULL;
	struct pmem_pool_params params;
	if (pmem_pool_parse_params(path, &params, 1))
		return get_error("cannot open pool: %s", strerror(errno));

	struct pool_set_file *psf = pool_set_file_open(path, 0, 1);
	if (psf == NULL) {
		return get_error("pool_set_file_open failed: %s",
				strerror(errno));
	}

	void *addr = pool_set_file_map(psf, 0);
	if (addr == NULL) {
		ret = "mapping file failed";
		goto pool_set_close;
	}

	struct pool_hdr *phdr = addr;
	uint32_t m = le32toh(phdr->major);
	if (m != OBJ_FORMAT_MAJOR) {
		/* shouldn't be possible, because pool open succeeded earlier */
		ret = get_error("invalid pool version: %d", m);
		goto pool_set_close;
	}

	if (pool_set_file_map_headers(psf, 0, POOL_HDR_SIZE)) {
		ret = get_error("mapping headers failed: %s", strerror(errno));
		goto pool_set_close;
	}

	/* need to update every header of every part */
	for (unsigned r = 0; r < psf->poolset->nreplicas; ++r) {
		struct pool_replica *rep = psf->poolset->replica[r];
		for (unsigned p = 0; p < rep->nparts; ++p) {
			struct pool_set_part *part = &rep->part[p];

			struct pool_hdr *hdr = part->hdr;
			assert(hdr->major == OBJ_FORMAT_MAJOR);
			hdr->major = htole32(OBJ_FORMAT_MAJOR + 1);
			util_checksum(hdr, sizeof(*hdr), &hdr->checksum, 1);
			pmem_msync(hdr, sizeof(struct pool_hdr));
		}
	}

	pool_set_file_unmap_headers(psf);

pool_set_close:
	pool_set_file_close(psf);

	return ret;
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
