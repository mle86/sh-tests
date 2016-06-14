#!/bin/sh
. $(dirname "$0")/init.sh

# This tests the cd_tmpdir() helper function.


oldpwd="$(pwd)"
cd_tmpdir || fail "cd_tmpdir() did not return true!"

tmp="$(pwd)"
[ "$oldpwd" != "$tmp" ] || fail "cd_tmpdir() did not change the current directory!"

prefix="$(/bin/echo "${TMPDIR:-/tmp}" | sed 's#/\+$##')/"
[ "$tmp" = "$prefix${tmp#$prefix}" ] || fail "cd_tmpdir() did not create its temporary directory below \$TMPDIR! ($tmp)"

list="$(ls -CA .)" || skip "could not call 'ls -CA' in temporary directory?!"
[ -z "$list" ] || fail "temporary directory is not empty! ($list)"

cd /  # Leave tmpdir so it can be deleted
output=$(success)  # Run in subshell, so it won't stop this test script. Also, we don't care about the output.
[ ! -d "$tmp" ] || fail "calling success() did not remove the still-empty temporary directory!"

success
