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
	# Prepares a subshell script and points the SHELL env var to it.
	# The subshell will always have IN_SUBSHELL=yes
	# and will always source the assert.sh and config.sh files (if present).
	# It can use all assertion functions, including fail(),
	# but should not need to use success().
	# Pipe the subshell script contents to this function.

	[ -n "$TMPSH" ] && rm -v "$TMPSH"  # delete earlier subshell file (in case of multiple calls)
	TMPSH="$(mktemp --tmpdir="$DIR" 'tmp.subshell.XXXXXX.sh')"

	echo "#!/bin/sh" > $TMPSH
	echo "export IN_SUBSHELL=yes" >> $TMPSH
	echo ". \$ASSERTSH" >> $TMPSH
	echo "cleanup () { :; }" >> $TMPSH
	echo "success () { :; }" >> $TMPSH
	echo "[ -r \"\$CONFIGSH\" ] && . \$CONFIGSH" >> $TMPSH
	cat >> $TMPSH
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

cleanup () {
	# This should not be called manually -- success() and fail() both call it.
	# It deletes the test's temporary files and directories.
	# It does NOT use "rm -r", so if the test script used cd_tmpdir
	# and placed additional files there, it should remove them itself
	# (or better, add them to the CLEANUP_FILES list).

	hook_cleanup
	[ -n "$TMPSH"   -a -f "$TMPSH"   ] && rm --one-file-system -v   -- "$TMPSH"
	[ -n "$ERRCOND" -a -f "$ERRCOND" ] && rm --one-file-system -v   -- "$ERRCOND"
	[ -n "$CLEANUP_FILES"            ] && rm --one-file-system -vfd -- $CLEANUP_FILES
	[ -n "$DIR"     -a -d "$DIR"     ] && rm --one-file-system -vd  -- "$DIR"

	:;  # if none of the previous conditions was true, this function should still succeed
}

