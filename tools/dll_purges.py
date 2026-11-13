"""dll_purges.py - names and stack purges of a Win16 DLL's exports, read off
the DLL itself: each export's name from the NE name tables, and its purge from
the first `retf N` its code reaches (PASCAL: the callee pops N bytes).

    py -3 tools/dll_purges.py game/SMACKW16.DLL game/WAIL16.DLL

Prints {MODULE: {ordinal: [name, purge]}}; a purge of None means no retf was
found by a straight scan (check it by hand).
"""
import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'pcrecomp', 'tools', 'ne'))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'pcrecomp', 'tools'))
from capstone import Cs, CS_ARCH_X86, CS_MODE_16   # noqa: E402
from ne_parse import parse_ne                        # noqa: E402


def purge_of(code, off):
    """The N of the first retf the code from `off` reaches, following jumps."""
    md = Cs(CS_ARCH_X86, CS_MODE_16)
    seen, todo = set(), [off]
    while todo:
        a = todo.pop(0)
        if a in seen or a >= len(code):
            continue
        seen.add(a)
        for i in md.disasm(code[a:a + 0x4000], a):
            if i.mnemonic == 'retf':
                return int(i.op_str, 0) if i.op_str else 0
            if i.mnemonic == 'jmp' and i.op_str.startswith('0x'):
                todo.append(int(i.op_str, 16))
                break
            if i.mnemonic in ('ret', 'iret', 'jmp'):
                break
            if i.mnemonic.startswith('j') and i.op_str.startswith('0x'):
                todo.append(int(i.op_str, 16))
    return None


def main():
    out = {}
    for path in sys.argv[1:]:
        ne = parse_ne(path)
        data = open(path, 'rb').read()
        names = {o: n for n, o in ne.resident_names + ne.nonresident_names}
        mod = {}
        for e in ne.entries:
            s = ne.seg(e.segment)
            code = data[s.file_offset:s.file_offset + s.actual_size]
            mod[e.ordinal] = [names.get(e.ordinal, ''), purge_of(code, e.offset)]
        out[ne.module_name] = mod
    print(json.dumps(out, indent=1))


if __name__ == '__main__':
    main()
