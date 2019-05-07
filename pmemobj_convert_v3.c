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
#include <sys/mman.h>

#include "libpmem.h"

#include "pmemobj_convert.h"
#include "libpmemobj.h"
#include "set.h"
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
 * pool_set_file_unmap_headers -- unmap headers of each pool set part file
 */
static void
pool_set_file_unmap_headers(struct pool_set_file *file)
{
	if (!file->poolset)
		return;
	for (unsigned r = 0; r < file->poolset->nreplicas; r++) {
		struct pool_replica *rep = file->poolset->replica[r];
		for (unsigned p = 0; p < rep->nparts; p++) {
			struct pool_set_part *part = &rep->part[p];
			util_unmap_hdr(part);
		}
	}
}

/*
 * pool_set_file_map_headers -- map headers of each pool set part file
 */
static int
pool_set_file_map_headers(struct pool_set_file *file, int rdonly)
{
	if (!file->poolset)
		return -1;

	int flags = rdonly ? MAP_PRIVATE : MAP_SHARED;
	for (unsigned r = 0; r < file->poolset->nreplicas; r++) {
		struct pool_replica *rep = file->poolset->replica[r];
		for (unsigned p = 0; p < rep->nparts; p++) {
			struct pool_set_part *part = &rep->part[p];
			if (util_map_hdr(part, flags, 0)) {
				part->hdr = NULL;
				goto err;
			}
		}
	}

	return 0;
err:
	pool_set_file_unmap_headers(file);
	return -1;
}

struct pmemobjpool_13 {
	struct pool_hdr hdr;	/* memory pool header */

	/* persistent part of PMEMOBJ pool descriptor (2kB) */
	char layout[PMEMOBJ_MAX_LAYOUT];
	uint64_t lanes_offset;
	uint64_t nlanes;
	uint64_t heap_offset;
	uint64_t heap_size;
	unsigned char unused[OBJ_DSC_P_UNUSED]; /* must be zero */
	uint64_t checksum;	/* checksum of above fields */

	uint64_t root_offset;

	/* unique runID for this program run - persistent but not checksummed */
	uint64_t run_id;

	uint64_t root_size;

	/*
	 * These flags can be set from a conversion tool and are set only for
	 * the first recovery of the pool.
	 */
	uint64_t conversion_flags;

	char pmem_reserved[512]; /* must be zeroed */

	void *addr;		/* mapped region */
	/* other stuff, not neededed for anything in conversion */
};

static uint64_t
obj_get_root_size(struct pmemobjpool *pop)
{
	if (pop->root_offset == 0)
		return 0;

	uint64_t off = pop->root_offset - sizeof(struct oob_header);
	struct oob_header *hdr = (struct oob_header *)((uintptr_t)pop + off);

	return hdr->size & ~OBJ_INTERNAL_OBJECT_MASK;
}

static void
pmemobj_convert_persist(const void *addr, size_t size)
{
	/* device dax */
	pmem_persist(addr, size);
	/*
	 * fs dax / nonpmem, will fail for ddax, but it doesn't
	 * matter
	 */
	pmem_msync(addr, size);
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

	uint64_t root_size = obj_get_root_size(pop);

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

	if (psf->poolset->remote) {
		ret = get_error("Conversion of remotely replicated pools is "
			"currently not supported. Remove the replica first");
		goto pool_set_close;

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

	if (pool_set_file_map_headers(psf, 0)) {
		ret = get_error("mapping headers failed: %s", strerror(errno));
		goto pool_set_close;
	}

	/* need to update every header of every part */
	for (unsigned r = 0; r < psf->poolset->nreplicas; ++r) {
		struct pool_replica *rep = psf->poolset->replica[r];
		struct pool_set_part *part0 = &rep->part[0];
		struct pmemobjpool_13 *pop13 =
				(struct pmemobjpool_13 *)part0->addr;
		assert(memcmp(pop13->hdr.signature, "PMEMOBJ\0", 8) == 0);

		/*
		 * We don't have to rely on 1.3 recovery, because we already
		 * performed it using 1.2, so we can set conversion flags to 0.
		 */
		pop13->conversion_flags = 0;
		pmemobj_convert_persist(&pop13->conversion_flags,
				sizeof(pop13->conversion_flags));

		/* zero out the pmem reserved part of the header */
		memset(pop13->pmem_reserved, 0, sizeof(pop13->pmem_reserved));
		pmemobj_convert_persist(pop13->pmem_reserved,
				sizeof(pop13->pmem_reserved));

		pop13->root_size = root_size;
		pmemobj_convert_persist(&pop13->root_size,
				sizeof(pop13->root_size));

		for (unsigned p = 0; p < rep->nparts; ++p) {
			struct pool_set_part *part = &rep->part[p];

			struct pool_hdr *hdr = part->hdr;
			assert(hdr->major == OBJ_FORMAT_MAJOR);
			hdr->major = htole32(OBJ_FORMAT_MAJOR + 1);
			util_checksum(hdr, sizeof(*hdr), &hdr->checksum, 1);
			pmemobj_convert_persist(hdr, sizeof(struct pool_hdr));
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
