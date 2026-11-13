#!/bin/sh
# Space Bucks runs on pcrecomp's Win16 host, which is Win32 code built with
# MinGW gcc on Windows. There is no Linux or macOS build yet, and the Wine
# route has not been tested, so this script does nothing but say so.
echo "Space Bucks recomp: Linux and macOS are not supported yet."
echo "Build it on Windows with Setup.cmd (docs/building.md)."
exit 1
