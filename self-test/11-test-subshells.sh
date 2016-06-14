#!/bin/sh
. $(dirname "$0")/init.sh
. $(dirname "$0")/helpers.sh

# This tests the prepare_subshell() helper function,
# the assertSubshellWasExecuted() assertion function,
# and whether assertCmd() works well with failing subshell assertions.


[ -z "$TMPSH" ] || fail "TMPSH envvar was already set after sourcing init.sh!"

#test_assertion 'fail' assertSubshellWasExecuted \
#	|| fail "assertSubshellWasExecuted() did NOT fail before prepare_subshell() was even called once!"

if output=$(prepare_subshell >/dev/null 2>/dev/null ; echo "$TMPSH"); then
	fail "Calling prepare_subshell() was possible without an earlier cd_tmpdir()!"
fi
# Ok, it failed. But did it change TMPSH anyway?
[ -z "$output" ] || fail "Calling prepare_subshel() without an earlier cd_tmpdir() resulted in an error, but still changed \$TMPSH!"


marker="MMMMMMMMMMMMMMM10806781201934M"
marker_end="MMMMMMMMMMMMMMM99927506456410X"
marker_noassert="MMMMMMMMMMMMMMM55911008451935A"

cd_tmpdir
tmpdir="$(pwd)"

if ! prepare_subshell <<-EOT
	echo "$marker"
	echo "IN_SUBSHELL=\$IN_SUBSHELL"
	if ! assertContains "abcdefg" "bcd" "subshell-assert-contains-errmsg"; then
		echo "$marker_noassert"
	fi
	success
	echo "$marker_end"
EOT
then fail "prepare_subshell() returned a non-zero status!"; fi
first_subshell="$TMPSH"

[ -n "$TMPSH" ] || fail "prepare_subshell() did not write anything to \$TMPSH!"
[ -f "$TMPSH" ] || fail "\$TMPSH is not a filename! ($TMPSH)"
[ -x "$TMPSH" ] || fail "The \$TMPSH file is not executable! ($TMPSH)"

content="$(cat -- "$TMPSH")"
assertContains "$content" "$marker"     "prepare_subshell() did not write its stdin to the \$TMPSH script file!"
assertContains "$content" "$marker_end" "prepare_subshell() only wrote its first stdin line to the \$TMPSH script file!"

test_assertion 'fail' assertSubshellWasExecuted \
	|| fail "assertSubshellWasExecuted() did NOT fail, but the prepared subshell had not been executed yet!"


# Now run it and check what it does:
output="$($TMPSH)" || fail "Could not execute subshell script!"
test_assertion 'pass' assertSubshellWasExecuted
assertContains "$output" "$marker" "The subshell was not executed correctly! (Marker string not found)"
assertContains "$output" "IN_SUBSHELL=yes" "The subshell script did not see envvar IN_SUBSHELL==yes!"
case "$output" in
	*"subshell-assert-contains-errmsg"*) fail "Subshell assertions broken!" ;;
	*"$marker_noassert"*) fail "Subshell could not use assertions!" ;;
	*"$marker_end"*) fail "Calling success() in subshell did not end the subshell script!" ;;
	*) ;;
esac

# Build a second one, with a failing assertion:
prepare_subshell <<-EOT
	assertContains "abc" "xyz"
	echo "$marker_end"
	exit 55
EOT
failed=
output="$(test_cmd 'err' "$TMPSH" 2>/dev/null)" || failed=yes
case "$output" in
	*"$marker_end"*) fail "Failed assertion did not abort the subshell script!" ;;
	*) ;;
esac
[ -z "$failed" ] || fail "Subshell with failing assertion did not return an error status!"

# Now let's see if assertCmd will handle that one correctly:
output="$(test_cmd 'err' assertCmd "$TMPSH" "44" 2>&1 )" \
	|| fail "assertCmd(TMPSH) failed! $? $output"
# assertCmd should have noticed the errcond marker file and aborted without printing its own error message.
case "$output" in
	*"44"*) fail "assertCmd(TMPSH) failed correctly, but assertCmd still printed its own error message!" ;;
	*) ;;
esac
assertContains "$output" "not contained in" "assertCmd(TMPSH) ran a failing assertion whose error message was hidden!"


cd /
output=$(success)
[ ! -f "$TMPSH"          ] || fail "Calling success() did not delete the subshell script file!"
[ ! -f "$first_subshell" ] || fail "Calling success() only deleted the last subshell script file, but not the first!"
[ ! -d "$tmpdir"         ] || fail "Temporary directory is still there, the subshell left something behind! ($tmpdir)"

success
