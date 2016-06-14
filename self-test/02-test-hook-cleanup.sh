#!/bin/sh
. $(dirname "$0")/init.sh

# This tests whether the hook_cleanup() function will be called once
# by the success() function.

nfile="$(mktemp)"
> "$nfile"

hook_cleanup () {
	# Since we'll call success() in a subshell
	# so that the script does not stop immediately,
	# this function is unable to alter any variables.
	# That's why we have to use a file to count the calls.
	echo -n "x" >>"$nfile"  # add one char to the previously empty file
	true
}

output="$(success 2>&1)"  || true

# remove hook:
hook_cleanup () { :; }

n_called=$(wc -c <"$nfile")  # count the characters in the files, i.e. how often hook_cleanup() was called
rm -f -- "$nfile"

[ "$n_called" -gt 0 ] || fail "success() did not call hook_cleanup()!"
[ "$n_called" -eq 1 ] || fail "success() called hook_cleanup() more than once!"

success
