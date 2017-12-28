#!/bin/sh
set -e  # fail on errors

# The full path of the currently-running test script.
THIS="$(readlink -f -- "$0")"

# The current test script name (without its .sh suffix).
TESTNAME="$(basename --suffix='.sh' -- "$THIS")"

# The directory where the test script is located, as well as this file.
HERE="$(dirname -- "$THIS")"

# The assertion functions script. Will be sourced later.
export ASSERTSH="$HERE/assert.sh"

# The test configuration script. Will be sourced later, if it exists.
export CONFIGSH="$HERE/config.sh"

# The error condition flag file. It should not exist yet. A subshell can create this file to signal an error to the main test.
export ERRCOND="$HERE/errcond-$TESTNAME"

# By default, the test subject is not supposed to run a real subshell. This should only be changed via prepare_subshell().
export SHELL="true"


DIR=  # The temporary working directory, which should be deleted by cleanup() later. (See cd_tmpdir)
TMPSH=  # The subshell script path (see prepare_subshell).
IN_SUBSHELL=  # This flag will be set to 'yes' for subshells by prepare_subshell().
CLEANUP_FILES=  # Additional files and empty directories to delete. Separate with spaces. Be careful, they'll be deleted with "rm -fd".
SUBSHELL_MARKER=  # Marker file, will be placed in $DIR by all subshell scripts when it executed.


rm -f -- "$ERRCOND"  # this may have been left over from an earlier, broken test 


# Load assertion and error functions.
# This must be done prior to our cleanup() definition, or it will be overwritten.
. $ASSERTSH

hook_cleanup () { :; }  # Override this in your config.sh if your tests have to do additional cleanup work.

# Load the project-specific test configuration, if present.
[ -r "$CONFIGSH" ] && . $CONFIGSH


echo "${color_info}Starting ${TESTNAME}...${color_normal}"


cd_tmpdir () {
	# Creates a temporary directory to work in and changes into it.
	# Also changes ERRCOND to point into the new directory,
	# so we don't clutter the test root with them.

	DIR="$(mktemp -d)"
	export ERRCOND="$DIR/errcond-$TESTNAME"
	cd -- "$DIR"
}

prepare_subshell () {
	# Prepares a subshell script and points the TMPSH and SHELL env vars to it.
	# The subshell will always have IN_SUBSHELL=yes set
	# and will always source the assert.sh and config.sh files (if present).
	# It can use all assertion functions, including fail(),
	# but should not need to use success() or cleanup().
	# Pipe the subshell script contents to this function.

	[ -z "$DIR" ] && fail "TEST ERROR: Call cd_tmpdir() before using prepare_subshell()!"

	[ -n "$TMPSH" ] && rm -v "$TMPSH"  # delete earlier subshell file (in case of multiple calls)
	TMPSH="$(mktemp --tmpdir="$DIR" 'tmp.subshell.XXXXXX.sh')"

	# Leave a marker file as soon as the script gets executed.
	# assertSubshellWasExecuted() checks the existence of this file.
	SUBSHELL_MARKER="$(mktemp -u --tmpdir="$DIR" 'subshell-executed_XXXXXX')"

	# Make sure this marker file will get deleted later.
	add_cleanup "$SUBSHELL_MARKER"

	cat >$TMPSH <<ZTMPSH
#!/bin/sh
export IN_SUBSHELL=yes
touch -- "$SUBSHELL_MARKER"
. \$ASSERTSH
cleanup () { :; }  # subshells don't need to do any cleanup
success () { exit 0; }  # don't report success yet, just return to the test script
skip    () { exit 0; }  # don't show the skip message, just return to the test script
[ -r "\$CONFIGSH" ] && . \$CONFIGSH  # load project test configuration
ZTMPSH
	cat >> $TMPSH  # append function input, i.e. the actual subshell script content
	chmod +x $TMPSH

	export SHELL="$TMPSH"
}

success () {
	# This should be called at the end of every test script
	# to signal the successful test to the user.

	echo "${color_success}Success: ${TESTNAME}${color_normal}"
	cleanup
	exit 0
}

# skip [errorMessage]
#  This function stops the test script execution, but exits with success status.
#  Also, the abort message is not printed in red (the "error color"), but in yellow.
skip () {
	[ -n "$1" ] && printf '%s\n' "${color_skip}""$*""${color_normal}"  >&2
	echo "${color_skip}Skipped: ${TESTNAME}${color_normal}"  >&2
	cleanup
	exit 0
}

cleanup () {
	# This should not be called manually -- success() and fail() both call it.
	# It deletes the test's temporary files and directories.
	# It does NOT use "rm -r", so if the test script used cd_tmpdir
	# and placed additional files there, it should remove them itself
	# (or better, add them to the CLEANUP_FILES list).

	hook_cleanup
	[ -n "$TMPSH"   ] && [ -f "$TMPSH"   ] && rm --one-file-system -v   -- "$TMPSH"
	[ -n "$ERRCOND" ] && [ -f "$ERRCOND" ] && rm --one-file-system -v   -- "$ERRCOND"
	[ -n "$CLEANUP_FILES"                ] && rm --one-file-system -vfd -- $CLEANUP_FILES

	[ -n "$DIR" ] && [ -d "$DIR" ] && rm --one-file-system -vd -- "$DIR"

	:;  # if none of the previous conditions was true, this function should still succeed
}

# add_cleanup filename...
#  Adds one or more filenames to the $CLEANUP_FILES list.
#  Use this if your test script creates files in the temporary directory
#  which should be automatically deleted as soon as the test script ends.
#  Be careful, they'll be deleted with "rm -fd" and must not contain spaces.
add_cleanup () {
	[ -n "$1" ] && CLEANUP_FILES="$CLEANUP_FILES $@"
}

