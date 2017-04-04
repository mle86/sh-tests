#!/bin/sh
. $(dirname "$0")/init.sh
. $(dirname "$0")/helpers.sh

# This tests whether the assertRegex() assertion function works correctly.


# tests with a simple one-line subject string:
t_actual="my test string"
t_expected='/^/'	test_assertion 'pass'  assertRegex
t_expected='/t/'	test_assertion 'pass'  assertRegex
t_expected='/T/i'	test_assertion 'pass'  assertRegex
t_expected='/[tTxX]/'	test_assertion 'pass'  assertRegex
t_expected='/T/'	test_assertion  'fail'  assertRegex	2>/dev/null
# inverted result:
t_expected='!/T/'	test_assertion 'pass'  assertRegex
t_expected='!/[xXG]/'	test_assertion 'pass'  assertRegex
t_expected='!/[xXGg]/'	test_assertion  'fail'  assertRegex	2>/dev/null
t_expected='!/[xXGg]/i'	test_assertion  'fail'  assertRegex	2>/dev/null
t_expected='!/[xXG]/i'	test_assertion  'fail'  assertRegex	2>/dev/null
t_expected='!/[tTxX]/'	test_assertion  'fail'  assertRegex	2>/dev/null

# illegal modifiers:
test_cmd 'err'  assertRegex "my test string" '/t/y'		2>/dev/null
test_cmd 'err'  assertRegex "my test string" '/t/;'		2>/dev/null
test_cmd 'err'  assertRegex "my test string" '/t/"'		2>/dev/null
test_cmd 'err'  assertRegex "my test string" '/t/`'		2>/dev/null
test_cmd 'err'  assertRegex "my test string" "/t/'"		2>/dev/null
test_cmd 'err'  assertRegex "my test string" '/t/iy'		2>/dev/null
test_cmd 'err'  assertRegex "my test string" '/t/yi'		2>/dev/null
test_cmd 'err'  assertRegex "my test string" '/t/iyi'		2>/dev/null
test_cmd 'err'  assertRegex "my test string" '/t/e'		2>/dev/null
test_cmd 'err'  assertRegex "my test string" '/t/g'		2>/dev/null

# dangerous characters:
username="$(whoami)"
test_cmd 'err'  assertRegex "+${username}+" '/`whoami`/i'	2>/dev/null
test_cmd 'err'  assertRegex "assertRegex perl -e" '/$0/i'	2>/dev/null

# tests with an empty subject string:
test_cmd 'noerr'  assertRegex "" '//'
test_cmd 'noerr'  assertRegex "" '/^/'
test_cmd 'noerr'  assertRegex "" '/^$/'
test_cmd 'noerr'  assertRegex "" '!/./'
test_cmd 'err'  assertRegex "" '/./'		2>/dev/null
test_cmd 'err'  assertRegex "" '/./'		2>/dev/null
test_cmd 'err'  assertRegex "" '!//'		2>/dev/null

# tests with a multi-line subject string:
t_actual="Multi-line
	subject

string!"
t_expected='/str/'			test_assertion 'pass'  assertRegex
t_expected='!/stx/'			test_assertion 'pass'  assertRegex
t_expected='/subject\s+string/'		test_assertion 'pass'  assertRegex
t_expected='!/subject string/'		test_assertion 'pass'  assertRegex
t_expected='!/^string/'			test_assertion 'pass'  assertRegex
t_expected='/^string/m'			test_assertion 'pass'  assertRegex
t_expected='!/subject.+string/'		test_assertion 'pass'  assertRegex
t_expected='/subject.+string/s'		test_assertion 'pass'  assertRegex


success
