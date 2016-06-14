This directory contains test shell scripts
to test the test shell script framework.
I was bored.

The test scripts can be run by themselves,
but many depend on successful results of earlier tests.
To ensure that the tests actually work correctly,
they should be run in filename order,
as their numeric prefixes were chosen to ensure correct dependencies.
These are the prefix groups:

* **00**
  Fundamentals like environment variables
  and whether init.sh and assert.sh can actually be sourced safely.  
  As nothing is yet certain, these tests use only low-level shell functions.

* **01**
  Tests about the script-stopping functions
  `success`, `fail`, and `skip`,
  as well as the similar `err` helper function.

* **02**
  Tests about the cleanup procedure
  and the hook functions.  
  These tests can use `success` and `fail` themselves,
  as those functions have been tested in the previous group.

* **10**
  Tests about specific assertions.

* **11**
  Tests about specific assertions
  with the added comfort of having `assertCmd` and `assertContains`.

The *run-all-tests.sh* script is so simple as to have no tests.

