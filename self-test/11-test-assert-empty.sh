#!/bin/sh
. $(dirname "$0")/init.sh
. $(dirname "$0")/helpers.sh

# This tests whether the assertEmpty() assertion function works correctly.

linebreak="
"
multiline=" sdfsd f


ltkgf h

"

test_assertion 'pass'  assertEmpty '' 'extra-error-message' \
	|| fail "assertEmpty('') failed!"

t_actual=yyy          t_errmsg='extra-error' test_assertion 'fail'  assertEmpty \
	|| fail "assertEmpty(string) failed!"
t_actual="$multiline" t_errmsg='fgkjdfgk'    test_assertion 'fail'  assertEmpty \
	|| fail "assertEmpty(multiline-string) failed!"
t_actual="$linebreak" t_errmsg='fgkjdfgk'    test_assertion 'fail'  assertEmpty \
	|| fail "assertEmpty(linebreak) failed!"

success
