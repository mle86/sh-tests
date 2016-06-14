#!/bin/sh
set -e
. $(dirname "$0")/init.sh

# This tests whether the skip() function correctly prints its argument
# without aborting the test script.

expectSt=0
expectMsg="foo19094858435"

sentinel="ZZZZZZZZZZZZZZZZZZ3413871920982Z"
status=0
output=$(set +e; skip "$expectMsg" 2>&1 ; echo "$sentinel")  || status="$?"

case "$output" in
	*"$sentinel"*)
		echo "skip() did not exit!"  >&2
		exit 1
		;;
esac

if [ $status != $expectSt ]; then
	echo "skip() exited, but with incorrect status $status !"  >&2
	exit 1
fi

if [ -z "$output" ]; then
	echo "skip() exited with status $expectSt, but had no output!"  >&2
	exit 1	
fi

case "$output" in
	*"$expectMsg"*)
		;;
	*)
		echo "skip() exited, but did not show expected message '$expectMsg'!"  >&2
		exit 1	
		;;
esac

echo "Ok"
exit 0
