#!/usr/bin/env python3
"""
args2userparams - Convert command-line arguments to a JSON string for 4D --user-param.

Usage as a library:
    from args2userparams import args2userparams, args2userparams_json
    import sys

    result = args2userparams(sys.argv[1:], camel_case=False)
    json_str = args2userparams_json(sys.argv[1:], camel_case=False)

Usage as a CLI:
    python3 args2userparams.py [args...]

    To enable camelCase conversion, use the library API directly:
        from args2userparams import args2userparams_json
        args2userparams_json(argv, camel_case=True)

Supported argument forms:
    --flag              Boolean flag           → {"flag": true}
    -f                  Short boolean flag     → {"f": true}
    -abc                Combined short flags   → {"a": true, "b": true, "c": true}
    --key=value         Option with value      → {"key": "value"}
    --key value         Option with value      → {"key": "value"}
    --key val1 \\
    --key val2          Repeated option        → {"key": ["val1", "val2"]}
    positional          Positional argument    → {"_": ["positional"]}

camelCase conversion (library only):
    args2userparams_json(argv, camel_case=True)
    --my-flag           → {"myFlag": true}
"""

import json
import re
import sys
from typing import Any


def _to_camel_case(name: str) -> str:
    """Convert a kebab-case string to camelCase."""
    parts = name.split('-')
    return parts[0] + ''.join(word.capitalize() for word in parts[1:])


def _set_value(result: dict, key: str, value: Any) -> None:
    """Set a key in result, converting to list on duplicates."""
    if key in result:
        existing = result[key]
        if isinstance(existing, list):
            existing.append(value)
        else:
            result[key] = [existing, value]
    else:
        result[key] = value


def args2userparams(argv: list, camel_case: bool = False) -> dict:
    """
    Parse a list of argument strings into a structured dictionary.

    :param argv:       List of argument strings (e.g. sys.argv[1:])
    :param camel_case: Convert kebab-case keys to camelCase
    :returns:          Dictionary with parsed arguments; positional args
                       are stored under the ``_`` key.
    """
    result: dict = {}
    positional: list = []
    i = 0

    def normalise_key(k: str) -> str:
        return _to_camel_case(k) if camel_case else k

    while i < len(argv):
        arg = argv[i]

        if arg == '--':
            # Everything after bare -- is positional
            positional.extend(argv[i + 1:])
            break

        if arg.startswith('--') and len(arg) > 2:
            body = arg[2:]
            if '=' in body:
                k, v = body.split('=', 1)
                _set_value(result, normalise_key(k), v)
            else:
                # Peek ahead: if next token is not a flag/option, treat as value
                if (
                    i + 1 < len(argv)
                    and not argv[i + 1].startswith('-')
                    and argv[i + 1] != '--'
                ):
                    _set_value(result, normalise_key(body), argv[i + 1])
                    i += 1
                else:
                    _set_value(result, normalise_key(body), True)

        elif re.match(r'^-[A-Za-z0-9]+$', arg):
            # Short flags: -v or combined -abc
            for flag in arg[1:]:
                _set_value(result, flag, True)

        else:
            positional.append(arg)

        i += 1

    result['_'] = positional
    return result


def args2userparams_json(argv: list, camel_case: bool = False) -> str:
    """
    Serialise command-line arguments to a JSON string.

    :param argv:       List of argument strings (e.g. sys.argv[1:])
    :param camel_case: Convert kebab-case keys to camelCase
    :returns:          JSON string
    """
    return json.dumps(args2userparams(argv, camel_case=camel_case),
                      separators=(',', ':'))


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

if __name__ == '__main__':
    print(args2userparams_json(sys.argv[1:]))
