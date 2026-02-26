#!/usr/bin/env bash
# args2userparams.sh - Convert command-line arguments to a JSON string for 4D --user-param
#
# Usage:
#   source args2userparams.sh
#   USER_PARAM=$(args2userparams [--camelcase] [args...])
#   tool4d --user-param "$USER_PARAM"
#
# Or run directly (prints JSON to stdout):
#   bash args2userparams.sh [--camelcase] [args...]
#
# Environment variable alternative:
#   ARGS2USERPARAMS_CAMELCASE=1 bash args2userparams.sh [args...]
#
# Supported argument forms:
#   --flag              Boolean flag           → {"flag":true}
#   -f                  Short boolean flag     → {"f":true}
#   --key=value         Option with value      → {"key":"value"}
#   --key value         Option with value      → {"key":"value"}
#   --key v1 --key v2   Repeated option        → {"key":["v1","v2"]}
#   positional          Positional argument    → {"_":["positional"]}
#
# camelCase conversion (--camelcase or ARGS2USERPARAMS_CAMELCASE=1):
#   --my-flag           → {"myFlag":true}

set -euo pipefail

# ---------------------------------------------------------------------------
# Helper: convert kebab-case to camelCase
# ---------------------------------------------------------------------------
_a2up_camel_case() {
    local input="$1"
    local result=""
    local IFS='-'
    local first=true
    for word in $input; do
        if $first; then
            result="${word}"
            first=false
        else
            result="${result}$(echo "${word:0:1}" | tr '[:lower:]' '[:upper:]')${word:1}"
        fi
    done
    echo "$result"
}

# ---------------------------------------------------------------------------
# Helper: JSON-escape a string value
# ---------------------------------------------------------------------------
_a2up_json_escape() {
    local s="$1"
    # Escape backslashes, double-quotes, and common control characters
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    echo "$s"
}

# ---------------------------------------------------------------------------
# Helper: check whether a string looks like a flag/option (starts with -)
# ---------------------------------------------------------------------------
_a2up_is_flag() {
    [[ "$1" == -* ]]
}

