/* sierra_dlls.c - the third-party DLLs Space Bucks ships: Miles (WAIL16), silent;
 * Borland BWCC's DialogBox. (Miles Sound System, WAIL16.DLL, below.)
 *
 * Space Bucks plays its sounds through Miles' 16-bit Windows API, imported by
 * name from WAIL16.DLL, which is not the game's code and is not lifted. This
 * is a driver that accepts everything and plays nothing: the game's own
 * logic runs, sounds are "done" as soon as they start. Real sound is on the
 * roadmap (decode the samples, play them through waveOut).
 *
 * Each shim pops its own PASCAL arguments (the far return frame plus the
 * argument bytes, as read off the game's call sites: tools/callsite_purges.py)
 * and returns in AX or DX:AX.
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "cpu.h"

static inline uint16_t a16(CPU *cpu, int off) {
    return mem_read16(cpu, cpu->ss, (uint16_t)(cpu->sp + 4 + off));
}
static inline void ret(CPU *cpu, int purge) { cpu->sp += 4 + purge; }
static inline void ret32(CPU *cpu, uint32_t v, int purge) {
    cpu->ax = (uint16_t)v; cpu->dx = (uint16_t)(v >> 16); ret(cpu, purge);
}

#define FAKE_DRIVER 0x00010001u
static uint16_t g_samples;

/* The game asks waveOutGetNumDevs before it starts Miles; 0 makes it stop
 * with "No wave devices!". One, which Miles then "opens". */
void MMSYSTEM_WAVEOUTGETNUMDEVS(CPU *cpu) { cpu->ax = 1; ret(cpu, 0); }

void WAIL16_AIL_STARTUP(CPU *cpu)  { ret(cpu, 0); }
void WAIL16_AIL_SHUTDOWN(CPU *cpu) { ret(cpu, 0); }
void WAIL16_AIL_SERVE(CPU *cpu)    { ret(cpu, 0); }

/* AIL_waveOutOpen(HDIGDRIVER far *drvr, LPHWAVEOUT far *hwo, DWORD id,
 * LPWAVEFORMAT fmt) -> 0 on success. */
void WAIL16_AIL_WAVEOUTOPEN(CPU *cpu) {
    uint16_t doff = a16(cpu, 12), dseg = a16(cpu, 14);
    if (dseg || doff) {
        mem_write16(cpu, dseg, doff, (uint16_t)FAKE_DRIVER);
        mem_write16(cpu, dseg, (uint16_t)(doff + 2), (uint16_t)(FAKE_DRIVER >> 16));
    }
    fprintf(stderr, "[miles] waveOutOpen: a silent driver\n");
    ret32(cpu, 0, 16);
}

/* AIL_last_error() -> char far *. Only asked after a failure, which the
 * silent driver never reports. */
void WAIL16_AIL_LAST_ERROR(CPU *cpu) { ret32(cpu, 0, 0); }

/* Samples: handles that are never null; every one is done. */
void WAIL16_AIL_ALLOCATE_SAMPLE_HANDLE(CPU *cpu) { ret32(cpu, 0x00020000u | ++g_samples, 4); }
void WAIL16_AIL_RELEASE_SAMPLE_HANDLE(CPU *cpu)  { ret(cpu, 4); }
void WAIL16_AIL_INIT_SAMPLE(CPU *cpu)            { ret(cpu, 4); }
void WAIL16_AIL_START_SAMPLE(CPU *cpu)           { ret(cpu, 4); }
void WAIL16_AIL_END_SAMPLE(CPU *cpu)             { ret(cpu, 4); }
void WAIL16_AIL_SET_SAMPLE_ADDRESS(CPU *cpu)     { ret(cpu, 12); }
void WAIL16_AIL_SET_SAMPLE_TYPE(CPU *cpu)        { ret(cpu, 12); }
void WAIL16_AIL_SET_SAMPLE_PLAYBACK_RATE(CPU *cpu) { ret(cpu, 8); }
void WAIL16_AIL_SET_SAMPLE_VOLUME(CPU *cpu)      { ret(cpu, 8); }
void WAIL16_AIL_SET_SAMPLE_PAN(CPU *cpu)         { ret(cpu, 8); }
void WAIL16_AIL_LOAD_SAMPLE_BUFFER(CPU *cpu)     { ret(cpu, 16); }
/* SMP_DONE (2): over as soon as it starts. */
void WAIL16_AIL_SAMPLE_STATUS(CPU *cpu)          { ret32(cpu, 2, 4); }
/* -1: neither stream buffer wants filling. */
void WAIL16_AIL_SAMPLE_BUFFER_READY(CPU *cpu)    { ret32(cpu, 0xFFFFFFFFu, 4); }

/* Miles' file helpers. FILE_read(name, dest) -> far pointer, FILE_size(name)
 * -> bytes, MEM_alloc_lock(size), MEM_free_lock(ptr). Failing them sends a
 * sound down the game's "not loaded" path. ponytail: real loads come with
 * real sound. */
void WAIL16_FILE_READ(CPU *cpu)      { ret32(cpu, 0, 8); }
void WAIL16_FILE_SIZE(CPU *cpu)      { ret32(cpu, 0xFFFFFFFFu, 4); }
void WAIL16_MEM_ALLOC_LOCK(CPU *cpu) { ret32(cpu, 0, 4); }
void WAIL16_MEM_FREE_LOCK(CPU *cpu)  { ret(cpu, 4); }

/* BWCC.DLL #2 is Borland's DialogBox(hInst, lpTemplate, hWndParent, lpDialogFunc):
 * the same arguments as USER's, which draws the dialog (the BWCC look, its
 * chiselled buttons and grey, is BWCC's own and is not reproduced). Every
 * game dialog goes through it: OPEN0 (the opening menu), MESSAGE, ... */
void USER_DIALOGBOX(CPU *cpu);
void BWCC_Ord2(CPU *cpu) { USER_DIALOGBOX(cpu); }
