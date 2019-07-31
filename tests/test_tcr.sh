#! /bin/sh

test_shows_usage_info_when_no_args() {
    result=`$TCR`

    assertFalse $?
    assertEquals "Usage: tcr {red,green} [msg]" "$result"
}

test_exits_with_error_when_repository_does_not_exist() {
    result=`$TCR green`

    assertEquals "Run from git repository!" "$result"
}

test_exits_with_error_when_repository_does_not_have_initial_commit() {
    givenRepositoryHasBeenCreated

    result=`$TCR green`

    assertEquals "At least initial commit is needed" "$result"
}

test_exits_with_error_when_failure_and_expected_green() {
    givenFailingTest

    result=`$TCR green`

    assertFalse $?
}

test_exits_with_success_when_failure_and_expected_red() {
    givenFailingTest

    result=`$TCR red`

    assertTrue $?
}

test_exits_with_error_when_success_and_expected_red() {
    givenPassingTest

    result=`$TCR red`

    assertFalse $?
}

test_exits_with_success_when_success_and_expected_green() {
    givenPassingTest

    result=`$TCR green`

    assertTrue $?
}

test_stashes_changes_when_failure_and_expected_green() {
    givenFailingTest

    result=`$TCR green`

    assertChangesStashed
}

test_stashes_changes_when_success_and_expected_red() {
    givenPassingTest

    result=`$TCR red`

    assertChangesStashed
}

test_exits_with_error_when_failure_expected_green_and_index_is_empty() {
    givenFailingTest
    git -C $TEST_DIR commit -am "everything commited" > /dev/null

    result=`$TCR green`

    assertEquals "No local changes to save" "$result"
}

givenFailingTest() {
    givenRepositoryHasBeenInitialized
    echo "exit 1" > $TCR_TEST_COMMAND
}

givenPassingTest() {
    givenRepositoryHasBeenInitialized
    echo "exit 0" > $TCR_TEST_COMMAND
}

givenRepositoryHasBeenInitialized() {
    givenRepositoryHasBeenCreated
    givenInitialCommitHasBeenCreated
}

givenRepositoryHasBeenCreated() {
    git init -q $TEST_DIR > /dev/null
}

givenInitialCommitHasBeenCreated() {
    git -C $TEST_DIR add $TCR_TEST_COMMAND > /dev/null
    git -C $TEST_DIR commit -m "init" > /dev/null
}


assertChangesStashed() {
    stashed=`git -C $TEST_DIR stash list`
    assertContains "$stashed" "WIP on master"
}


# commits changes when failure and expected red
# commits changes when success and expected green
# runs tests with make test when test command not provided
# does not stash when success expected red and index is empty

setUp() {
    TCR=$(dirname $(dirname $0))/tcr
    TCR=`realpath $TCR`
    TEST_DIR=`mktemp -d`
    TCR_TEST_COMMAND=$TEST_DIR/test.sh
    export TCR_TEST_COMMAND
    touch $TCR_TEST_COMMAND
    chmod +x $TCR_TEST_COMMAND
    OLD_DIR=$PWD
    cd $TEST_DIR
}
tearDown() {
    cd $OLD_DIR
    rm -rf $TEST_DIR
    unset TCR_TEST_COMMAND
}

# Load shUnit2
source `dirname $0`/shunit2
