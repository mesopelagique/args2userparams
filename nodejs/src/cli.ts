#!/usr/bin/env node
/**
 * CLI entry point.
 *
 * Usage:
 *   args2userparams [args...]
 *
 * All arguments are parsed and emitted as a JSON string to stdout.
 * To enable camelCase conversion, use the library API directly:
 *   import { args2userparamsJSON } from 'args2userparams';
 *   args2userparamsJSON(argv, { camelCase: true });
 *
 * Examples:
 *   args2userparams --verbose --output=file.txt arg1
 *   # → {"verbose":true,"output":"file.txt","_":["arg1"]}
 *
 *   args2userparams --tag foo --tag bar
 *   # → {"tag":["foo","bar"],"_":[]}
 */

import { args2userparamsJSON } from './index';

const argv = process.argv.slice(2);

process.stdout.write(args2userparamsJSON(argv) + '\n');

