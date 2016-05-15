#!/bin/sh

set -e  # immediately abort if any test fails

cd "$(readlink -f "$(dirname "$0")")"  # change to test directory

for testsh in ./??-test-*.sh; do  # run all tests in filename order
	$testsh
done

. ./assert.sh  # just for the color_ constants
echo "${color_success}"
echo "All tests executed successfully."
echo "${color_normal}"

