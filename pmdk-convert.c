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

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <limits.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#ifndef _WIN32
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#endif
#define MINVERSION ((MIN_VERSION_MAJOR) * 10 + (MIN_VERSION_MINOR))
#define MAXVERSION ((MAX_VERSION_MAJOR) * 10 + (MAX_VERSION_MINOR))

#include "pmemobj_convert.h"

typedef const char *(*conv)(const char *, unsigned);
typedef int (*try_op)(const char *);
static char *AppName;

enum {
	NOT_ENOUGH_ARGS = 1,
	UNKNOWN_FLAG = 2,
	UNKNOWN_ARG = 3,
	FROM_EXCLUSIVE = 4,
	TO_EXCLUSIVE = 5,
	FROM_INVALID = 6,
	TO_INVALID = 7,
	FROM_LAYOUT_INVALID = 8,
	TO_LAYOUT_INVALID = 9,
	NO_POOL = 10,
	POOL_DETECTION = 11,
	UNSUPPORTED_FROM = 12,
	UNSUPPORTED_TO = 13,
	BACKWARD_CONVERSION = 14,
	CONVERT_FAILED = 15,
	CREATE_VERSION_STR_FAILED = 16,
	OPEN_LIB_FAILED = 17,
	DLSYM_FAILED = 18,
	FREELIB_FAILED = 19,
	OPEN_FAILED = 20,
	STAT_FAILED = 21,
	MMAP_FAILED = 22,
	REMOTE = 23,
	ARG_CONVERSION_FAILED = 24,
	STDIN_EOF = 25,
};

#define ARRAY_LENGTH(array) (sizeof((array)) / sizeof((array)[0]))
#define CHECK_VERSION(x) (MINVERSION <= (x)) && ((x) <= MAXVERSION)
static const struct {
	int pmdk_version;
	int layout;
} Layouts[] = {
#if CHECK_VERSION(10)
	{10, 1},
#endif
#if CHECK_VERSION(11)
	{11, 2},
#endif
#if CHECK_VERSION(12)
	{12, 3},
#endif
#if CHECK_VERSION(13)
	{13, 4},
#endif
#if CHECK_VERSION(14)
	{14, 4},
#endif
#if CHECK_VERSION(15)
	{15, 5},
#endif
#if CHECK_VERSION(16)
	{16, 5},
#endif
#if CHECK_VERSION(17)
	{17, 6},
#endif
};

#ifndef WIN32
#include <dlfcn.h>
#include <libgen.h>
/*
 * open_lib -- opens conversion plugin
 */
static void *
open_lib(const char *name)
{
	char *argv0copy = strdup(AppName);
	char *dir = dirname(argv0copy);
	char path[2][strlen(dir) + strlen(name) + strlen(LIBDIR) + 100];
	char *reason0 = NULL;

	sprintf(path[0], "%s/%s.so", dir, name);
	void *lib = dlopen(path[0], RTLD_NOW);
	if (!lib) {
		reason0 = strdup(dlerror());
		if (reason0 == NULL) {
			fprintf(stderr, "strdup failed");
			exit(OPEN_LIB_FAILED);
		}
		sprintf(path[1], "%s/pmdk-convert/%s.so", LIBDIR, name);
		lib = dlopen(path[1], RTLD_NOW);
	}

	if (!lib)
		fprintf(stderr, "dlopen failed:\n%s: %s\n%s: %s\n", path[0],
				reason0, path[1], dlerror());
	free(argv0copy);
	free(reason0);
	if (!lib)
		exit(OPEN_LIB_FAILED);
	return lib;
}
/*
 * get_fun -- returns function from library
 */
static void *
get_fun(void * library, const char *function)
{
	void *_fun = dlsym(library, function);
	if (!_fun) {
		fprintf(stderr, "dlsym failed: %s\n", dlerror());
		exit(DLSYM_FAILED);
	}
	return _fun;
}

/*
 * close_lib -- closes conversion plugin
 */
static void
close_lib(void *lib)
{
	dlclose(lib);
}

#else
#include <windows.h>
/*
 * dirname - windows implementation of dirname function
 *	based on windows/include/unistd.h from pmdk repo
 */
