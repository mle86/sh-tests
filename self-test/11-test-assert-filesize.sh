#!/bin/sh
. $(dirname "$0")/init.sh
. $(dirname "$0")/helpers.sh

# This tests whether the assertFileSize() assertion function works correctly.

tf="$(mktemp)" ; add_cleanup "$tf"
#td="$(mktemp -d)" ; add_cleanup "$td"
[ -f "$tf"   ] || skip "mktemp did not work!"
[ ! -s "$tf" ] || skip "mktemp made a non-empty file!"
#[ -d "$td"   ] || skip "mktemp -d did not work!"


# Successful cases:
t_actual=0
test_assertion 'pass' assertFileSize "$tf" 0
t_actual=3 ; echo -n foo >>"$tf"
test_assertion 'pass' assertFileSize "$tf" 3

# Special case:
test_assertion 'pass' assertFileSize "/dev/null" 0

# Fail on size mismatch:
t_expected=2
test_assertion 'fail' assertFileSize "$tf" "$t_expected" \
	fail "assertFileSize did NOT fail on a size mismatch!"

# Fail on missing files:
t_actual=
t_expected=
rm -f -- "$tf"
test_assertion 'fail' assertFileSize "$tf" 7 \
	fail "assertFileSize did NOT fail on a missing file!"
test_assertion 'fail' assertFileSize "$tf" 0 \
	fail "assertFileSize accepted a missing file as size zero!"


success
