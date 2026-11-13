# Notice

The MIT license in [LICENSE](LICENSE) covers what is ours in this repository:
the runtime shims, the setup scripts, the tools and the documentation. It does
not cover the game.

*Space Bucks* is © 1996 Sierra On-Line / Impressions Games, and is not ours to
license. Its executable, data, videos, sounds and art are not in this
repository and are excluded by `.gitignore`. Smacker is RAD Game Tools', the
Miles Sound System RAD's (then Miles Design), BWCC Borland's; none of them is
included either. `runtime/sierra_dlls.c` answers their APIs with our own code.

- You need your own copy of the game to use any of this. Setup copies your CD
  into `game/`; the pipeline reads it from there.
- Lifted code is a derivative work of the binary it came from. Anything the
  pipeline writes into `work/` or `src/recomp/gen*/` carries whatever license
  the original carries, not this one. The MIT grant stops at our own work.
- `work/win16_imports.json`, the Win16 API names by ordinal, is built on your
  machine by pcrecomp's `tools/ne/wine_spec_to_json.py` from Wine's 16-bit
  `.spec` files (LGPL-2.1). It is generated, never committed, and nothing of
  Wine's is in this repository.

The Win16 front end and host runtime are
[pcrecomp](https://github.com/sp00nznet/pcrecomp)'s (MIT), fetched by setup
rather than vendored. The project layout follows the
[Catz recomp](https://github.com/sp00nznet/catz-recomp).
