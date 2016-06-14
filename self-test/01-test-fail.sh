#!/bin/sh
set -e
. $(dirname "$0")/init.sh

# This tests whether the fail() function correctly prints its argument
# and aborts the test script with an exit status of 99.

expectSt=99
expectMsg="foo40923866183"

sentinel="ZZZZZZZZZZZZZZZZZZ0917510264695Z"
status=0
output=$(set +e; fail "$expectMsg" 2>&1 ; echo "$sentinel")  || status="$?"

case "$output" in
	*"$sentinel"*)
		echo "fail() did not exit!"  >&2
		exit 1
		;;
esac

if [ $status != $expectSt ]; then
	echo "fail() exited, but with incorrect status $status !"  >&2
	exit 1
fi

if [ -z "$output" ]; then
	echo "fail() exited with status $expectSt, but had no output!"  >&2
	exit 1	
fi

case "$output" in
	*"$expectMsg"*)
		;;
	*)
		echo "fail() exited, but did not show expected message '$expectMsg'!"  >&2
		exit 1	
		;;
esac

echo "Ok"
exit 0
