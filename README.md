# BSA

Swift support for Bethesda's BSA file format, as used by Skyrim, Fallout, etc.

Currently this version of the code supports version 105, as used by Skyrim SE/AE. 

Support for earlier versions may be added at some later date. 

## Here Be Dragons

This is an early version, and it currently only supports extracting a `.bsa` file to a directory, and packing a directory to a compressed archive.

Right now it's just a library and some tests. 

The next step will be to add a command line tool target, but I envisage it mostly being used as a library, linked to by other tools. 

## Why?

This is part of a [larger tools project](https://github.com/elegantchaos/SkyrimFileFormat).

### Why Swift?

It's what I use for the day job, has decent cross platform support, and I needed an excuse to mess around with some binary streaming and async/await things. 

### Why Cross Platform?

1. Although I play Skyrim on a PC, I do most of my coding work on a Mac.
2. OpenMW supports Windows/MacOS/Linux. At some point I'd like to extend this tool and the other things I'm working on to support OpenMW.

## Useful Info

- File Format: https://en.uesp.net/wiki/Skyrim_Mod:Archive_File_Format
- Some Notes: https://github.com/focustense/easymod/tree/master/Focus.Apps.EasyNpc
- Other Implementations:
  - https://github.com/focustense/easymod/blob/master/Focus.Storage.Archives/README.md
  - https://github.com/Guekka/libbsarch
  - https://github.com/TES5Edit/TES5Edit/tree/dev/Tools/BSArchive
