# Contributing

Issues and pull requests are welcome.

## The one rule

**Nothing from the game goes in the repository.** No game files, no lifted C
(`work/`), no import maps or catalogs generated on your machine, no
disassembly listings, nothing generated from `SPACEBUC.EXE`. The tool ships;
its output is made on each person's machine from their own copy. `.gitignore`
covers the usual paths; check `git status` before you commit anyway.
Screenshots of the game running are fine.

## Before a pull request

1. Lift and build from clean: `py -3 tools\relift.py` (17,668 functions,
   0 unresolved calls), then `cmake --build build` ([docs/building.md](docs/building.md)).
2. There is no conformance harness yet. Run the scripted New Game walk
   (`RECOMP_INPUT`, docs/building.md) on a virtual monitor and check it still
   reaches the play screen; say what you ran in the PR.

## Where a fix belongs

- A bug in the NE lifter, the code map or the Win16 host belongs in
  [pcrecomp](https://github.com/sp00nznet/pcrecomp), not here.
- A shim for a DLL the game ships (Miles, BWCC, Smacker) belongs here, in
  `runtime/`.
- A wall you got past goes in `docs/bringup.md`: what it looked like, what it
  was, what moved it.
