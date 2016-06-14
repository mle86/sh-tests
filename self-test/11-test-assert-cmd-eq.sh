#!/bin/sh
. $(dirname "$0")/init.sh
. $(dirname "$0")/helpers.sh

# This tests whether the assertCmdEq() assertion function works correctly.

t_errmsg="this is bad"
multiline_cmd="/bin/echo -e \"aaa\nbbb\n\nccc\""
multiline="$(sh -c "$multiline_cmd")"


# Simple commands with one-line output, successful exit status, and simple arguments:
test_assertion 'pass' \
	assertCmdEq "true" ""
test_assertion 'pass' \
	assertCmdEq "echo foo" "foo"
t_expected="boz9821"
test_assertion 'fail' \
	assertCmdEq "echo bar" "$t_expected" "$t_errmsg"

# Simple commands with unsuccessful exit status:
t_expected=
test_assertion 'fail' \
	assertCmdEq "echo YYYYYY ; false" "XXXXXX" "$t_errmsg" \
	|| fail "assertCmdEq with wrong output AND non-zero exit status did not fail!"
t_expected="zog23434"
test_assertion 'fail' \
	assertCmdEq "echo $t_expected ; false" "$t_expected" "$t_errmsg" \
	|| fail "assertCmdEq with correct output but non-zero exit status did not fail!"

# Multi-line output:
test_assertion 'pass' \
	assertCmdEq "$multiline_cmd" "$multiline" \
	|| fail "assertCmdEq with a multiline-output command did not work!"

# Multiple command input:
test_assertion 'pass' \
	assertCmdEq "echo -n qqq ; echo www" "qqqwww"

# Commands with redirections:
redircmd="echo invisible >/dev/null ; echo fooBar | tr [a-z] [A-Z]"
t_expected="FOOBAR"
test_assertion 'pass' assertCmdEq "$redircmd" "$t_expected"
t_expected="XXXXXX"
test_assertion 'fail' assertCmdEq "$redircmd" "$t_expected"

success
