#!/bin/sh

set -e  # immediately abort if any test fails

cd "$(readlink -f "$(dirname "$0")")"  # change to test directory

# list all test scripts in alphabetical order
test_file_pattern='??-test-*.sh'
test_files="$(find . -maxdepth 1 -type f -name "$test_file_pattern" | sort)"

for testsh in ${test_files:-$test_file_pattern}; do  # run all tests in filename order
	$testsh
done

. ./assert.sh  # just for the color_ constants
echo "${color_success}"
echo "All tests executed successfully."
echo "${color_normal}"

