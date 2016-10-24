#!/bin/sh
. $(dirname "$0")/init.sh
. $(dirname "$0")/helpers.sh

# The err() function contained a problem:
# If the "expected" value of some assertion contained the literal string "\0",
# dash's "echo" would convert that to a real NUL, corrupting the error message.
# 
# err() and skip() are both using "printf %s" now.
# This test verifies that the fix is effective.


t_actual='aZb'
t_expected='a\''0b'
test_assertion 'fail'  assertCmdEq "echo aZb" "$t_expected" \
	|| fail "BBBBBBBB"

t_actual='a\''0b'
t_expected='aZb'
test_assertion 'fail'  assertCmdEq "printf '%s' 'a\\0b'" "$t_expected" \
	|| fail "CCCCCCCC"


success
