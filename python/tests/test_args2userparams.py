"""Tests for args2userparams Python implementation."""

import json
import sys
import os
import unittest

# Allow running from repo root or from python/ directory
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from args2userparams import args2userparams, args2userparams_json


class TestFlags(unittest.TestCase):
    def test_long_boolean_flag(self):
        self.assertEqual(args2userparams(['--verbose']), {'verbose': True, '_': []})

    def test_short_boolean_flag(self):
        self.assertEqual(args2userparams(['-v']), {'v': True, '_': []})

    def test_combined_short_flags(self):
        self.assertEqual(
            args2userparams(['-abc']),
            {'a': True, 'b': True, 'c': True, '_': []},
        )


class TestOptions(unittest.TestCase):
    def test_key_equals_value(self):
        self.assertEqual(
            args2userparams(['--output=file.txt']),
            {'output': 'file.txt', '_': []},
        )

    def test_key_space_value(self):
        self.assertEqual(
            args2userparams(['--output', 'file.txt']),
            {'output': 'file.txt', '_': []},
        )


class TestRepeatedOptions(unittest.TestCase):
    def test_repeated_option_becomes_array(self):
        self.assertEqual(
            args2userparams(['--tag', 'foo', '--tag', 'bar']),
            {'tag': ['foo', 'bar'], '_': []},
        )


class TestPositionalArgs(unittest.TestCase):
    def test_positional_args_in_underscore(self):
        self.assertEqual(
            args2userparams(['arg1', 'arg2']),
            {'_': ['arg1', 'arg2']},
        )

    def test_mixed_args(self):
        self.assertEqual(
            args2userparams(['--verbose', '--output=out.txt', 'file1', 'file2']),
            {'verbose': True, 'output': 'out.txt', '_': ['file1', 'file2']},
        )

    def test_double_dash_separator(self):
        result = args2userparams(['--verbose', '--', '--not-a-flag', 'positional'])
        self.assertEqual(result['verbose'], True)
        self.assertIn('--not-a-flag', result['_'])
        self.assertIn('positional', result['_'])


class TestCamelCase(unittest.TestCase):
    def test_kebab_case_kept_by_default(self):
        result = args2userparams(['--my-flag'])
        self.assertIn('my-flag', result)

    def test_kebab_case_to_camel_case(self):
        result = args2userparams(['--my-flag', '--output-file=out.txt'], camel_case=True)
        self.assertEqual(result.get('myFlag'), True)
        self.assertEqual(result.get('outputFile'), 'out.txt')


class TestEmptyInput(unittest.TestCase):
    def test_empty_returns_only_underscore(self):
        self.assertEqual(args2userparams([]), {'_': []})


class TestJSON(unittest.TestCase):
    def test_returns_valid_json(self):
        j = args2userparams_json(['--verbose', '--output=file.txt', 'arg1'])
        parsed = json.loads(j)
        self.assertEqual(parsed['verbose'], True)
        self.assertEqual(parsed['output'], 'file.txt')
        self.assertEqual(parsed['_'], ['arg1'])

    def test_camel_case_json(self):
        j = args2userparams_json(['--my-flag'], camel_case=True)
        parsed = json.loads(j)
        self.assertEqual(parsed.get('myFlag'), True)


if __name__ == '__main__':
    unittest.main()
