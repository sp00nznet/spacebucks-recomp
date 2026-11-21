# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.0] - 2026-11-20

### Removed
- `analysis/win16_imports.json` is no longer in the repository: it is derived
  from Wine's LGPL `.spec` files. `tools/relift.py` builds it into
  `work/win16_imports.json` on the first lift.

### Changed
- Builds against pcrecomp main; the `pcrecomp-ne-spacebucks` branch is merged.
- Repository conformance: README in the house order, `NOTICE.md` (replacing
  `NOTICE`), `CONTRIBUTING.md`, `CONTRIBUTORS.md`, `docs/building.md`, a
  `setup.sh` that says Linux and macOS are not supported yet;
  `docs/lifting.md` is now `docs/bringup.md`. Setup and the docs name one
  toolkit branch, `pcrecomp-ne-spacebucks`.

### Added
- In game: real (simulated) clicks walk New Game through company, color, race
  and difficulty into the running game. `RECOMP_INPUT` scripts them, e.g.
  `12:150,119;3:149,198;3:149,229;3:150,262;3:150,119`.
- New Game reaches the main play screen. The toolkit now opens dialogs by name
  (`OPEN0`, `CGDIALOG_11`, `MESSAGE`); before, the opening menu drew only its
  background. pcrecomp branch `pcrecomp-ne-spacebucks`.

### Changed
- The lift needs no IDA: pcrecomp's `pcrecomp-ne-nativemap` branch builds the
  code map itself (`tools/ne/ne_codemap.py`). `tools/relift.py` lost `--ida`,
  `Setup.cmd` no longer checks for idalib, and it runs through the credits to the opening menu as before (17,668 functions, 0 unresolved calls).
- The Win16 ordinal map is built from Wine's 16-bit `.spec` files (pcrecomp
  `tools/ne/wine_spec_to_json.py`) instead of IDA's `.idt` files; every
  ordinal the game imports has the same name in both.

### Added
- `Setup.cmd` (`tools/setup.ps1`): checks and offers to install the tools,
  copies your CD into `game\`, lifts, builds and leaves a `Space Bucks.cmd` shortcut.
  `launcher/launcher.json` for recomp-launcher, and a manual-only
  `installer` workflow.

### Changed
- README in the pcrecomp house style.

## [0.1.0] - 2026-11-08

### Added
- First boot: `SPACEBUC.EXE` lifted (17,461 functions) on pcrecomp's Win16
  host. Logo, credits with palette fades, title, and the opening menu dialog.
- A silent Miles (WAIL16) driver and BWCC's DialogBox (`runtime/sierra_dlls.c`).
- `tools/dll_purges.py`, `tools/callsite_purges.py`; `docs/lifting.md`.
- Toolkit fixes in pcrecomp#167: imports by name, WinG and palette calls,
  WM_CREATE, tiled reuse of huge blocks.
