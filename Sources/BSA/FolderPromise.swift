// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Contains all the information needed to write a folder record.
struct FolderPromise {
    let hash: UInt64
    let name: Data
    let files: [FileSpec]
    
    init(path: String, files: [FileSpec]) {
        var data = Data()
        if let bytes = path.data(using: .windowsCP1252) {
            data.append(UInt8(bytes.count))
            data.append(contentsOf: bytes)
            data.append(UInt8(0))
        }
        
        self.hash = path.bsaHash
        self.files = files
        self.name = data
    }
}

extension FolderPromise: Equatable {
}

extension FolderPromise: Comparable {
    static func < (lhs: FolderPromise, rhs: FolderPromise) -> Bool {
        lhs.hash < rhs.hash
    }
}
