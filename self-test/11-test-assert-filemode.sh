#!/bin/sh
. $(dirname "$0")/init.sh
. $(dirname "$0")/helpers.sh

# This tests whether the assertFileMode() assertion function works correctly.

tf="$(mktemp)"    ; add_cleanup "$tf"
td="$(mktemp -d)" ; add_cleanup "$td"
[ -f "$tf" ] || skip "mktemp did not work!"
[ -d "$td" ] || skip "mktemp -d did not work!"


# Successful cases:
t_expected=644 ; chmod "0$t_expected" -- "$tf" ; test_assertion 'pass' assertFileMode "$tf" "$t_expected"
t_expected=501 ; chmod "0$t_expected" -- "$tf" ; test_assertion 'pass' assertFileMode "$tf" "$t_expected"
t_expected=755 ; chmod "0$t_expected" -- "$td" ; test_assertion 'pass' assertFileMode "$td" "$t_expected"
t_expected=710 ; chmod "0$t_expected" -- "$td" ; test_assertion 'pass' assertFileMode "$td" "$t_expected"

# Fail on mode mismatch:
t_expected=611 ; test_assertion 'fail' assertFileMode "$tf" "$t_expected"
t_expected=701 ; test_assertion 'fail' assertFileMode "$td" "$t_expected"

# Fail on missing files:
t_actual=
t_expected=
rm -f -- "$tf"
test_assertion 'fail' assertFileMode "$tf" 644 \
	fail "assertFileMode did NOT fail on a missing file!"
test_assertion 'fail' assertFileMode "$tf" 000 \
	fail "assertFileMode accepted a missing file as mode 000!"
test_assertion 'fail' assertFileMode "$tf" 0 \
	fail "assertFileMode accepted a missing file as mode 0!"
test_assertion 'fail' assertFileMode "$tf" "" \
	fail "assertFileMode accepted a missing file as mode empty-string!"


success
