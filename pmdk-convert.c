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

#include <ctype.h>
#include <dlfcn.h>
#include <errno.h>
#include <getopt.h>
#include <libgen.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#define MINVERSION ((MIN_VERSION_MAJOR) * 10 + (MIN_VERSION_MINOR))
#define MAXVERSION ((MAX_VERSION_MAJOR) * 10 + (MAX_VERSION_MINOR))

#include "pmemobj_convert.h"

/*
 * open_lib -- opens conversion plugin
 */
static void *
open_lib(const char *argv0, const char *name)
{
	char *argv0copy = strdup(argv0);
	char *dir = dirname(argv0copy);
	char path[2][strlen(dir) + 100];
	char *reason0 = NULL;

	sprintf(path[0], "%s/%s", dir, name);
	void *lib = dlopen(path[0], RTLD_NOW);
	if (!lib) {
		reason0 = strdup(dlerror());
		sprintf(path[1], "%s/pmdk-convert/%s", LIBDIR, name);
		lib = dlopen(path[1], RTLD_NOW);
	}
	if (!lib)
		fprintf(stderr, "dlopen failed:\n%s: %s\n%s: %s\n", path[0],
				reason0, path[1], dlerror());
	free(argv0copy);
	free(reason0);
	return lib;
}

/*
 * print_usage -- prints usage message
 */
static void
print_usage()
{
	printf(
		"Usage: pmdk-covert [--version] [--help] [--no-warning] --from=<version> --to=<version> <pool>\n");
}

/*
 * print_version -- print version message
 */
static void
print_version()
{
	printf("pmdk-convert 1.4\n");
}

/*
 * print_help -- prints help message
 */
static void
print_help()
{
	print_usage();
	print_version();
	printf("\n");
	printf("Options:\n");
	printf("  -V, --version              display version\n");
	printf("  -h, --help                 display this help and exit\n");
	printf("  -f, --from=version         convert from specified version\n");
	printf("  -t, --to=version           convert to specified version\n");
	printf(
		"  -X, --force-yes=[question] reply positively to specified question\n");
	printf("                             possible questions:\n");
	printf("                             - fail-safety\n");
	printf("                             - 1.2-pmemmutex\n");
	printf("\n");
}

/*
 * conv_version -- converts version string from major.minor format to number
 * (major * 10 + minor)
 */
static int
conv_version(const char *strver)
{
	if (strlen(strver) != 3)
		return -1;
	if (strver[1] != '.')
		return -1;
	if (!isdigit(strver[0]))
		return -1;
	if (!isdigit(strver[2]))
		return -1;
	return (strver[0] - '0') * 10 + strver[2] - '0';
}

int
main(int argc, char *argv[])
{
	void *lib;
	char name[100];
	const char *(*conv)(const char *, unsigned);
	const char *path;
	int from = -2;
	int to = -2;
	unsigned force = 0;

	if (argc < 2) {
		print_usage();
		exit(1);
	}

	/*
	 * long_options -- pmempool command line arguments
	 */
	static const struct option long_options[] = {
		{"version",	no_argument,		NULL, 'V'},
		{"help",	no_argument,		NULL, 'h'},
		{"from",	required_argument,	NULL, 'f'},
		{"to",		required_argument,	NULL, 't'},
		{"force-yes",	required_argument,	NULL, 'X'},
		{NULL,		0,			NULL, 0 },
	};

	int opt;
	int option_index;
	while ((opt = getopt_long(argc, argv, "Vhf:t:X:",
			long_options, &option_index)) != -1) {
		switch (opt) {
		case 'V':
			print_version();
			exit(0);
		case 'h':
			print_help();
			exit(0);
		case 'f':
			from = conv_version(optarg);
			break;
		case 't':
			to = conv_version(optarg);
			break;
		case 'X':
			if (strcmp(optarg, "fail-safety") == 0)
				force |= QUEST_FAIL_SAFETY;
			else if (strcmp(optarg, "1.2-pmemmutex") == 0)
				force |= QUEST_12_PMEMMUTEX;
			else {
				fprintf(stderr, "unknown parameter %s\n",
						optarg);
				exit(11);
			}

			break;
		default:
			print_usage();
			exit(2);
		}
	}

	if (from < 0) {
		if (from == -1)
			fprintf(stderr,
				"Invalid \"from\" version format [major.minor].\n");
		print_usage();
		exit(3);
	}

	if (to < 0) {
		if (to == -1)
			fprintf(stderr,
				"Invalid \"to\" version format [major.minor].\n");
		print_usage();
		exit(4);
	}

	if (from < MINVERSION || to > MAXVERSION) {
		fprintf(stderr,
			"Conversion is possible only in <%d.%d, %d.%d> range.\n",
			MIN_VERSION_MAJOR, MIN_VERSION_MINOR,
			MAX_VERSION_MAJOR, MAX_VERSION_MINOR);
		print_usage();
		exit(5);
	}

	if (from > to) {
		fprintf(stderr, "Backward conversion is not implemented.\n");
		print_usage();
		exit(6);
	}

	if (optind >= argc) {
		fprintf(stderr, "Missing pool argument.\n");
		exit(7);
	}

	path = argv[optind];

	printf(
		"This tool will update the pool to the specified layout version.\n"
		"This process is NOT fail-safe.\n"
		"Proceed only if the pool has been backed up or\n"
		"the risks are fully understood and acceptable.\n");

	if (!(force & QUEST_FAIL_SAFETY)) {
		printf(
			"Hit Ctrl-C now if you want to stop or Enter to continue.\n");
		getchar();
	}

	for (int ver = from; ver < to; ++ver) {
		sprintf(name, "libpmemobj_convert_%d_to_%d.so", ver, ver + 1);
		lib = open_lib(argv[0], name);
		if (!lib)
			exit(8);

		sprintf(name, "pmemobj_convert_%d_to_%d", ver, ver + 1);
		conv = dlsym(lib, name);
		if (!conv) {
			fprintf(stderr, "dlsym failed: %s\n", dlerror());
			exit(9);
		}

		const char *msg = conv(path, force);
		if (msg) {
			fprintf(stderr, "%s failed: %s (%s)\n", name, msg,
					strerror(errno));
			exit(10);
		}

		dlclose(lib);
		printf(
			"Conversion from %d.%d to %d.%d has been completed successfully.\n",
				ver / 10, ver % 10, ver / 10, ver % 10 + 1);
	}

	return 0;
}
