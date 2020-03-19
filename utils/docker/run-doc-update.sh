#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2018-2019, Intel Corporation

set -e

ORIGIN="https://${GITHUB_TOKEN}@github.com/pmem-bot/pmdk-convert"
UPSTREAM="https://github.com/pmem/pmdk-convert"

# Clone repo
git clone ${ORIGIN}
cd pmdk-convert
git remote add upstream ${UPSTREAM}

git config --local user.name "pmem-bot"
git config --local user.email "pmem-bot@intel.com"

git checkout master
git remote update
git reset --hard upstream/master

mkdir build
cd build
CC=gcc cmake .. -DCMAKE_BUILD_TYPE=Debug
cd ..

# Build & PR groff
make md2man -C ./build
git add -A ./doc
git commit -m "doc: automatic master docs update" && true
git push -f ${ORIGIN} master

# Makes pull request.
# When there is already an open PR or there are no changes an error is thrown, which we ignore.
hub pull-request -f -b pmem:master -h pmem-bot:master -m "doc: automatic master docs update" && true

git clean -dfx

# Copy man & PR web md
mkdir ../web_manpages
cp -r ./doc/pmdk-convert/* ../web_manpages/

# Checkout gh-pages and copy docs
git checkout -fb gh-pages upstream/gh-pages
git clean -dfx
cp -r  ../web_manpages/* ./manpages/master/

# Add and push changes.
# git commit command may fail if there is nothing to commit.
# In that case we want to force push anyway (there might be open pull request with
# changes which were reverted).
git add -A
git commit -m "doc: automatic gh-pages docs update" && true
git push -f ${ORIGIN} gh-pages

hub pull-request -f -b pmem:gh-pages -h pmem-bot:gh-pages -m "doc: automatic gh-pages docs update" && true

exit 0
