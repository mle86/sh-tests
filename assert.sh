#!/bin/sh

# This file contains the actual assertion functions.


# The exit status for the test script (and the subshell script)
# if an assertion fails or fail() or abort() are called.
EXIT_ASSERT=99

# The stdout output of the last assertCmd() command.
ASSERTCMDOUTPUT=

# ANSI color constants. Used by init.sh functions too.
color_info='[1;37m'
color_success='[1;32m'
color_skip='[1;33m'
color_error='[1;31m'
color_normal='[0m'



# abort()
#  If this is called from a test script, we should simply call cleanup and exit.
#  But if this is called from a subshell, we should signal the error condition to the test script running outside!
#  This function should not be called manually -- use fail() instead.
abort () {
	[ -n "$IN_SUBSHELL" -a -n "$ERRCOND" ] && touch $ERRCOND  # signal the error condition back to the test script
	cleanup
	exit $EXIT_ASSERT
}

# err errorMessage
#  This function prints an error message on stderr, but does not abort the test script execution.
#  Use it for multi-line error messages; otherwise, use fail(), as it also aborts the test script.
err () {
	echo "${color_error}""$@""${color_normal}" >&2
}

# fail errorMessage
#  This function prints an error message on stderr, then aborts the test script execution,
#  also calling cleanup() in the process.
fail () {
	err "$@"
	abort
}

# assertCmd [-v] command [expectedReturnStatus=0]
#  Tries to run a command and checks its return status.
#  The command's stdout output will be saved in $ASSERTCMDOUTPUT,
#  and won't be visible (unless the -v option is present).
#  The command's stderr output will NOT be redirected.
#  expectedReturnStatus can be any number (0..255),
#  or the special value 'any', in which case
#  all return status values will be accepted
#  (except 126 and 127, those are still considered a failure,
#  because they usually signify a shell command invocation error).
assertCmd () {

	local verbose=
	if [ "$1" = "-v" ]; then
		verbose=yes
		shift
	fi

	local cmd="$1"
	local expectedReturnStatus="${2:-0}"

	ASSERTCMDOUTPUT=

	# Run the command, save the return status and output,
	# and don't fail, no matter what the return status is!
	if ASSERTCMDOUTPUT="$(echo "$cmd" | sh -s)"; then
		local status="$?"  # ok
	else
		local status="$?"  # also ok
	fi

	[ -n "$verbose" ] && echo "$ASSERTCMDOUTPUT"

	# The command might possibly have run a subshell (see prepare_subshell).
	# In this case, it will have run its own assertions,
	# so now we have to check if the error condition file has been created.
	if [ -n "$ERRCOND" -a -f "$ERRCOND" ]; then
		# The error condition file exists!
		# We'll assume that the assertion that caused this
		# has already printed an error message, so we'll abort silently.
		# No need to check the command status/output anymore.
		abort
	fi

	local isStatusError=
	if [ "$expectedReturnStatus" = "any" ]; then
		# "any" means to accept all return status values -- except 126 and 127,
		# those come from the shell, usually due to an invalid command.
		[ "$status" -eq 126 -o "$status" -eq 127 ] && isStatusError=yes
	elif [ "$status" -ne "$expectedReturnStatus" ]; then
		# status mismatch
		isStatusError=yes
	fi

	if [ -n "$isStatusError" ]; then
		err "Command '$cmd' was not executed successfully!"
		err "(Expected return status: $expectedReturnStatus, Actual: $status)"
		abort
	fi
}

# assertEq valueActual valueExpected [errorMessage]
#  This assertion compares two strings and tests them for equality.
assertEq () {
	local valueActual="$1"
	local valueExpected="$2"
	local errorMessage="${3:-"Equality assertion failed!"}"
	if [ "$valueActual" != "$valueExpected" ]; then
		err "$errorMessage"
		err "(Expected: '$valueExpected', Actual: '$valueActual')"
		abort
	fi
}

# assertContains valueActual valueExpectedPart [errorMessage]
#  This assertion compares two strings,
#  expecting the second to be contained somewhere in the first.
assertContains () {
	local valueActual="$1"
	local valueExpectedPart="$2"
	local errorMessage="${3:-"Substring assertion failed!"}"
	case "$valueActual" in
		*"$valueExpectedPart"*) true ;;  # ok
		*)
			err "$errorMessage"
			err "(Expected '$valueExpectedPart' is not contained in '$valueActual')"
			abort ;;
	esac
}

# assertEmpty valueActual [errorMessage]
#  This assertion tests a string, expecting it to be empty.
assertEmpty () {
	local valueActual="$1"
	local errorMessage="${2:-"Emptyness assertion failed!"}"
	assertEq "$valueActual" "" "$errorMessage"
}

# assertCmdEq command expectedOutput [errorMessage]
#  This assertion is a combination of assertCmd+assertEq.
#  It executes a command, then compares its entire stdout output against expectedOutput.
#  The command is expected to always have a return status of zero.
assertCmdEq () {
	local cmd="$1"
	local expectedOutput="$2"
	local errorMessage="${3:-"Command output assertion failed!"}"

	assertCmd "$cmd" 0  # run cmd, check success return status
	assertEq "$ASSERTCMDOUTPUT" "$expectedOutput" "$errorMessage"  # compare output
}

# assertCmdEmpty command [errorMessage]
#  This assertion is a combination of assertCmd+assertEmpty.
#  It executes a command, then compares its entire stdout output against the empty string.
#  The command is expected to always have a return status of zero.
assertCmdEmpty () {
	local cmd="$1"
	local errorMessage="${2:-"Command output emptyness assertion failed!"}"

	assertCmdEq "$cmd" "$expectedReturnStatus" "" "$errorMessage"
}

# assertFileSize fileName expectedSize [errorMessage]
#  This assertion checks than a file exists and compares its total size (in bytes) 
#  against expectedSize.
assertFileSize () {
	local fileName="$1"
	local expectedSize="$2"
	local errorMessage="${3:-"File '$fileName' has wrong size!"}"

	assertCmdEq "stat --format='%s' '$fileName'" "$expectedSize" "$errorMessage"
}

# assertFileMode fileName expectedOctalMode [errorMessage]
#  This assertion checks that a file exists and compares its octal access mode
#  (as printed by 'stat -c %a', e.g. '755') against expectedOctalMode.
assertFileMode () {
	local fileName="$1"
	local expectedOctalMode="$2"
	local errorMessage="${3:-"File '$fileName' has wrong access mode!"}"

	assertCmdEq "stat --format='%a' '$fileName'" "$expectedOctalMode" "$errorMessage"
}

# assertSubshellWasExecuted [errorMessage]
#  This assertion checks whether the last subshell script created via prepare_subshell() has been executed.
#  It does so by checking the existence of the marker file which the subshell script should have created.
assertSubshellWasExecuted () {
	local errorMessage="${1:-"Subshell script was not executed! (Marker file not found.)"}"
	[ -n "$SUBSHELL_MARKER" ] || fail "Could not check subshell execution, prepare_subshell() was not used"
	[ -e "$SUBSHELL_MARKER" ] || fail "$errorMessage"
	:;
}

