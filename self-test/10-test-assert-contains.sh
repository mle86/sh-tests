#!/bin/sh
. $(dirname "$0")/init.sh
. $(dirname "$0")/helpers.sh

# This tests whether the assertContains() assertion function works correctly.

string_part="9645"
string="foo baz ${string_part}6210845970"
multiline_prefix="aa Aaa"
multiline_part="cCc"
multiline="$multiline_prefix
BBBB bbbb
     $multiline_part

fF

"

test_cmd 'noerr' assertContains "$string"    "$string" \
	|| fail "assertContains(\$string, \$string) failed!"
test_cmd 'noerr' assertContains ""           "" 'extra-error-message' \
	|| fail "assertContains('', '', extra-error-message) failed!"
test_cmd 'noerr' assertContains "$multiline" "$multiline" \
	|| fail "assertContains(\$multiline, \$multiline) failed!"

test_cmd 'noerr' assertContains "$string" "" \
	|| fail "assertContains(\$string, '') failed!"
test_cmd 'noerr' assertContains "$string" "$string_part" \
	|| fail "assertContains(\$string, \$string_part) failed!"
test_cmd 'noerr' assertContains "$multiline" "$multiline_part" \
	|| fail "assertContains(\$multiline, \$multiline_part) failed!"
test_cmd 'noerr' assertContains "$multiline" "$multiline_prefix" \
	|| fail "assertContains(\$multiline, \$multiline_prefix) failed!"

t_actual="$multiline"
t_expectedpart="YYYYY"
t_errmsg="snafu snafu"
errmsg="$(test_cmd 'err' assertContains "$t_actual" "$t_expectedpart" "$t_errmsg" 2>&1 )" \
	|| fail "assertContains(actual, missingPart, errorMessage) failed! $?"

case "$errmsg" in
	*"$t_actual"*"$t_expectedpart"*|*"$t_expectedpart"*"$t_actual"*) ;;
	*"$t_actual"*) fail "failed assertContains() printed its actual input value, but not its expected value!" ;;
	*"$t_expectedpart"*) fail "failed assertContains() printed its expected value, but not its actual input value!" ;;
	*) fail "failed assertContains() printed neither its actual input nor its expected value!" ;;
esac
case "$errmsg" in
	*"$t_errmsg"*) ;;
	*) fail "failed assertContains() did not print its error message input!" ;;
esac

success