static char *
dirname(char *path)
{
	if (path == NULL)
		return ".";

	size_t len = strlen(path);
	if (len == 0)
		return ".";

	char *end = path + len;

	/* strip trailing forslashes and backslashes */
	while ((--end) > path) {
		if (*end != '\\' && *end != '/') {
			*(end + 1) = '\0';
			break;
		}
	}

	/* strip basename */
	while ((--end) > path) {
		if (*end == '\\' || *end == '/') {
			*end = '\0';
			break;
		}
	}

	if (end != path)
		return path;

	/* handle edge cases */
	if (*end == '\\' || *end == '/') {
		*(end + 1) = '\0';
	} else {
		*end++ = '.';
		*end = '\0';
	}

	return path;
}

/*
 * open_lib -- opens conversion plugin
 */
static void *
open_lib(const char *name)
{
	char *argv0copy = strdup(AppName);
	char *dir = dirname(argv0copy);
	char *path = malloc(strlen(dir) + strlen(name) + 100);

	if (path == NULL) {
		fprintf(stderr, "malloc failed");
		exit(OPEN_LIB_FAILED);
	}

	sprintf(path, "%s/%s.dll", dir, name);
	void *lib = LoadLibrary(path);

	if (!lib)
		fprintf(stderr, "LoadLibrary(%s) failed: %d",
			path, GetLastError());

	free(argv0copy);
	free(path);

	if (!lib)
		exit(OPEN_LIB_FAILED);

	return lib;
}

/*
 * get_fun -- returns function from library
 */
static void *
get_fun(void *library, const char *function)
{
	void *_fun = GetProcAddress(library, function);
	if (!_fun) {
		fprintf(stderr, "GetProcAddress failed: %d\n", GetLastError());
		exit(DLSYM_FAILED);
	}
	return _fun;
}

/*
 * close_lib -- closes conversion plugin
 */
static void
close_lib(void *lib)
{
	if (!FreeLibrary(lib))
		exit(FREELIB_FAILED);
}

/*
 * util_toUTF8 -- allocating conversion from wide char string to UTF8
 */
static char *
util_toUTF8(const wchar_t *wstr)
{
	int size = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, wstr, -1,
		NULL, 0, NULL, NULL);
	if (size == 0)
		goto err;

	char *str = malloc(size * sizeof(char));
	if (str == NULL)
		goto out;

	if (WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, wstr, -1, str,
			size, NULL, NULL) == 0) {
		free(str);
		goto err;
	}

out:
	return str;

err:
	errno = EINVAL;
	return NULL;
}

#endif


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

/*
 * conv_layout_version -- converts layout version string to number
 */
static int
conv_layout_version(const char *strver)
{
	char *end;
	errno = 0;
	unsigned long long retval = strtoull(strver, &end, 10);
	if (*end != '\0')
		return -1;

	if (errno != 0)
		return -1;

	if (retval > INT_MAX)
		return -1;

	return (int)retval;
}

/*
 * RUN_FUNCTION -- runs function from a given library
 */
#define RUN_FUNCTION(library, function, type, ret, ...)			\
	do {								\
		type _fun = get_fun(library, function);			\
									\
		ret = _fun(__VA_ARGS__);				\
	} while (0)

/*
 * find_layout_version -- returns a layout version for a given PMDK version
 */
static int
find_layout_version(int version)
{
	for (unsigned i = 0; i < ARRAY_LENGTH(Layouts); i++) {
		if (Layouts[i].pmdk_version == version)
			return Layouts[i].layout;
	}

	return -1;
}

/*
 * verify_layout_version -- checks if a given layout version is supported by
 *     pmdk-convert
 */
static int
verify_layout_version(int layout_version)
{
	for (unsigned i = 0; i < ARRAY_LENGTH(Layouts); i++) {
		if (Layouts[i].layout == layout_version)
			return 0;
	}

	return -1;
}
/*
 * create_pmdk_version_str -- returns string in format:
 *      "v<layout_version> (PMDK <MAJOR1>.<MINOR1>, PMDK <MAJOR2>.<MINOR2>)"
 *      for a given layout version.
 */
