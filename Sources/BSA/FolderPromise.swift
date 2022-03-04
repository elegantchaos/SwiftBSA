// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import BinaryCoding

/// Contains all the information needed to write a folder record.
struct FolderPromise {
    let hash: UInt64
    let name: Data
    var files: [FileSpec]
    var patchLocation: Int
    
    init(path: String, files: [FileSpec]) {
        var data = Data()
        if let bytes = path.data(using: .windowsCP1252) {
            data.append(UInt8(bytes.count + 1)) // length includes zero byte
            data.append(contentsOf: bytes)
            data.append(UInt8(0))
        }
        
        self.hash = path.bsaHash
        self.files = files
        self.name = data
        self.patchLocation = 0
        hashChannel.debug("folder: \(path), hash: \(String(format: "0x%0X",hash))")
    }
    
    mutating func encodeRecordingPatch(to encoder: DataEncoder) throws {
        patchLocation = encoder.data.count
        try FolderRecord(self).binaryEncode(to: encoder)
    }
    
    func resolvePatch(for encoder: DataEncoder, header: BSAHeader) {
        encoder.patch(encoder.data.count + Int(header.totalFileNameLength), at: patchLocation + FolderRecord.patchOffset)
    }
}

extension FolderPromise: Equatable {
}

extension FolderPromise: Comparable {
    static func < (lhs: FolderPromise, rhs: FolderPromise) -> Bool {
        lhs.hash < rhs.hash
    }
}
