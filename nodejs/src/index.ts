import yargsParser from 'yargs-parser';

/** Options for args2userparams */
export interface Args2UserParamsOptions {
  /** Convert kebab-case flags/options to camelCase keys (default: false) */
  camelCase?: boolean;
}

/**
 * Convert an array of command-line argument strings into a structured JSON
 * object suitable for passing to 4D via --user-param.
 *
 * - Boolean flags  : `--verbose` / `-v`       → `{ "verbose": true }`
 * - Key=value      : `--output=file.txt`       → `{ "output": "file.txt" }`
 * - Key space value: `--output file.txt`       → `{ "output": "file.txt" }`
 * - Repeated option: `--tag foo --tag bar`     → `{ "tag": ["foo", "bar"] }`
 * - Positional args: `arg1 arg2`               → `{ "_": ["arg1", "arg2"] }`
 * - camelCase mode : `--my-flag`               → `{ "myFlag": true }`
 *
 * @param argv    Array of argument strings (e.g. process.argv.slice(2))
 * @param options Conversion options
 * @returns       A plain object ready to be JSON-serialised
 */
export function args2userparams(
  argv: string[],
  options: Args2UserParamsOptions = {}
): Record<string, unknown> {
  const camelCase = options.camelCase ?? false;

  const parsed = yargsParser(argv, {
    configuration: {
      'camel-case-expansion': camelCase,
      'duplicate-arguments-array': true,
      'flatten-duplicate-arrays': true,
      'greedy-arrays': false,
    },
  }) as Record<string, unknown>;

  if (!camelCase) {
    return parsed;
  }

  // When camelCase is enabled, yargs-parser keeps BOTH the original kebab-case
  // key AND the new camelCase key.  Remove the kebab-case duplicates so that
  // only the camelCase version is present in the output.
  const toCamelCase = (s: string): string =>
    s.replace(/-([a-z])/g, (_, c: string) => c.toUpperCase());

  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(parsed)) {
    const camelKey = toCamelCase(key);
    // Skip the original kebab-case key if its camelCase form is already present
    if (key.includes('-') && camelKey in parsed) {
      continue;
    }
    result[key] = value;
  }
  return result;
}

/**
 * Serialise command-line arguments to a JSON string ready for --user-param.
 *
 * @param argv    Array of argument strings (e.g. process.argv.slice(2))
 * @param options Conversion options
 * @returns       JSON string
 */
export function args2userparamsJSON(
  argv: string[],
  options: Args2UserParamsOptions = {}
): string {
  return JSON.stringify(args2userparams(argv, options));
}