static int
create_pmdk_version_str(int layout_version, char *str, size_t len)
{
	*str = '\0';
	int ret = snprintf(str, len, "v%d (", layout_version);

	if (ret <= 0)
		return -1;

	str += ret;
	len -= (unsigned)ret;

	for (unsigned i = 0; i < ARRAY_LENGTH(Layouts); i++) {
		if (Layouts[i].layout != layout_version)
			continue;

		int major = Layouts[i].pmdk_version / 10;
		int minor = Layouts[i].pmdk_version % 10;
		int ret = snprintf(str, len, "PMDK %d.%d, ", major, minor);

		if (ret <= 0)
			return -1;

		str += ret;
		len -= (unsigned)ret;
	}

	if (*(str - 2) != ',' && *(str - 1) != ' ')
		return -1; /* should never happen */

	/* s/ ,/)/ */
	*(str - 2) = ')';
	*(str - 1) = '\0';

	return 0;
}

/*
 * detect_layout_version -- detects a layout version for a given pool
 */
static int
detect_layout_version(const char *path)
{
	int from = find_layout_version(MINVERSION);
	int to = find_layout_version(MAXVERSION);

	for (int ver = from; ver <= to; ver++) {
		char lib_name[100];
		int ret;
		sprintf(lib_name, "pmemobj_convert_v%d", ver);
		void *lib = open_lib(lib_name);
		RUN_FUNCTION(lib, "pmemobj_convert_try_open",
			try_op, ret, path);
		close_lib(lib);
		if (!ret)
			return ver;
	}

	return -1;
}

/*
 * list_supported_pools -- prints supported layouts(and PMDK versions) by
 *     pmdk-convert
 */
static void
list_supported_pools()
{
	char line[256];
	int prev = 0;
	printf("Supported pools layouts (corresponding PMDK versions)\n");
	for (unsigned i = 0; i < ARRAY_LENGTH(Layouts); i++) {
		if (prev == Layouts[i].layout)
			continue;
		prev = Layouts[i].layout;
		if (create_pmdk_version_str(Layouts[i].layout, line, 256))
			exit(CREATE_VERSION_STR_FAILED);
		printf("    %s\n", line);
	}
}

/*
 * print_usage -- prints usage message
 */
static void
print_usage()
{
	printf(
		"Usage: pmdk-convert [--version] [--help] [--no-warning] --from=<version> --to=<version> <pool>\n");
}

/*
 * print_version -- prints version message
 */
static void
print_version()
{
	printf("pmdk-convert %d.%d", VERSION_MAJOR, VERSION_MINOR);

	if (VERSION_PATCH)
		printf(".%d", VERSION_PATCH);

	if (strlen(VERSION_PRERELEASE) > 0)
		printf("-%s", VERSION_PRERELEASE);

	printf("\n");
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
	printf(
		"  -f, --from=version         convert from specified PMDK version\n");
	printf(
		"  -t, --to=version           convert to specified PMDK version\n");
	printf(
		"  -F, --from-layout=version  convert from specified layout version\n");
	printf(
		"  -T, --to-layout=version    convert to specified layout version\n");
	printf(
		"  -X, --force-yes=[question] reply positively to specified question\n");
	printf("                             possible questions:\n");
	printf("                             - fail-safety\n");
	printf("                             - 1.2-pmemmutex\n");
	printf("\n");
	list_supported_pools();
}

#define POOLSET_DESC "PMEMPOOLSET\n"
#define REPLICA_DESC "\nREPLICA"

