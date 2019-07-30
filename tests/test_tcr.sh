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

# exits with error when success and expected red
# exits with success when success and expected green
# exits with error when failure and expected green

# stashes changes when failure and expected green
# stashes changes when success and expected red
# commits changes when failure and expected red
# commits changes when success and expected green

oneTimeSetUp() {
    TCR=$(dirname $(dirname $0))/tcr
    TCR=`realpath $TCR`
    TEST_DIR=`mktemp -d`
    TCR_TEST_COMMAND=$TEST_DIR/test.sh
    touch $TCR_TEST_COMMAND
    chmod +x $TCR_TEST_COMMAND
    export TCR_TEST_COMMAND
}

# Load shUnit2
source `dirname $0`/shunit2
