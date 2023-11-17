#!/bin/sh -ex

export SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)
YICES2_SRC=yices2-src
YICES2_BUILD=yices2-build