static int
check_remote(const char *path)
{
#ifdef _WIN32
	return 0;
#else
	int fd = open(path, O_RDONLY);

	if (fd < 0) {
		fprintf(stderr, "open failed: %s\n", strerror(errno));
		exit(OPEN_FAILED);
	}

	struct stat st;
	if (fstat(fd, &st)) {
		fprintf(stderr, "fstat failed: %s\n", strerror(errno));
		close(fd);
		exit(STAT_FAILED);
	}

	if (S_ISCHR(st.st_mode)) {
		close(fd);
		return 0; /* char device(DEVDAX) is not a poolset file */
	}

	size_t map_size = (size_t)st.st_size;
	const char *poolset = mmap(NULL, map_size, PROT_READ,
		MAP_PRIVATE | MAP_NORESERVE, fd, 0);

	if (poolset == MAP_FAILED) {
		fprintf(stderr, "mmap failed: %s\n", strerror(errno));
		close(fd);
		exit(MMAP_FAILED);
	}

	close(fd);
	if (memcmp(poolset, POOLSET_DESC, sizeof(POOLSET_DESC) - 1) != 0)
		return 0; /* not a poolset */

	for (unsigned long i = 0; i < map_size - sizeof(REPLICA_DESC) - 1;
			i++) {
		if (memcmp(poolset + i, REPLICA_DESC,
				sizeof(REPLICA_DESC) - 1) == 0) {
			i += sizeof(REPLICA_DESC) - 1;

			/* check if it is not REPLCA[^\s] */
			if (!isblank(poolset[i]))
				continue;

			for (; i < map_size; i++) {
				if (poolset[i] == '\n')
					break;

				if (isblank(poolset[i]) == 0 &&
						poolset[i] != '#')
					return 1;
			}
		}
	}

	return 0;
#endif
}

