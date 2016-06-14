#!/bin/sh
. $(dirname "$0")/init.sh
. $(dirname "$0")/helpers.sh

# This tests whether the assertEq() assertion function works correctly.

multiline_prefix="aaa"
multiline="$(/bin/echo -e "$multiline_prefix\n\nbbb\nccc\n")"
string="foo baz 96456210845970"

test_assertion 'pass' assertEq "$string" "$string" \
	|| fail "assertEq(\$string, \$string) failed!"

test_assertion 'pass' assertEq "$multiline" "$multiline" "extra-error-message" \
	|| fail "assertEq(\$multiline, \$multiline, extra-error-message) failed!"

test_assertion 'pass' assertEq '' '' \
	|| fail "assertEq('', '') failed!"

# Ok, assertEq() does no false-negatives
# and produces no stderr output when it shouldn't.

t_actual= t_expected=' '
test_assertion 'fail' assertEq '' ' ' \
	|| fail "assertEq('', ' ') did not fail!"

t_actual="$multiline" t_expected="$multiline_prefix"
test_assertion 'fail' assertEq \
	|| fail "assertEq(multiline, multiline_firstline) did not fail!"

# Ok, assertEq() does no false-positives
# and produces some stderr output when it fails.

t_actual='A' t_expected='a' t_errmsg='snafu Snafu'
test_assertion 'fail' assertEq \
	|| fail "assertEq(A, a) did not fail!"
# Ok, assertEq() is case-sensitive and
# prints the custom error message input in the stderr error message.

success
