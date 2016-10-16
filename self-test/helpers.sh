#!/bin/sh

# test_cmd OP COMMAND...
#  OP="exit"  expect command to call "exit 0"
#  OP="cont"  expect command to finish successfully, not call exit
#  OP="noerr" expect command to finish successfully, not call exit, and have no stderr output
#  OP="fail"  expect command to call "exit" with a non-zero status
#  OP="err"   expect command to call "exit" with a non-zero status and print something on stderr
#  OP=N       expect command to call "exit $N"
#  If the env var $OUTPUTFILE is set, it's interpreted as file name
#   and the content of the $ASSERTCMDOUTPUT env var is written there after the command has been run.
#  Returns zero if OP was met, non-zero if it wasn't
#  Echoes the command's stdout on stdout, the command's stderr on stderr.
test_cmd () {
	local op="$1" ; shift

	[ -n "$OUTPUTFILE" ] && >"$OUTPUTFILE"

	local stderrfile=
	if [ "$op" = "err" ] || [ "$op" = "noerr" ]; then
		stderrfile="$(mktemp)"
	fi

	local sentinel="YYYYYYYYYYYYYYYYYYY832462194287342Y"
	local status=0
	local output=
	output="$(
		set -e ;

		# If COMMAND is an assertion and it fails, cleanup() will be called.
		# Prevent it from deleting anything we might still need:
		cleanup () { :; }

		if [ -n "$stderrfile" ]; then
			"$@" 2>"$stderrfile" ;
		else
			"$@" ;
		fi ;
		[ -n "$OUTPUTFILE" ] && /bin/echo "$ASSERTCMDOUTPUT" >"$OUTPUTFILE" ;
		/bin/echo -n "$sentinel" ;
	)" || status=$?

	local stderr_output=
	if [ -n "$stderrfile" ]; then
		stderr_output="$(cat -- "$stderrfile")"
		cat -- "$stderrfile" >&2
		rm -f "$stderrfile"
	fi

	if [ "$op" = "exit" ]; then
		[ "${output%$sentinel}" = "$output" ] || return 1  # sentinel was reached when the command should have exited
		[ "$status" -eq 0 ] || return 2  # wrong exit status
	elif [ "$op" = "cont" ]; then
		[ "${output%$sentinel}$sentinel" = "$output" ] || return 3  # sentinel was NOT reached, the command called exit
		[ "$status" -eq 0 ] || return 2  # wrong exit status
	elif [ "$op" = "noerr" ]; then
		[ "${output%$sentinel}$sentinel" = "$output" ] || return 3  # sentinel was NOT reached, the command called exit
		[ "$status" -eq 0 ] || return 2  # wrong exit status
		[ -z "$stderr_output" ] || return 4  # there was stderr output
	elif [ "$op" = "fail" ]; then
		[ "$status" -ne 0 ] || return 2  # wrong exit status
	elif [ "$op" = "err" ]; then
		[ -n "$stderr_output" ] || return 5  # no stderr output
		[ "$status" -ne 0 ] || return 2  # wrong exit status
	else
		[ "${output%$sentinel}" = "$output" ] || return 1  # sentinel was reached when the command should have exited
		[ "$status" -eq "$op" ] || return 2  # wrong exit status
	fi

	output="${output%$sentinel}"
	[ -n "$output" ] && /bin/echo "$output"

	true
}

# test_assertion OP COMMAND...
#  The optional envvar $t_actual will be the assertion's first argument if set.
#  The optional envvar $t_expected will be the assertion's second argument if set.
#  The optional envvar $t_errmsg will be the assertion's last argument if set.
#  The envvars $t_actual/$t_expected/$t_errmsg will ONLY be appended to the assertion command
#   if there's only one COMMAND argument, but no literal arguments to pass to the command.
#   This is done so that regular $t_actual/$t_expected/$t_errmsg arguments can be passed
#   to the command automatically, while special arguments (like the empty string)
#   can still be passed to the command explicitly.
#  OP="pass"  expect that the assertion returns with zero status and has no stderr output.
#  OP="fail"  expect that the assertion exits with non-zero status and includes $t_actual, $t_expected, and $t_errmsg in its stderr output.
#  This function assumes that working err() and assertContains() functions are available.
#  This function prints error messages on stderr and returns a non-zero status if OP is not met,
#   but it won't call exit().
test_assertion () {
	local op="$1" ; shift

	local stderr_output=

	local assertion="$1" ; shift
	local assertcmd="\"\$assertion\" \"\$@\""
	if [ $# -eq 0 ]; then
		[ -n "$t_actual"   ] && assertcmd="$assertcmd \"\$t_actual\""
		[ -n "$t_expected" ] && assertcmd="$assertcmd \"\$t_expected\""
		[ -n "$t_errmsg"   ] && assertcmd="$assertcmd \"\$t_errmsg\""
	fi

	if [ "$op" = "pass" ]; then
		# We expect the assertion to return with zero status and without any stderr output.
		if ! stderr_output="$(eval test_cmd 'cont' $assertcmd 2>&1 >/dev/null)"; then
			err "False-negative: Successful $assertion did not return with a zero status!"
			err "(Assertion error output: $(_reformat_error "$stderr_output"))"
			return 2
		fi
		if [ -n "$stderr_output" ]; then
			err "Successful $assertion produced stderr output!"
			err "(Assertion error output: $(_reformat_error "$stderr_output"))"
			return 4
		fi
	else
		# We expect the assertion to fail (non-zero status, $t_actual+$t_expected+$t_errmsg contained in stderr output).
		if ! stderr_output="$(eval test_cmd 'fail' $assertcmd 2>&1 >/dev/null)"; then
			err "False-positive: Failed $assertion did not exit with a non-zero status!"
			return 2
		fi

		if [ -z "$stderr_output" ]; then
			err "Failed $assertion did not print anything on stderr!"
			return 5
		fi

		stderr_output="$(_reformat_error "$stderr_output")"

		assertContains "$stderr_output" "$t_actual" "Failed $assertion did not print its valueActual on stderr!"
		assertContains "$stderr_output" "$t_expected" "Failed $assertion did not print its valueExpected on stderr!"
		assertContains "$stderr_output" "$t_error" "Failed $assertion did not print the custom error message on stderr!"
	fi

	true
}

# _reformat_assertion_error errorMessage
#  Strip ansi coloring,
#  surround with special highlighting.
_reformat_error () {
	local raw="$1"
	local nonl="$(/bin/echo "$raw" | sed 's/\x1b\[[[:digit:]d;]\+m//g' )"
	local highlighted="[3m${nonl}[23m"
	/bin/echo "$highlighted"
}

t_actual=
t_expected=
t_errmsg=

