#!/usr/bin/env bash
# Tests for args2userparams.sh
# Run: bash tests/test_args2userparams.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
A2UP="${SCRIPT_DIR}/../args2userparams.sh"

pass=0
fail=0

assert_eq() {
    local desc="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo "PASS: $desc"
        (( pass++ )) || true
    else
        echo "FAIL: $desc"
        echo "  expected: $expected"
        echo "  actual:   $actual"
        (( fail++ )) || true
    fi
}

assert_contains() {
    local desc="$1"
    local needle="$2"
    local haystack="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "PASS: $desc"
        (( pass++ )) || true
    else
        echo "FAIL: $desc"
        echo "  expected to contain: $needle"
        echo "  actual: $haystack"
        (( fail++ )) || true
    fi
}

# --- Flags ---
assert_eq "long boolean flag" \
    '{"verbose":true,"_":[]}' \
    "$(bash "$A2UP" --verbose)"

assert_eq "short boolean flag" \
    '{"v":true,"_":[]}' \
    "$(bash "$A2UP" -v)"

# --- Options with values ---
assert_eq "key=value syntax" \
    '{"output":"file.txt","_":[]}' \
    "$(bash "$A2UP" --output=file.txt)"

assert_eq "key space value syntax" \
    '{"output":"file.txt","_":[]}' \
    "$(bash "$A2UP" --output file.txt)"

# --- Repeated options ---
assert_eq "repeated option becomes array" \
    '{"tag":["foo","bar"],"_":[]}' \
    "$(bash "$A2UP" --tag foo --tag bar)"

# --- Positional args ---
assert_eq "positional args in _" \
    '{"_":["arg1","arg2"]}' \
    "$(bash "$A2UP" arg1 arg2)"

# --- camelCase (via env var, code-level configuration) ---
result="$(ARGS2USERPARAMS_CAMELCASE=1 bash "$A2UP" --my-flag)"
assert_contains "env var camelCase: --my-flag → myFlag" '"myFlag":true' "$result"

result="$(ARGS2USERPARAMS_CAMELCASE=1 bash "$A2UP" --output-file=out.txt)"
assert_contains "env var camelCase: --output-file → outputFile" '"outputFile":"out.txt"' "$result"

# --- double-dash separator ---
result="$(bash "$A2UP" --verbose -- --not-a-flag positional)"
assert_contains "double-dash: verbose is true" '"verbose":true' "$result"
assert_contains "double-dash: --not-a-flag is positional" '"--not-a-flag"' "$result"

# --- empty ---
assert_eq "empty input" \
    '{"_":[]}' \
    "$(bash "$A2UP")"

echo ""
echo "Results: ${pass} passed, ${fail} failed"
[[ $fail -eq 0 ]]
