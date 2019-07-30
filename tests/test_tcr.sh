#! /bin/sh

test_shows_usage_info_when_no_args() {
    result=`$TCR`

    assertFalse $?
    assertEquals "Usage: tcr {red,green} [msg]" "$result"
}

# stashes changes when failure and expects green
# stashes changes when success and expects red
# commits changes when failure and expects red
# commits changes when success and expects green

oneTimeSetUp() {
    TCR=$(dirname $(dirname $0))/tcr
    TCR=`realpath $TCR`
}

# Load shUnit2
source `dirname $0`/shunit2
