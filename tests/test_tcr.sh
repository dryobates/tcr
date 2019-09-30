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

    $TCR green > /dev/null

    assertFalse $?
}

test_exits_with_success_when_failure_and_expected_red() {
    givenFailingTest

    $TCR red > /dev/null

    assertTrue $?
}

test_exits_with_error_when_success_and_expected_red() {
    givenPassingTest

    $TCR red > /dev/null

    assertFalse $?
}

test_exits_with_success_when_success_and_expected_green() {
    givenPassingTest

    $TCR green > /dev/null

    assertTrue $?
}

test_stashes_changes_when_failure_and_expected_green() {
    givenFailingTest

    $TCR green > /dev/null

    assertChangesStashed
}

test_stashes_changes_when_success_and_expected_red() {
    givenPassingTest

    $TCR red > /dev/null

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

    $TCR red > /dev/null

    assertChangesCommited
}

test_commits_changes_when_success_and_expected_green() {
    givenPassingTest

    $TCR green > /dev/null

    assertChangesCommited
}

test_commits_changes_with_T_prefix_when_failure_and_expected_red() {
    givenFailingTest

    $TCR red > /dev/null

    assertChangesCommitedWithMessage "T working"
}

test_commits_changes_with_B_prefix_when_success_and_expected_green() {
    givenPassingTest

    $TCR green > /dev/null

    assertChangesCommitedWithMessage "B working"
}

test_commits_changes_with_S_prefix_when_success_expected_green_and_last_commit_was_with_B_or_S_prefix() {
    givenLastCommitMessageHadMessage "B working"
    givenPassingTest

    $TCR green > /dev/null

    assertChangesCommitedWithMessage "S working"
}

test_commits_changes_with_given_message_when_failure_and_expected_red() {
    givenFailingTest
    message="custom message"

    $TCR red $message > /dev/null

    assertChangesCommitedWithMessage "T $message"
}

test_commits_changes_with_given_message_when_success_and_expected_green() {
    givenPassingTest
    message="custom message"

    $TCR green $message > /dev/null

    assertChangesCommitedWithMessage "B $message"
}

test_commits_changes_with_last_message_but_different_prefix_when_success_and_expected_green() {
    givenLastCommitMessageHadMessage "T custom message"
    givenPassingTest

    $TCR green > /dev/null

    assertChangesCommitedWithMessage "B custom message"
}

test_commits_changes_with_default_message_when_failure_expected_red() {
    givenLastCommitMessageHadMessage "S some message"
    givenFailingTest

    $TCR red > /dev/null

    assertChangesCommitedWithMessage "T working"
}

test_runs_tests_with_make_test_when_test_command_not_provided() {
    givenFailingTest
    givenTestCommandIsMakeTest

    $TCR red &> /dev/null

    assertChangesCommitedWithMessage "T working"
}

test_finds_repo_in_current_directory() {
    git init  -q $TEST_DIR > /dev/null
    result=`find_repo $PWD`
    assertTrue $?
}

test_finds_repo_in_parent_directory() {
    git init  -q $TEST_DIR > /dev/null
    mkdir subdir && cd subdir
    result=`find_repo $PWD`
    assertTrue $?
}

test_finds_repo_in_ancestors_directory() {
    git init  -q $TEST_DIR > /dev/null
    mkdir -p subdir/subsubdir && cd subdir/subsubdir
    result=`find_repo $PWD`
    assertTrue $?
}

test_returns_false_when_no_repo_up_to_root() {
    result=`find_repo $PWD`
    assertFalse $?
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

givenTestCommandIsMakeTest() {
    mv $TCR_TEST_COMMAND $TEST_DIR/Makefile
    makefile="test:
	exit 1"
    echo "$makefile" > $TEST_DIR/Makefile
    unset TCR_TEST_COMMAND
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

oneTimeSetUp() {
    TCR=$(dirname $(dirname $0))/tcr
    TCR=`realpath $TCR`
    TCR_TESTING="unit"
    source "$TCR"
    set +e
    unset TCR_TESTING
}

setUp() {
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
echo "source $(dirname $(realpath $0))/shunit2"
source $(dirname $(realpath $0))/shunit2
