#!/bin/sh
. $(dirname "$0")/init.sh

# This tests whether files added to the cleanup list with add_cleanup()
# will actually be deleted when success() or fail() is called.

tfile1="$(mktemp)" ; [ -f "$tfile1" ] || skip "mktemp() failed"
tfile2="$(mktemp)" ; [ -f "$tfile2" ] || skip "mktemp() failed"
tfile3="$(mktemp)" ; [ -f "$tfile3" ] || skip "mktemp() failed"
tfile4="$(mktemp)" ; [ -f "$tfile4" ] || skip "mktemp() failed"

add_cleanup "$tfile1"
add_cleanup "$tfile2"

output="$(success 2>&1)"  || true
[ ! -f "$tfile1" ] || fail "success() did not delete the first add_cleanup() file!"
[ ! -f "$tfile2" ] || fail "success() did not delete the second add_cleanup() file!"
[   -f "$tfile3" ] || fail "success() deleted some OTHER file on cleanup!!"
[   -f "$tfile4" ] || fail "success() deleted some OTHER file on cleanup!!"

add_cleanup "$tfile4"
add_cleanup "$tfile3"

output="$(fail "foo" 2>&1)"  || true
[ ! -f "$tfile3" ] || fail "fail() did not delete a add_cleanup() file!"
[ ! -f "$tfile4" ] || fail "fail() did not delete another add_cleanup() file!"

success
