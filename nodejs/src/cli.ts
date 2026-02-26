#!/usr/bin/env node
/**
 * CLI entry point.
 *
 * Usage:
 *   args2userparams [--camelcase] [args...]
 *
 * The optional --camelcase flag (consumed by this wrapper) converts
 * kebab-case option names to camelCase in the JSON output.
 * All other arguments are forwarded to the parser and emitted as JSON.
 *
 * Environment variable alternative: set ARGS2USERPARAMS_CAMELCASE=1
 *
 * Examples:
 *   args2userparams --verbose --output=file.txt arg1
 *   # → {"verbose":true,"output":"file.txt","_":["arg1"]}
 *
 *   args2userparams --camelcase --my-flag --output-file=out.txt
 *   # → {"myFlag":true,"outputFile":"out.txt","_":[]}
 */

import { args2userparamsJSON } from './index';

const argv = process.argv.slice(2);

// Detect and strip our own --camelcase flag before forwarding
const camelCaseIdx = argv.indexOf('--camelcase');
const camelCase =
  camelCaseIdx !== -1 || process.env['ARGS2USERPARAMS_CAMELCASE'] === '1';

if (camelCaseIdx !== -1) {
  argv.splice(camelCaseIdx, 1);
}

process.stdout.write(args2userparamsJSON(argv, { camelCase }) + '\n');
