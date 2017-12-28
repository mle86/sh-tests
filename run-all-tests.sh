#!/bin/sh

set -e  # immediately abort if any test fails

cd "$(readlink -f "$(dirname "$0")")"  # change to test directory

# list all test scripts in alphabetical order
test_file_pattern='??-test-*.sh'
test_files="$(find . -maxdepth 1 -type f -name "$test_file_pattern" | sort)"

if [ -z "$test_files" ]; then
	printf '%s: no test scripts (%s)\n' "$0" "$test_file_pattern"  >&2
	exit 1
fi

# count test scripts
n_tests="$(printf '%s' "$test_files" | wc -l)"

for testsh in $test_files; do  # run all tests
	./$testsh
done

. ./assert.sh  # just for the color_ constants
echo "${color_success}"
echo "All ${n_tests} tests executed successfully."
echo "${color_normal}"