# ---------------------------------------------------------------------------
# Main function
# ---------------------------------------------------------------------------
args2userparams() {
    local camel_case=false
    local -a argv=("$@")

    # Check env var
    if [[ "${ARGS2USERPARAMS_CAMELCASE:-0}" == "1" ]]; then
        camel_case=true
    fi

    # Detect and strip our own --camelcase flag
    local -a filtered=()
    for arg in "${argv[@]}"; do
        if [[ "$arg" == "--camelcase" ]]; then
            camel_case=true
        else
            filtered+=("$arg")
        fi
    done
    argv=("${filtered[@]+"${filtered[@]}"}")

    # Associative array for key→value storage
    declare -A kv_single   # key → single value
    declare -A kv_multiple # key → space-separated list (for arrays)
    declare -A kv_is_array # key → "1" if array
    local -a positional=()
    local end_of_options=false

    local i=0
    local n=${#argv[@]}

    while (( i < n )); do
        local arg="${argv[$i]}"

        if [[ "$end_of_options" == true ]]; then
            positional+=("$arg")
            (( i++ )) || true
            continue
        fi

        if [[ "$arg" == "--" ]]; then
            end_of_options=true
            (( i++ )) || true
            continue
        fi

        if [[ "$arg" =~ ^--([A-Za-z0-9_-]+)=(.*)$ ]]; then
            # --key=value
            local key="${BASH_REMATCH[1]}"
            local val="${BASH_REMATCH[2]}"
            if $camel_case; then key="$(_a2up_camel_case "$key")"; fi
            if [[ -v kv_single["$key"] ]] || [[ -v kv_multiple["$key"] ]]; then
                kv_is_array["$key"]="1"
                kv_multiple["$key"]+=$'\x1f'"$val"
            else
                kv_single["$key"]="$val"
            fi

        elif [[ "$arg" =~ ^--([A-Za-z0-9_-]+)$ ]]; then
            # --key (boolean or --key value)
            local key="${BASH_REMATCH[1]}"
            if $camel_case; then key="$(_a2up_camel_case "$key")"; fi
            local next_i=$(( i + 1 ))
            if (( next_i < n )) && ! _a2up_is_flag "${argv[$next_i]}" && [[ "${argv[$next_i]}" != "--" ]]; then
                local val="${argv[$next_i]}"
                (( i++ )) || true
                if [[ -v kv_single["$key"] ]] || [[ -v kv_multiple["$key"] ]]; then
                    kv_is_array["$key"]="1"
                    kv_multiple["$key"]+=$'\x1f'"$val"
                else
                    kv_single["$key"]="$val"
                fi
            else
                if [[ -v kv_single["$key"] ]] || [[ -v kv_multiple["$key"] ]]; then
                    kv_is_array["$key"]="1"
                    kv_multiple["$key"]+=$'\x1f'"true"
                else
                    kv_single["$key"]="__bool_true__"
                fi
            fi

        elif [[ "$arg" =~ ^-([A-Za-z0-9]+)$ ]]; then
            # Short flags: -v or combined -abc
            local flags="${BASH_REMATCH[1]}"
            local c
            for (( c=0; c<${#flags}; c++ )); do
                local flag="${flags:$c:1}"
                kv_single["$flag"]="__bool_true__"
            done

        else
            positional+=("$arg")
        fi

        (( i++ )) || true
    done

    # Build JSON
    local json="{"
    local first_key=true

    # Emit all parsed keys
    local -a all_keys=()
    for k in "${!kv_single[@]}"; do all_keys+=("$k"); done
    for k in "${!kv_multiple[@]}"; do
        local already=false
        for ek in "${all_keys[@]+"${all_keys[@]}"}"; do
            if [[ "$ek" == "$k" ]]; then already=true; break; fi
        done
        if ! $already; then all_keys+=("$k"); fi
    done

    for key in "${all_keys[@]+"${all_keys[@]}"}"; do
        if ! $first_key; then json+=","; fi
        first_key=false
        local escaped_key
        escaped_key="$(_a2up_json_escape "$key")"
        json+="\"${escaped_key}\":"

        if [[ "${kv_is_array[$key]:-0}" == "1" ]]; then
            # Build array from single value + multiple values
            json+="["
            local arr_first=true
            if [[ -v kv_single["$key"] ]]; then
                local v="${kv_single[$key]}"
                if [[ "$v" == "__bool_true__" ]]; then
                    json+="true"
                else
                    json+="\"$(_a2up_json_escape "$v")\""
                fi
                arr_first=false
            fi
            if [[ -v kv_multiple["$key"] ]]; then
                local IFS=$'\x1f'
                local -a parts
                # skip leading separator
                read -ra parts <<< "${kv_multiple[$key]}"
                for part in "${parts[@]}"; do
                    if [[ -z "$part" ]]; then continue; fi
                    if ! $arr_first; then json+=","; fi
                    arr_first=false
                    if [[ "$part" == "__bool_true__" ]] || [[ "$part" == "true" ]]; then
                        json+="true"
                    else
                        json+="\"$(_a2up_json_escape "$part")\""
                    fi
                done
            fi
            json+="]"
        else
            local v="${kv_single[$key]:-}"
            if [[ "$v" == "__bool_true__" ]]; then
                json+="true"
            else
                json+="\"$(_a2up_json_escape "$v")\""
            fi
        fi
    done

    # Positional args → "_"
    if ! $first_key; then json+=","; fi
    json+="\"_\":["
    local first_pos=true
    for pos in "${positional[@]+"${positional[@]}"}"; do
        if ! $first_pos; then json+=","; fi
        first_pos=false
        json+="\"$(_a2up_json_escape "$pos")\""
    done
    json+="]}"

    echo "$json"
}

# Run as script (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    args2userparams "$@"
fi
