#!/bin/sh
. $(dirname "$0")/init.sh

# This tests whether our assertions correctly increase the $ASSERTCNT var by +1 each
# and whether addAssertionCount() works correctly.


[ "$ASSERTCNT" = "0" ] || fail \
	"After initializing a test script, \$ASSERTCNT was not set to zero!  (Actual value: '$ASSERTCNT')"


# testAssertionIncr assertionCommand...
testAssertionIncr () {
	local currentCnt="$ASSERTCNT"
	local expectedCnt="$((currentCnt + 1))"

	"$@"

	assertEq "$expectedCnt" "$ASSERTCNT" \
		"Assertion call did not correctly increase the \$ASSERTCNT var!  (Call: $*)"
}

# testCounterAdd expectedCnt [addArgument]
testCounterAdd () {
	local expectedAssertionCount="$1"
	if [ "$#" -ge 2 ]; then
		addAssertionCount "$2"
		assertEq "$expectedAssertionCount" "$ASSERTCNT" \
			"addAssertionCount() with argument \"$2\" did not work as expected!"
	else
		addAssertionCount
		assertEq "$expectedAssertionCount" "$ASSERTCNT" \
			"addAssertionCount() (without argument) did not work as expected!"
	fi
}


testAssertionIncr assertEq "foo" "foo"
testAssertionIncr assertContains "my-testing-string" "g-str"
testAssertionIncr assertCmd "true"
testAssertionIncr assertCmdEq "echo foobar" "foobar"
testAssertionIncr assertRegex "my-testing-string" "/\\bTESTING\\b/i"

testCounterAdd "$((ASSERTCNT + 1))"
testCounterAdd "$((ASSERTCNT + 1))" 1
testCounterAdd "$((ASSERTCNT + 1))" +1
testCounterAdd "$((ASSERTCNT + 2))" 2
testCounterAdd "$((ASSERTCNT + 3))" +3
testCounterAdd "$((ASSERTCNT - 2))" -2
testCounterAdd "$((ASSERTCNT    ))" 0


success
