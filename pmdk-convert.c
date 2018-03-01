/*
 * Copyright 2018, Intel Corporation
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

#include <dlfcn.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int
main(int argc, char *argv[])
{
	int ver;
	void *lib;
	char name[100];
	const char *(*conv)(const char *);
	const char *path;

	if (argc < 3) {
		fprintf(stderr, "not enough parameters\n");
		exit(99);
	}

	path = argv[1];
	ver = atoi(argv[2]);
	sprintf(name, "libpmemobj_convert_1%d_to_1%d.so", ver, ver + 1);
	lib = dlopen(name, RTLD_NOW);
	if (!lib) {
		fprintf(stderr, "dlopen failed: %s\n", dlerror());
		exit(1);
	}

	sprintf(name, "pmemobj_convert_1%d_to_1%d", ver, ver + 1);
	conv = dlsym(lib, name);
	if (!conv) {
		fprintf(stderr, "dlsym failed: %s\n", dlerror());
		exit(2);
	}

	const char *msg = conv(path);
	if (msg) {
		fprintf(stderr, "%s failed: %s (%s)\n", name, msg,
				strerror(errno));
		exit(3);
	}

	dlclose(lib);
}
