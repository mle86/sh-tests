#!/bin/sh
set -e

# This checks whether init.sh sources config.sh (if available).

EXTVAR="e8269 9901 239842"
CONFIG_SH_LOADED=
CONFIG_SH_EXTVAR=

. $(dirname "$0")/init.sh

fail () {
	echo "$@"  >&2
	exit 1
}

[ "$CONFIG_SH_LOADED" = "yes" ] || fail "init.sh did not source config.sh!"
[ "$CONFIG_SH_EXTVAR" = "$EXTVAR" ] || fail "config.sh was sourced, but could not read other vars!"
[ "$(config_sh_works)" = "yep" ] || fail "config.sh was sourced, but it could not define new functions!"

echo "Ok"
exit 0
