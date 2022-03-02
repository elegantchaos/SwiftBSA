// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

struct BSAHash {
    static func hash(for url: URL) -> UInt64
    {
        let pathExtension = url.pathExtension
        let path = url.deletingPathExtension().path.replacingOccurrences(of: "/", with: "\\")
        
        return hash(forPath: path, pathExtension: pathExtension)
    }

    static func hash(forPath nameString: String, pathExtension extString: String) -> UInt64 {
        let name = nameString.lowercased().data(using: .windowsCP1252)!
        let ext = extString.lowercased().data(using: .windowsCP1252)!
        
        let c1 = UInt32((name.count == 0) ? 0 : name.last!)
        let c2 = UInt32((name.count < 3) ? 0 : name.dropLast().last!)
        let c3 = UInt32(name.count)
        let c4 = UInt32(name.first!)
        
        var hash1 = c1 + (c2 << 8) + (c3 << 16) + (c4 << 24)
        switch (extString)
        {
            case ".kf": hash1 |= 0x80
            case ".nif": hash1 |= 0x8000
            case ".dds": hash1 |= 0x8080
            case ".wav": hash1 |= 0x80000000
            default: break
        }

        var hash2: UInt32 = 0
        for i in 1..<(name.count - 2) {
            hash2 = hash2 * 0x1003f + UInt32(name[i])
        }

        var hash3: UInt32 = 0
        for i in 0..<ext.count {
            hash3 = hash3 * 0x1003f + UInt32(ext[i])
        }

        return ((UInt64(hash2) + UInt64(hash3)) << 32) + UInt64(hash1)
    }
}
