import { args2userparams, args2userparamsJSON } from '../src/index';

describe('args2userparams', () => {
  describe('flags', () => {
    it('parses a long boolean flag', () => {
      expect(args2userparams(['--verbose'])).toEqual({ _: [], verbose: true });
    });

    it('parses a short boolean flag', () => {
      expect(args2userparams(['-v'])).toEqual({ _: [], v: true });
    });

    it('parses multiple short flags combined', () => {
      expect(args2userparams(['-abc'])).toEqual({ _: [], a: true, b: true, c: true });
    });
  });

  describe('options with values', () => {
    it('parses --key=value syntax', () => {
      expect(args2userparams(['--output=file.txt'])).toEqual({
        _: [],
        output: 'file.txt',
      });
    });

    it('parses --key value syntax', () => {
      expect(args2userparams(['--output', 'file.txt'])).toEqual({
        _: [],
        output: 'file.txt',
      });
    });
  });

  describe('repeated options', () => {
    it('converts repeated options into an array', () => {
      const result = args2userparams(['--tag', 'foo', '--tag', 'bar']);
      expect(result).toEqual({ _: [], tag: ['foo', 'bar'] });
    });
  });

  describe('positional arguments', () => {
    it('puts positional args in _', () => {
      expect(args2userparams(['arg1', 'arg2'])).toEqual({ _: ['arg1', 'arg2'] });
    });

    it('mixes flags, options, and positional args', () => {
      const result = args2userparams([
        '--verbose',
        '--output=out.txt',
        'file1',
        'file2',
      ]);
      expect(result).toEqual({
        _: ['file1', 'file2'],
        verbose: true,
        output: 'out.txt',
      });
    });
  });

  describe('camelCase option', () => {
    it('keeps kebab-case by default', () => {
      expect(args2userparams(['--my-flag'])).toMatchObject({ 'my-flag': true });
    });

    it('converts kebab-case to camelCase when enabled', () => {
      const result = args2userparams(['--my-flag', '--output-file=out.txt'], {
        camelCase: true,
      });
      expect(result).toMatchObject({ myFlag: true, outputFile: 'out.txt' });
    });
  });

  describe('empty input', () => {
    it('returns object with empty _ array for no args', () => {
      expect(args2userparams([])).toEqual({ _: [] });
    });
  });
});

describe('args2userparamsJSON', () => {
  it('returns valid JSON string', () => {
    const json = args2userparamsJSON(['--verbose', '--output=file.txt', 'arg1']);
    const parsed = JSON.parse(json);
    expect(parsed).toEqual({ _: ['arg1'], verbose: true, output: 'file.txt' });
  });

  it('works with camelCase option', () => {
    const json = args2userparamsJSON(['--my-flag'], { camelCase: true });
    const parsed = JSON.parse(json);
    expect(parsed).toMatchObject({ myFlag: true });
  });
});