int
main(int argc, char *argv[])
{
#ifdef _WIN32
	wchar_t **wargv = CommandLineToArgvW(GetCommandLineW(), &argc);
	for (int i = 0; i < argc; i++) {
		argv[i] = util_toUTF8(wargv[i]);
		if (argv[i] == NULL) {
			for (i--; i >= 0; i--)
				free(argv[i]);
			fprintf(stderr,
				"Error during arguments conversion %s\n",
				strerror(errno));
			exit(ARG_CONVERSION_FAILED);
		}
	}
#endif
	const char *path;
	int from = 0;
	int to = 0;
	int from_layout = 0;
	int to_layout = 0;
	unsigned force = 0;
	AppName = argv[0];

	if (argc < 2) {
		print_usage();
		exit(NOT_ENOUGH_ARGS);
	}

	/*
	 * long_options -- pmempool command line arguments
	 */
	static const struct option long_options[] = {
		{"version",	no_argument,		NULL, 'V'},
		{"help",	no_argument,		NULL, 'h'},
		{"from",	required_argument,	NULL, 'f'},
		{"to",		required_argument,	NULL, 't'},
		{"from-layout",	required_argument,	NULL, 'F'},
		{"to-layout",	required_argument,	NULL, 'T'},
		{"force-yes",	required_argument,	NULL, 'X'},
		{NULL,		0,			NULL, 0 },
	};

	int opt;
	int option_index;
	while ((opt = getopt_long(argc, argv, "Vhf:F:t:T:X:",
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
		case 'F':
			from_layout = conv_layout_version(optarg);
			break;
		case 'T':
			to_layout = conv_layout_version(optarg);
			break;
		case 'X':
			if (strcmp(optarg, "fail-safety") == 0)
				force |= QUEST_FAIL_SAFETY;
			else if (strcmp(optarg, "1.2-pmemmutex") == 0)
				force |= QUEST_12_PMEMMUTEX;
			else {
				fprintf(stderr, "unknown parameter %s\n",
						optarg);
				exit(UNKNOWN_FLAG);
			}
			break;
		default:
			print_usage();
			exit(UNKNOWN_ARG);
		}
	}

	if (from != 0 && from_layout != 0) {
		fprintf(stderr,
			"\"from\" and \"from-layout\" parameters are exclusive.\n");
		print_usage();
		exit(FROM_EXCLUSIVE);
	}

	if (to != 0 && to_layout != 0) {
		fprintf(stderr,
			"\"to\" and \"to-layout\" parameters are exclusive.\n");
		print_usage();
		exit(TO_EXCLUSIVE);
	}

	if (from < 0) {
		fprintf(stderr,
			"Invalid \"from\" version format [major.minor].\n");
		print_usage();
		exit(FROM_INVALID);
	}

	if (to < 0) {
		fprintf(stderr,
			"Invalid \"to\" version format [major.minor].\n");
		print_usage();
		exit(TO_INVALID);
	}

	if (from_layout < 0) {
		fprintf(stderr, "Invalid \"from-layout\" version.\n");
		print_usage();
		exit(FROM_LAYOUT_INVALID);
	}

	if (to_layout < 0) {
		fprintf(stderr, "Invalid \"to-layout\" version.\n");
		print_usage();
		exit(TO_LAYOUT_INVALID);
	}

	if (optind >= argc) {
		fprintf(stderr, "Missing pool argument.\n");
		exit(NO_POOL);
	}

	path = argv[optind];

	if (check_remote(path)) {
		fprintf(stderr,
			"Remote replication is not supported.\n"
			"Please use pmempool transform to remove remote replica and then use pmdk-convert.\n");
		exit(REMOTE);
	}

	void *pmem_convert = open_lib("libpmem-convert");

	if (from == 0) {
		if (from_layout == 0) {
			if ((from_layout = detect_layout_version(path)) < 0) {
				fprintf(stderr,
					"Cannot detect pool version.\n");
				exit(POOL_DETECTION);
			}
		} else {
			if (verify_layout_version(from_layout)) {
				fprintf(stderr,
					"Unsupported pool 'from-layout' version\n");
				exit(UNSUPPORTED_FROM);
			}
		}
	} else {
		from_layout = find_layout_version(from);
		if (from_layout == -1) {
			fprintf(stderr, "Unsupported pool 'from' version\n");
			exit(UNSUPPORTED_FROM);
		}
	}

	if (to == 0) {
		if (to_layout == 0) {
			to_layout = find_layout_version(MAXVERSION);
		} else {
			if (verify_layout_version(to_layout)) {
				fprintf(stderr,
					"Unsupported pool 'to-layout' version\n");
				exit(UNSUPPORTED_TO);
			}
		}
	} else {
		to_layout = find_layout_version(to);
		if (to_layout == -1) {
			fprintf(stderr, "Unsupported pool 'to' version\n");
			exit(UNSUPPORTED_TO);
		}
	}

	if (to_layout == from_layout) {
		printf(
			"The pool is in the requested layout verison, conversion is not needed");
		exit(0);
	}

	if (from_layout > to_layout) {
		fprintf(stderr, "Backward conversion is not implemented.\n");
		print_usage();
		exit(BACKWARD_CONVERSION);
	}

	printf(
		"This tool will update the pool to the specified layout version.\n"
		"This process is NOT fail-safe.\n"
		"Proceed only if the pool has been backed up or\n"
		"the risks are fully understood and acceptable.\n");

	if (!(force & QUEST_FAIL_SAFETY)) {
		printf(
			"Hit Ctrl-C now if you want to stop or Enter to continue.\n");
		if (getchar() == EOF) {
			fprintf(stderr, "EOF, aborting\n");
			exit(STDIN_EOF);
		}
	}

	char to_str[255];
	char from_str[255];

	if (create_pmdk_version_str(from_layout, from_str, 255))
		exit(CREATE_VERSION_STR_FAILED);

	if (create_pmdk_version_str(to_layout, to_str, 255))
		exit(CREATE_VERSION_STR_FAILED);

	printf("Starting conversion from %s to %s\n", from_str, to_str);

	for (int ver = from_layout; ver < to_layout; ++ver) {
		if (create_pmdk_version_str(ver, from_str, 255))
			exit(CREATE_VERSION_STR_FAILED);

		if (create_pmdk_version_str(ver + 1, to_str, 255))
			exit(CREATE_VERSION_STR_FAILED);

		printf("Converting from %s to %s... ", from_str, to_str);
		fflush(stdout);
		char lib_name[100];
		const char *msg;
		sprintf(lib_name, "pmemobj_convert_v%d", ver);
		void *lib = open_lib(lib_name);
		RUN_FUNCTION(lib, "pmemobj_convert", conv, msg, path, force);
		if (msg) {
			fprintf(stderr, "failed: %s (%s)\n",
				msg, strerror(errno));
			close_lib(lib);
			exit(CONVERT_FAILED);
		}
		close_lib(lib);
		printf("Done\n");
	}

	close_lib(pmem_convert);

#ifdef _WIN32
	for (int i = argc; i > 0; i--)
		free(argv[i - 1]);
#endif
	return 0;
}
