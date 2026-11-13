# Building by hand

`Setup.cmd` (`tools/setup.ps1`) runs exactly these steps; this is the same
thing, command for command.

## Prerequisites

Windows 10/11, **Python 3.10+** (`py -3 --version`) with `capstone`,
**CMake** 3.16+, **Ninja**, **MSYS2** with `mingw-w64-x86_64-gcc`
(`C:\msys64\mingw64\bin\gcc.exe`), **git**, and pcrecomp cloned **beside**
this repository as `pcrecomp`, on branch **`pcrecomp-ne-spacebucks`** (or
point `PCRECOMP_DIR` at it). `main` lacks this game's host fixes.

```
some-folder\
  pcrecomp\            <- git clone -b pcrecomp-ne-spacebucks https://github.com/sp00nznet/pcrecomp
  spacebucks-recomp\   <- this repository
```

## Steps

1. `py -3 -m pip install --user capstone`
2. Copy the CD's `HD` folder into `game\`, then merge `DATA`, `VIDEO` and
   `WAV` into it (`game\DATA` gets both halves), and add the INI:
   ```
   robocopy E:\HD game /E
   robocopy E:\DATA game\DATA /E
   robocopy E:\VIDEO game\VIDEO /E
   robocopy E:\WAV game\WAV /E
   ```
   `game\SPACEBUC.INI`:
   ```
   [Config]
   CDDRIVE=D:
   ```
3. Lift into `work\`: `py -3 tools\relift.py`. The first run builds
   `work\win16_imports.json` (the Win16 API names by ordinal) from Wine's
   `.spec` files, downloaded by pcrecomp's `wine_spec_to_json.py`; they are
   LGPL, so the map is made here and never committed. Then `ne_link` lifts
   the game with pcrecomp's own code map (no IDA): 17,668 functions.
4. Build:
   ```
   cmake -S . -B build -G Ninja -DCMAKE_C_COMPILER=C:/msys64/mingw64/bin/gcc.exe
   cmake --build build
   ```
5. Run `build\spacebucks.exe`.

`PCRECOMP_DIR` (for `relift.py`, and `-DPCRECOMP_DIR=` for CMake) points at a
toolkit checkout other than `..\pcrecomp`; the lifter and the runtime must
come from the same tree.

## Trip-ups

- `python` opening the Microsoft Store: that is Windows' alias placeholder;
  use `py -3`.
- A freshly installed tool is not on `PATH` until you open a new window.
- gcc failing to find `cc1`: `C:\msys64\mingw64\bin` is not on `PATH`.
- A pcrecomp on `main` or `pcrecomp-ne-nativemap`: it lacks the dialog-by-name
  fixes, and the opening menu draws only its background.

## Scripted input

`RECOMP_INPUT` feeds clicks (`delay:x,y`, seconds, client coordinates of the
topmost window) and keys (`delay:kVK`) to the game; this
walks New Game into the running game:

```
set RECOMP_INPUT=12:150,119;3:149,198;3:149,229;3:150,262;3:150,119
build\spacebucks.exe
```

Run it on a virtual monitor (`offstage run -- build\spacebucks.exe`), not your
own screen; there is no headless mode yet.

## netlab

`netlab build spacebucks-recomp` builds it on the MinGW builder.

## Linux and macOS

Not yet. The host is Win32 and the build MinGW gcc; `setup.sh` says so and exits.
