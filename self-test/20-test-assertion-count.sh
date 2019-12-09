#!/bin/sh
. $(dirname "$0")/init.sh

# This tests whether our assertions correctly increase the $ASSERTCNT var by +1 each.


[ "$ASSERTCNT" = "0" ] || fail \
	"After initializing a test script, \$ASSERTCNT was not set to zero!  (Actual value: '$ASSERTCNT')"


testAssertionIncr () {
	local currentCnt="$ASSERTCNT"
	local expectedCnt="$((currentCnt + 1))"

	"$@"

	assertEq "$expectedCnt" "$ASSERTCNT" \
		"Assertion call did not correctly increase the \$ASSERTCNT var!  (Call: $*)"
}

testAssertionIncr assertEq "foo" "foo"
testAssertionIncr assertContains "my-testing-string" "g-str"
testAssertionIncr assertCmd "true"
testAssertionIncr assertCmdEq "echo foobar" "foobar"
testAssertionIncr assertRegex "my-testing-string" "/\\bTESTING\\b/i"


success
