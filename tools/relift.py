"""
relift.py - Regenerate Space Bucks' lifted tree from your own copy of the game.

Everything below work/ is derived from SPACEBUC.EXE and is never
committed. One command, so a re-lift cannot silently skip a step:

    python tools/relift.py

No IDA: pcrecomp builds each module's code map itself (tools/ne/ne_codemap.py,
the default inside ne_link).

What it runs, all from pcrecomp (PCRECOMP_DIR, default ../pcrecomp, branch pcrecomp-ne-spacebucks):
  ne/wine_spec_to_json.py  work/win16_imports.json, the Win16 API names by
                      ordinal, from Wine's .spec files (LGPL, so built here
                      and never committed); skipped once it exists
  ne/ne_link.py       lift both modules into one numbering, build the image,
                      and regenerate the glue (segments.h, dispatch, stubs)
  ne/patch_borland_eh.py  the Borland EH cleanup-chain guard
"""
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
PC = os.path.abspath(os.environ.get('PCRECOMP_DIR', os.path.join(ROOT, '..', 'pcrecomp')))
MODULES = ['game/SPACEBUC.EXE']


def run(*cmd):
    print('>', ' '.join(cmd), flush=True)
    subprocess.run(cmd, cwd=ROOT, check=True)


def main():
    imports = os.path.join(ROOT, 'work', 'win16_imports.json')
    if not os.path.exists(imports):
        os.makedirs(os.path.dirname(imports), exist_ok=True)
        run(sys.executable, os.path.join(PC, 'tools', 'ne', 'wine_spec_to_json.py'), '-o', imports)
    run(sys.executable, os.path.join(PC, 'tools', 'ne', 'ne_link.py'),
        '--work', 'work',
        '--prefix', 'recomp',
        '--shims', os.path.join(PC, 'runtime', 'win16', 'host'), '--shims', 'runtime',
        *MODULES)
    run(sys.executable, os.path.join(PC, 'tools', 'ne', 'patch_borland_eh.py'),
        '--work', 'work', *MODULES)


if __name__ == '__main__':
    main()
