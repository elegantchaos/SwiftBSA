#!/usr/bin/python
# Reference implementation, taken from https://en.uesp.net/wiki/Oblivion_Mod:Hash_Calculation

import os
import sys

def tesHash(fileName):
    """Returns tes4's two hash values for filename.
    Based on TimeSlips code with cleanup and pythonization."""

    root,ext = os.path.splitext(fileName.lower()) #--"bob.dds" >> root = "bob", ext = ".dds"
    #--Hash1
    chars = map(ord,root) #--'bob' >> chars = [98,111,98]
    hash1 = chars[-1] | (0,chars[-2])[len(chars)>2]<<8 | len(chars)<<16 | chars[0]<<24
    #--(a,b)[test] is similar to test?a:b in C. (Except that evaluation is not shortcut.)
    if   ext == '.kf':  hash1 |= 0x80
    elif ext == '.nif': hash1 |= 0x8000
    elif ext == '.dds': hash1 |= 0x8080
    elif ext == '.wav': hash1 |= 0x80000000
    #--Hash2
    #--Python integers have no upper limit. Use uintMask to restrict these to 32 bits.
    uintMask, hash2, hash3 = 0xFFFFFFFF, 0, 0
    for char in chars[1:-2]: #--Slice of the chars array
        hash2 = ((hash2 * 0x1003f) + char ) & uintMask
    for char in map(ord,ext):
        hash3 = ((hash3 * 0x1003F) + char ) & uintMask
    hash2 = (hash2 + hash3) & uintMask
    #--Done
    return (hash2<<32) + hash1 #--Return as uint64


if len(sys.argv) == 2:
    print tesHash(sys.argv[1])
else:
    print "Usage: " + sys.argv[0] + " <path>"
