#! /bin/sh

test_shows_usage_info_when_no_args() {
    result=`$TCR`

    assertFalse $?
    assertEquals "Usage: tcr {red,green} [msg]" "$result"
}

test_exits_with_success_when_failure_and_expected_red() {
    echo "exit 1" > $TCR_TEST_COMMAND

    result=`$TCR red`

    assertTrue $?
}

test_exits_with_error_when_success_and_expected_red() {
    echo "exit 0" > $TCR_TEST_COMMAND

    result=`$TCR red`

    assertFalse $?
}

test_exits_with_success_when_success_and_expected_green() {
    echo "exit 0" > $TCR_TEST_COMMAND

    result=`$TCR green`

    assertTrue $?
}

test_exits_with_error_when_failure_and_expected_green() {
    echo "exit 1" > $TCR_TEST_COMMAND

    result=`$TCR green`

    assertFalse $?
}

test_exits_with_error_when_repository_does_not_exist() {
    result=`$TCR`

    assertEquals "Run from git repository!" "$result"
}

# stashes changes when failure and expected green
# stashes changes when success and expected red
# commits changes when failure and expected red
# commits changes when success and expected green
# exits with error when repository does not have initial commit
# runs tests with make test when test command not provided
# does not stash when failure expected green and index is empty
# does not stash when success expected red and index is empty

oneTimeSetUp() {
    TCR=$(dirname $(dirname $0))/tcr
    TCR=`realpath $TCR`
    TEST_DIR=`mktemp -d`
    TCR_TEST_COMMAND=$TEST_DIR/test.sh
    touch $TCR_TEST_COMMAND
    chmod +x $TCR_TEST_COMMAND
    export TCR_TEST_COMMAND
}

setUp() {
    OLD_DIR=$PWD
    cd $TEST_DIR
}
tearDown() {
    cd $OLD_DIR
}


# Load shUnit2
source `dirname $0`/shunit2
