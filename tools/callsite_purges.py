"""callsite_purges.py - the argument bytes each Win16 import's call sites push,
read off the lifted C (work/src): the pushes since the previous call, minus the
far return frame. Prints MODULE.API, the sizes seen (most common first), and
pcrecomp's purge for it, flagging disagreements.

    py -3 tools/callsite_purges.py SMACKW16 WAIL16
"""
import collections, glob, os, re, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'pcrecomp', 'tools', 'ne'))
import win16  # noqa: E402

mods = [m.upper() for m in sys.argv[1:]]
call = re.compile(r'^\s*([A-Z0-9]+)_([A-Z0-9_]+)\(cpu\);')
seen = collections.defaultdict(collections.Counter)
for f in glob.glob('work/src/seg*.c'):
    n = 0
    for line in open(f, encoding='utf-8', errors='replace'):
        m = call.match(line)
        if m and m.group(1) in mods:
            seen[(m.group(1), m.group(2))][n - 4] += 1
        if m or re.match(r'^\s*seg\d+_[0-9A-F]+\(cpu\);', line) or line.startswith('void ') or line.startswith('}'):
            n = 0
        n += 2 * line.count('push16(') + 4 * line.count('push32(')
for (mod, api), c in sorted(seen.items()):
    p = win16.get_purge(mod, api)
    best = c.most_common(1)[0][0]
    print('%-40s %-14s purge %-4s %s' % (mod + '.' + api, dict(c), p, '' if p == best else '<-- differs'))
