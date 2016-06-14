#!/bin/sh
set -e
. $(dirname "$0")/init.sh

# This tests whether the success() function prints something
# and aborts the test script with an exit status of zero.

expectSt=0

sentinel="ZZZZZZZZZZZZZZZZZZ2209155682348Z"
status=0
output=$(set +e; success 2>&1 ; echo "$sentinel")  || status="$?"

case "$output" in
	*"$sentinel"*)
		echo "success() did not exit!"  >&2
		exit 1
		;;
esac

if [ $status != $expectSt ]; then
	echo "success() exited, but with incorrect status $status !"  >&2
	exit 1
fi

if [ -z "$output" ]; then
	echo "success() exited with status $expectSt, but had no output!"  >&2
	exit 1	
fi

success
