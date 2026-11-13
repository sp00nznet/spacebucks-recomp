/* game.c - the few facts about Space Bucks that pcrecomp's Win16 host runtime
 * needs. See <pcrecomp>/runtime/win16/host/recomp_game.h for each field. */
#include "recomp_game.h"

const RecompGame recomp_game = {
    .title      = "Space Bucks",
    .guest_dir  = "C:\SIERRA\SPACEBUC",
    /* The installer writes [Config] CDDRIVE here; the CD's folders are merged
       into game/, so any drive letter maps there. */
    .ini_fallbacks = { "SPACEBUC.INI", NULL },
    /* Its WinG surface, timer and palette are made in WM_CREATE. */
    .create_message = 1,
};
