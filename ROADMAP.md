# Roadmap

## Next
- Route mode draws its side panels out of place (the right column repeats lower
  down); trading, ports and ship building are unchecked.
- Game dialogs are laid out too small (their right edge is clipped).
- Play: the galaxy map, a star port, trading, building a ship.
- Smacker: decode `.SMK` videos (SmackOpen/DoFrame/ToBuffer) or skip them cleanly.
- Sound: play Miles' samples through waveOut instead of the silent driver.
- `WIN87EM.__FPMATH` (stubbed), `waveOutGetDevCaps`.

## Then
- A conformance harness: a fixed list of milestones (boot, logo, credits,
  title, opening menu) checked by captures, with a pass count in the README
  and a netlab `QA` line.
- Headless mode, `--headless --record out.mp4`, so runs and captures need no
  screen (REPO_RULES section 10).
- The toolkit fix on pcrecomp's `pcrecomp-ne-spacebucks` branch merged into `main`, and
  the setup pinned to `main`.
- A published installer (recomp-launcher) once the game is playable.
- BWCC's look for the dialogs.
