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
    print("Arguments")
    print(root, ext)
    
    c1 = chars[-1]
    c2 = (0,chars[-2])[len(chars)>2]
    c3 = len(chars)
    c4 = chars[0]
    
    print("Hash1 Components")
    print(c1, c2, c3, c4)
    
    hash1 = c1 | c2<<8 | c3<<16 | c4<<24
    #--(a,b)[test] is similar to test?a:b in C. (Except that evaluation is not shortcut.)
    if   ext == '.kf':  hash1 |= 0x80
    elif ext == '.nif': hash1 |= 0x8000
    elif ext == '.dds': hash1 |= 0x8080
    elif ext == '.wav': hash1 |= 0x80000000
    
    print("Hash1")
    print(hash1)
    #--Hash2
    #--Python integers have no upper limit. Use uintMask to restrict these to 32 bits.
    uintMask, hash2, hash3 = 0xFFFFFFFF, 0, 0
    for char in chars[1:-2]: #--Slice of the chars array
        hash2 = ((hash2 * 0x1003f) + char ) & uintMask

    print("Hash2")
    print(hash2)

    for char in map(ord,ext):
        hash3 = ((hash3 * 0x1003F) + char ) & uintMask

    print("Hash3")
    print(hash3)

    hash2 = (hash2 + hash3) & uintMask
    #--Done
    return (hash2<<32) + hash1 #--Return as uint64


if len(sys.argv) == 2:
    hash = tesHash(sys.argv[1])
    print("")
    print("Final hash:")
    print(hash)
    
else:
    print "Usage: " + sys.argv[0] + " <path>"
