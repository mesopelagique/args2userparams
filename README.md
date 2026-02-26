# args2userparams

Convert command-line arguments to a structured JSON string, ready to be
passed to **4D** or **tool4D** via the `--user-param` option.

```bash
tool4d --user-param "$(args2userparams --verbose --output=report.txt myDB)"
# tool4d receives: --user-param '{"verbose":true,"output":"report.txt","_":["myDB"]}'
```

Implementations are provided for **Node.js / TypeScript**, **Python**, and
**Bash** so you can call it from any script.

---

## JSON structure

| Input form | JSON key / value |
|---|---|
| `--flag` | `"flag": true` |
| `-f` | `"f": true` |
| `-abc` | `"a": true, "b": true, "c": true` |
| `--key=value` | `"key": "value"` |
| `--key value` | `"key": "value"` |
| `--key v1 --key v2` | `"key": ["v1", "v2"]` |
| `positional` | `"_": ["positional"]` |
| `-- raw args` | forwarded as-is into `"_"` |

### camelCase mode

Pass `--camelcase` (CLI) or `camelCase: true` (library) to convert
kebab-case option names to camelCase keys:

```
--my-flag          →  "myFlag": true
--output-file=a.txt →  "outputFile": "a.txt"
```

---

## Node.js / TypeScript

### Install

```bash
cd nodejs
npm install
npm run build
```

### Library usage

```typescript
import { args2userparams, args2userparamsJSON } from './dist/index';

// Returns a plain object
const parsed = args2userparams(['--verbose', '--output=file.txt', 'arg1']);
// { verbose: true, output: 'file.txt', _: ['arg1'] }

// Returns a JSON string  (ready for --user-param)
const json = args2userparamsJSON(process.argv.slice(2), { camelCase: true });
// '{"verbose":true,"output":"file.txt","_":["arg1"]}'
```

#### API

```typescript
args2userparams(argv: string[], options?: { camelCase?: boolean }): Record<string, unknown>
args2userparamsJSON(argv: string[], options?: { camelCase?: boolean }): string
```

### CLI usage

```bash
# After building (npm run build) the binary is at dist/cli.js
node dist/cli.js [--camelcase] [args...]

# Examples
node dist/cli.js --verbose --output=file.txt arg1
# {"_":["arg1"],"verbose":true,"output":"file.txt"}

node dist/cli.js --camelcase --my-flag --output-file=out.txt
# {"_":[],"myFlag":true,"outputFile":"out.txt"}
```

Set `ARGS2USERPARAMS_CAMELCASE=1` as an alternative to `--camelcase`.

#### Install globally

```bash
npm install -g .
args2userparams --verbose --output=file.txt arg1
```

### Tests

```bash
npm test
```

---

## Python

No external dependencies required (Python 3.6+).

### Library usage

```python
from args2userparams import args2userparams, args2userparams_json
import sys

# Returns a dict
parsed = args2userparams(sys.argv[1:])
# {'verbose': True, 'output': 'file.txt', '_': ['arg1']}

# Returns a JSON string (ready for --user-param)
json_str = args2userparams_json(sys.argv[1:], camel_case=True)
# '{"verbose":true,"output":"file.txt","_":["arg1"]}'
```

#### API

```python
args2userparams(argv: list, camel_case: bool = False) -> dict
args2userparams_json(argv: list, camel_case: bool = False) -> str
```

### CLI usage

```bash
python3 python/args2userparams.py [--camelcase] [args...]

# Examples
python3 python/args2userparams.py --verbose --output=file.txt arg1
# {"verbose":true,"output":"file.txt","_":["arg1"]}

python3 python/args2userparams.py --camelcase --my-flag --output-file=out.txt
# {"myFlag":true,"outputFile":"out.txt","_":[]}
```

Set `ARGS2USERPARAMS_CAMELCASE=1` as an alternative to `--camelcase`.

### Tests

```bash
cd python
python3 -m pytest tests/ -v
```

---

## Bash

Requires Bash 4.0+ (uses associative arrays).

### Source as a function

```bash
source bash/args2userparams.sh

USER_PARAM=$(args2userparams --verbose --output=file.txt arg1)
tool4d --user-param "$USER_PARAM"
```

### CLI usage

```bash
bash bash/args2userparams.sh [--camelcase] [args...]

# Examples
bash bash/args2userparams.sh --verbose --output=file.txt arg1
# {"verbose":true,"output":"file.txt","_":["arg1"]}

bash bash/args2userparams.sh --camelcase --my-flag --output-file=out.txt
# {"myFlag":true,"outputFile":"out.txt","_":[]}
```

Set `ARGS2USERPARAMS_CAMELCASE=1` as an alternative to `--camelcase`.

### Tests

```bash
bash bash/tests/test_args2userparams.sh
```

---

## Real-world example — calling tool4D from a bash script

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/bash/args2userparams.sh"

USER_PARAM=$(args2userparams --camelcase "$@")

tool4d \
  --project MyProject.4DProject \
  --user-param "$USER_PARAM"
```

Then invoke it:

```bash
./run.sh --database=prod --import --file=data.csv
# tool4d … --user-param '{"database":"prod","import":true,"file":"data.csv","_":[]}'
```

---

## License

MIT
