#!/bin/sh
set -e
. $(dirname "$0")/init.sh

# This tests whether the err() function correctly prints its argument
# without aborting the test script.

expectMsg="bar11194597345"

sentinel="ZZZZZZZZZZZZZZZZZZ9921356977233Z"
output=$(set +e; err "$expectMsg" 2>&1; echo "$sentinel")  || true

case "$output" in
	*"$sentinel"*)
		;;
	*)
		echo "err() exited!"  >&2
		exit 1
		;;
esac

case "$output" in
	*"$expectMsg"*)
		;;
	*)
		echo "err() did not show expected message '$expectMsg'!"  >&2
		exit 1	
		;;
esac

echo "Ok"
exit 0
