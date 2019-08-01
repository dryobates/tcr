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

test_exits_with_error_when_trying_stash_but_empty_index() {
    givenFailingTest
    git -C $TEST_DIR commit -am "everything commited" > /dev/null

    result=`$TCR green`

    assertEquals "No local changes to save" "$result"
}

test_commits_changes_when_failure_and_expected_red() {
    givenFailingTest

    result=`$TCR red`

    assertChangesCommited
}

test_commits_changes_when_success_and_expected_green() {
    givenPassingTest

    result=`$TCR green`

    assertChangesCommited
}

test_commits_changes_with_T_prefix_when_failure_and_expected_red() {
    givenFailingTest

    result=`$TCR red`

    assertChangesCommitedWithMessage "T working"
}

test_commits_changes_with_B_prefix_when_success_and_expected_green() {
    givenPassingTest

    result=`$TCR green`

    assertChangesCommitedWithMessage "B working"
}

test_commits_changes_with_S_prefix_when_success_expected_green_and_last_commit_was_with_B_or_S_prefix() {
    givenLastCommitMessageHadMessage "B working"
    givenPassingTest

    result=`$TCR green`

    assertChangesCommitedWithMessage "S working"
}

test_commits_changes_with_given_message_when_failure_and_expected_red() {
    givenFailingTest
    message="custom message"

    result=`$TCR red $message`

    assertChangesCommitedWithMessage "T $message"
}

test_commits_changes_with_given_message_when_success_and_expected_green() {
    givenPassingTest
    message="custom message"

    result=`$TCR green $message`

    assertChangesCommitedWithMessage "B $message"
}

test_commits_changes_with_last_message_but_different_prefix_when_success_and_expected_green() {
    givenLastCommitMessageHadMessage "T custom message"
    givenPassingTest

    result=`$TCR green`

    assertChangesCommitedWithMessage "B custom message"
}

test_commits_changes_with_default_message_when_failure_expected_red() {
    givenLastCommitMessageHadMessage "S some message"
    givenFailingTest

    result=`$TCR red`

    assertChangesCommitedWithMessage "T working"
}

givenFailingTest() {
    givenRepositoryHasBeenInitialized
    echo "exit 1" > $TCR_TEST_COMMAND
}

givenPassingTest() {
    givenRepositoryHasBeenInitialized
    echo "exit 0" > $TCR_TEST_COMMAND
}

givenLastCommitMessageHadMessage() {
    givenRepositoryHasBeenInitialized
    message=$1
    echo "#" >> $TCR_TEST_COMMAND
    git -C $TEST_DIR add $TCR_TEST_COMMAND > /dev/null
    git -C $TEST_DIR commit -m "$message" > /dev/null
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
    git -C $TEST_DIR commit -m "working" > /dev/null
}


assertChangesStashed() {
    stashed=`git -C $TEST_DIR stash list`
    assertContains "$stashed" "WIP on master"
}

assertChangesCommited() {
    last_commit=`git -C $TEST_DIR show -s --format='format:%s'`
    assertContains "$last_commit" "working"
}

assertChangesCommitedWithMessage() {
    message=$1
    last_commit=`git -C $TEST_DIR show -s --format='format:%s'`
    assertEquals "$message" "$last_commit"
}

# runs tests with make test when test command not provided

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
