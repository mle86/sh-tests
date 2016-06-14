#!/bin/sh
. $(dirname "$0")/init.sh
. $(dirname "$0")/helpers.sh

# This tests whether the assertCmd() assertion function works correctly.


script_params="$(mktemp)" ; add_cleanup "$script_params" ; chmod +x -- "$script_params"
cat >"$script_params" <<-'EOT'
	#!/bin/sh
	echo "<$1><$2><$3>"
	exit 0
EOT
if ! t=$($script_params '' 123) || [ "$t" != "<><123><>" ]; then
	skip "helper script 'script_params' did not work as expected"
fi

script_status="$(mktemp)" ; add_cleanup "$script_status" ; chmod +x -- "$script_status"
cat >"$script_status" <<-'EOT'
	#!/bin/sh
	echo "foo44445"
	exit "${1:-0}"
EOT
st=0 ; t=$($script_status 42) || st=$?
if [ "$t" != "foo44445" ] || [ "$st" -ne 42 ]; then
	skip "helper script 'script_status' did not work as expected"
fi


OUTPUTFILE=$(mktemp) ; add_cleanup "$OUTPUTFILE"
assertion_output="$(test_cmd 'cont' assertCmd "$script_params '' foo222")" \
	|| fail "assertCmd aborted the test script after a succeeding command!"
[ -z "$assertion_output" ] || fail "assertCmd (successful and without -v option) printed some extra output! ($assertion_output)"
ASSERTCMDOUTPUT="$(cat -- "$OUTPUTFILE")"
[ -n "$ASSERTCMDOUTPUT" ] || fail "assertCmd did not store the command's output in \$ASSERTCMDOUTPUT!"
[ "$ASSERTCMDOUTPUT" = "<><foo222><>" ] || fail "assertCmd's command argument handling is broken!"

# Now we know that assertCmd() works with successful commands when expecting a zero exit status,
# will correctly store its command's output in $ASSERTCMDOUTPUT,
# will correctly pass arguments to its command,
# and won't abort the test script for no good reason.

# Test a different exit status:
test_cmd 'err' assertCmd "$script_status 33"     2>/dev/null \
	|| fail "assertCmd did NOT abort the test script after an unsuccessful command!"
test_cmd 'cont' assertCmd "$script_status 33" 33 2>/dev/null \
	|| fail "assertCmd aborted the test script after an expectedly unsuccessful command!"

# Test the -v option:
assertion_output="$(test_cmd 'cont' assertCmd -v "$script_status 0" 0 2>/dev/null)"
ASSERTCMDOUTPUT="$(cat -- "$OUTPUTFILE")"
[ -n "$ASSERTCMDOUTPUT" ] || fail "assertCmd -v did not store anything in \$ASSERTCMDOUTPUT!"
[ "$ASSERTCMDOUTPUT" = "foo44445" ] || fail "assertCmd -v did not store the correct command's output in \$ASSERTCMDOUTPUT!"
case "$assertion_output" in
	"$ASSERTCMDOUTPUT")	;;  # ok
	*"$ASSERTCMDOUTPUT"*)	fail "assertCmd -v added extra stdout output!" ;;
	*)			fail "assertCmd -v did not print the command's output on stdout!" ;;
esac

# Test multiple command input:
test_cmd 'cont' assertCmd "echo foo1 ; echo bar2" \
	|| fail "assertCmd did not work correctly with multiple-command input!"
test_cmd 'err' assertCmd "echo foo1 ; echo bar2 ; false" 2>/dev/null \
	|| fail "assertCmd did NOT fail on an unsuccessful multiple command!"

# Test multi-line input:
longcmd="echo -n   \"1111\"   \\
2222
echo   '3333'"
test_cmd 'cont' assertCmd "$longcmd" \
	|| fail "assertCmd did not work correctly with multi-line multiple-command input!"
ASSERTCMDOUTPUT="$(cat -- "$OUTPUTFILE")"
[ "$ASSERTCMDOUTPUT" = "1111 22223333" ] || fail "assertCmd did not execute a multi-line multi-command correctly! (Wrong output)"

# Test redirections:
test_cmd 'cont' assertCmd "echo foo >/dev/null ; false ; echo bAr | tr [a-z] [A-Z]" \
	|| fail "assertCmd did not work correctly with a multiple-command input with redirections!"
ASSERTCMDOUTPUT="$(cat -- "$OUTPUTFILE")"
[ "$ASSERTCMDOUTPUT" = "BAR" ] || fail "assertCmd did not execute a multi-line multi-command with redirections correctly! (Wrong output)"

# Test "any" status:
test_cmd 'cont' assertCmd "$script_status 0"   'any'             || fail "assertCmd did not accept exit status zero as 'any'!"
test_cmd 'cont' assertCmd "$script_status 1"   'any'             || fail "assertCmd did not accept exit status 1 as 'any'!"
test_cmd 'cont' assertCmd "$script_status 83"  'any'             || fail "assertCmd did not accept exit status 83 as 'any'!"
test_cmd 'err'  assertCmd "$script_status 126" 'any' 2>/dev/null || fail "assertCmd falsely accepted exit status 126 as 'any'!"
test_cmd 'err'  assertCmd "$script_status 127" 'any' 2>/dev/null || fail "assertCmd falsely accepted exit status 127 as 'any'!"
test_cmd 'cont' assertCmd "$script_status 128" 'any'             || fail "assertCmd did not accept exit status 128 as 'any'!"

success
