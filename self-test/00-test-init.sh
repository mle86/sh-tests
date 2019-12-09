#!/bin/sh
set -e

# This checks whether init.sh sets the helper variables which are mentioned in the readme,
# and if they have the correct values.

THIS='WAS-NOT-SET'
TESTNAME='WAS-NOT-SET'
HERE='WAS-NOT-SET'
ASSERTSH='WAS-NOT-SET'
ASSERTCMDOUTPUT='WAS-NOT-CLEARED'
ASSERTCNT='WAS-NOT-ZEROED'
SKIP_ASSERTCNT='WAS-NOT-CLEARED'

. $(dirname "$0")/init.sh

fail () {
	echo "$@"  >&2
	exit 1
}

thisscript="$(readlink -f -- "$0")"
thisname="$(basename --suffix='.sh' -- "$thisscript")"
thislocation="$(readlink -f -- "$(dirname -- "$0")")"

[ -z "$ASSERTCMDOUTPUT"          ] || fail "envvar \$ASSERTCMDOUTPUT has not been cleared!"
[ -z "$SKIP_ASSERTCNT"           ] || fail "envvar \$SKIP_ASSERTCNT has not been cleared!"
[ "$THIS"      = "$thisscript"   ] || fail "envvar \$THIS has incorrect value! ($THIS != $thisscript)"
[ "$TESTNAME"  = "$thisname"     ] || fail "envvar \$TESTNAME has incorrect value! ($TESTNAME != $thisname)"
[ "$HERE"      = "$thislocation" ] || fail "envvar \$HERE has incorrect value! ($HERE != $thislocation)"
[ "$ASSERTCNT" = "0"             ] || fail "envvar \$ASSERTCNT has incorrect value! ($ASSERTCNT != 0)"



if [ -z "$ASSERTSH" ] || [ ! -f "$ASSERTSH" ] || [ ! -r "$ASSERTSH" ]; then
	fail "envvar \$ASSERTSH does not point to a readable file ($ASSERTSH)"
fi

echo "Ok"
exit 0
