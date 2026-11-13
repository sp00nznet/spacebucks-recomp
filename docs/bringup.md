# Lifting Space Bucks: what it took

The layout is Catz's: pcrecomp's `ne_link` lifts the NE module into one tree,
and pcrecomp's Win16 host (`runtime/win16/host`) answers the Windows 3.1 API
with Win32. What follows is what this game needed on top, in the order it
turned up. The toolkit half is pcrecomp#167 (branch `pcrecomp-ne-spacebucks`).

## 1. Imports by name

Smacker (`SMACKW16`) and Miles (`WAIL16`) are imported **by name**: the NE
relocation's ordinal field is an offset into the importer's name table. The
lifter read it as an ordinal, so `SmackOpen` became `SMACKW16.Ord81` with no
purge. The name is now resolved.

Win16 is PASCAL: the callee pops its arguments, and a shim that pops the wrong
number shifts the caller's frame. Purges for the ten shipped DLL's exports
came from each export's `retf N` (`tools/dll_purges.py`) and were checked
against the game's own call sites (`tools/callsite_purges.py`); where the two
disagreed, the documented prototype decided.

## 2. A code map

A linear sweep missed functions (`near MISS seg1:3D0E`). IDA's map found
them first; pcrecomp's own (`tools/ne/ne_codemap.py`, the default now) finds
them too: 0 unresolved calls, and the same run to the opening menu.

## 3. The sound drivers

The game asks `waveOutGetNumDevs` and quits on 0 ("No wave devices!"), then
drives Miles. `runtime/sierra_dlls.c` is a silent Miles: the driver opens,
sample handles are real, every sample is done as soon as it starts.

## 4. WM_CREATE

The host never forwarded `WM_CREATE` (Win32's carries a host pointer). Space
Bucks makes its WinG surface, its timer and its palette there, so without it
the frame pointer stayed NULL and the first credit page was `hmemcpy`'d,
275 KB, over low memory, the stack's saved DS included. The next `sprintf` ran
with DS=0 and copied its format string out unformatted
(`%s%sdata\credit1.lbm`). The host now sends it, opt-in
(`RecompGame.create_message`).

## 5. WinG and the palette

`WinGGetDIBPointer`, `WinGSetDIBColorTable`, `WinGBitBlt`,
`GetPaletteEntries` / `SetPaletteEntries` / `AnimatePalette` (the credits
fade with it) and `GetWindowDC` were stubs returning 0.

## 6. Reused huge blocks had no tiles

Win16 reaches the second 64 KB of a huge block through `sel+1`. The host's
fresh allocations get those tiles; a block reused from the free list did not,
so `sel+1` was whatever selector came next. The game's file reader `_lread`s
32 KB at a time through a huge pointer, and the fourth chunk of
`credit4.lbm` landed in an unrelated block just below the stack: BP came back
as `37FC`, and the LBM decoder filled 128 KB of code segment 27 (the game's
string constants) with one color. Found with the host's selector watch
(`RECOMP_WATCH_SEL=1B`), then by checking BP at each function entry of the
decoder.

## 7. BWCC

Borland's BWCC.DLL #2 is its `DialogBox`, with USER's arguments: every game
dialog (`OPEN0`, `MESSAGE`, ...) goes through it, so it forwards to the host's.

## Debugging aids

| | |
|---|---|
| `RECOMP_INPUT="12:150,119;3:149,198;..."` | scripted clicks (`X,Y` client of the topmost window) and keys (`kVK`), each after a delay in seconds; the example walks New Game into play |
| `RECOMP_WATCHDOG_SECS=N` | end the run after N seconds |
| `RECOMP_DISPATCH_STRICT=1` | stop at the first unresolved call, with the function ring and a host backtrace |
| `RECOMP_WATCH_SEL=sel`, `RECOMP_WATCH_LO/HI=off` | who writes a range of a selector |
| `tools/callsite_purges.py MODULE...` | bytes pushed at each import's call sites vs the purge used |
