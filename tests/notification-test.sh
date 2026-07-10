#!/usr/bin/env bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export CONFIG_FILE="$PROJECT_ROOT/tests/test-config.conf"

source "$PROJECT_ROOT/scripts/common.sh"


PASS=0
FAIL=0


assert_email()
{
    local EVENT="$1"
    local FILE="$2"
    local EXPECTED="$3"

    if should_send_email "$EVENT" "$FILE"; then
        RESULT=0
    else
        RESULT=1
    fi


    if [ "$RESULT" -eq "$EXPECTED" ]; then
        echo "PASS: $EVENT $FILE"
        PASS=$((PASS+1))
    else
        echo "FAIL: $EVENT $FILE (expected $EXPECTED got $RESULT)"
        FAIL=$((FAIL+1))
    fi
}


echo "Notification Engine Tests"
echo "=========================="


assert_email "CREATE" "/tmp/test.php" 0

assert_email "MODIFY" "/tmp/test.php" 0

assert_email "ATTRIB" "/tmp/test.php" 1

assert_email "CREATE" "/tmp/test.pdf" 1

assert_email "ATTRIB" "/tmp/wp-config.php" 0


echo
echo "Passed: $PASS"
echo "Failed: $FAIL"


if [ "$FAIL" -gt 0 ]; then
    exit 1
fi

exit 0
