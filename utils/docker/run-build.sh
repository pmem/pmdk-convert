#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2016-2022, Intel Corporation

#
# run-build.sh - is called inside a Docker container; prepares the environment
#                and starts a build of pmdk-convert.
#

set -e
set -x

./prepare-for-build.sh

cd $WORKDIR
INSTALL_DIR=/tmp/pmdk-convert

mkdir $INSTALL_DIR

if [ -n "$CC" ]
then
	CC=gcc
fi

# -----------------------------------------
# Coverage
if [[ $COVERAGE -eq 1 ]] ; then
	mkdir build
	cd build

	CC=$CC \
	cmake .. -DCMAKE_BUILD_TYPE=$TEST_BUILD \
		-DTRACE_TESTS=1 \
		-DCMAKE_C_FLAGS=-coverage \
		-DTESTS_USE_FORCED_PMEM=ON

	make -j2
	ctest --output-on-failure
	bash <(curl -s https://codecov.io/bash) -c

	cd ..

	rm -r build
	exit 0
fi

# -----------------------------------------
# base build

mkdir $WORKDIR/build
cd $WORKDIR/build

CC=$CC \
cmake .. -DCMAKE_BUILD_TYPE=$TEST_BUILD \
	-DDEVELOPER_MODE=1 \
	-DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
	-DTRACE_TESTS=1 \
	-DTESTS_USE_FORCED_PMEM=ON

make -j2
ctest --output-on-failure

make install
make uninstall

cd ..
rm -r $WORKDIR/build

# -----------------------------------------
# different MINVERSION

mkdir $WORKDIR/build
cd $WORKDIR/build

CC=$CC \
cmake .. -DCMAKE_BUILD_TYPE=$TEST_BUILD \
	-DDEVELOPER_MODE=1 \
	-DMIN_VERSION=1.3 \
	-DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
	-DTRACE_TESTS=1 \
	-DTESTS_USE_FORCED_PMEM=ON

make -j2
ctest --output-on-failure

cd ..
rm -r $WORKDIR/build

# -----------------------------------------
# deb & rpm

mkdir $WORKDIR/build
cd $WORKDIR/build

CC=$CC \
cmake .. -DCMAKE_INSTALL_PREFIX=/usr \
		-DCPACK_GENERATOR=$PACKAGE_MANAGER \
		-DCMAKE_BUILD_TYPE=$TEST_BUILD \
		-DTRACE_TESTS=1 \
		-DTESTS_USE_FORCED_PMEM=ON

make -j2
ctest --output-on-failure

make package

if [ $PACKAGE_MANAGER = "deb" ]; then
	echo $USERPASS | sudo -S dpkg -i pmdk-convert*.deb
elif [ $PACKAGE_MANAGER = "rpm" ]; then
	echo $USERPASS | sudo -S rpm -i pmdk-convert*.rpm
fi

cp ./tests/create_10 /tmp
cp ./tests/open_17 /tmp
cp ./libpmem-convert.so /tmp
cp ./libpmemobj_10.so /tmp
cp ./libpmemobj_17.so /tmp

cd ..
rm -rf $WORKDIR/build

# Verify installed package
# pmdk-convert ...

rm -r $INSTALL_DIR
echo "Creating 1.0 pool"
LD_LIBRARY_PATH=/tmp:$LD_LIBRARY_PATH /tmp/create_10 /tmp/pool 16
echo "Converting 1.0 pool to the latest version"
pmdk-convert -X fail-safety -X 1.2-pmemmutex /tmp/pool
echo "Checking pool works with the latest version"
LD_LIBRARY_PATH=/tmp:$LD_LIBRARY_PATH /tmp/open_17 /tmp/pool
echo "OK"

# -----------------------------------------
# doc

# Trigger auto doc update on master
if [[ "$AUTO_DOC_UPDATE" == "1" ]]; then
	echo "Running auto doc update"

	mkdir doc_update
	cd doc_update

	$SCRIPTSDIR/run-doc-update.sh

	cd ..
	rm -rf doc_update
fi
