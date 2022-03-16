// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public struct BSAHash {
    public static func hash(forPath nameString: String, pathExtension extString: String) -> UInt64 {
        let name = nameString.lowercased().data(using: .windowsCP1252)!
        let ext = extString.lowercased().data(using: .windowsCP1252)!
        
        let count = name.count
        let c1 = UInt32((count == 0) ? 0 : name[count - 1])
        let c2 = UInt32((count < 3) ? 0 : name[count - 2])
        let c3 = UInt32(count)
        let c4 = UInt32(name[0])
        
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
            hash2 = hash2 &* 0x1003f &+ UInt32(name[i])
        }

        var hash3: UInt32 = 0
        for i in 0..<ext.count {
            hash3 = hash3 &* 0x1003f &+ UInt32(ext[i])
        }

        let hash23 = hash2 &+ hash3
        return (UInt64(hash23) << 32) + UInt64(hash1)
    }
}

public extension URL {
    var bsaHash: UInt64 {
        let path = self.deletingPathExtension().relativePath.replacingOccurrences(of: "/", with: "\\")
        let ext = pathExtension.isEmpty ? "" : ".\(pathExtension)"
        return BSAHash.hash(forPath: path, pathExtension: ext)
    }
}

public extension String {
    var bsaHash: UInt64 {
        return URL(fileURLWithPath: self).bsaHash
    }
}
