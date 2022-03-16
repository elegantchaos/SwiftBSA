// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import BinaryCoding
import SWCompression

/// Sorted list of folders
public struct Folders {
    let folders: [Folder]
    
    init(records: [FolderRecord], decoder: BinaryDecoder) throws {
        let includingNames = decoder.decodeBSADirectoryNames
        var folders: [Folder] = []
        for record in records {

            // decode optional folder name
            let name: String?
            if includingNames {
                let length = try decoder.decode(UInt8.self)
                var chars = try decoder.decodeArray(of: UInt8.self, count: Int(length))
                if chars.last == 0 {
                    chars.removeLast()
                }
                name = String(bytes: chars, encoding: decoder.stringEncoding)
                hashChannel.debug("folder: \(name!), hash: \(String(format: "0x%0X",record.hash))")
            } else {
                name = nil
            }
            
            // decode files
            var files: [BSAFile] = []
            for _ in 0..<record.count {
                files.append(try decoder.decode(BSAFile.self))
            }
            
            let folder = Folder(name: name, hash: record.hash, offset: record.offset, files: files)
            folders.append(folder)
        }
        
        // decode optional file names
        if decoder.decodeBSAFileNames {
            for i in 0..<folders.count {
                for j in 0..<folders[i].files.count {
                    folders[i].files[j].name = try decoder.decode(String.self)
                    hashChannel.debug("file: \(folders[i].files[j].name!), hash: \(folders[i].files[j].nameHash)")
                }
            }
        }

        self.folders = folders
    }
    
    init() {
        self.folders = []
    }
    
    public func extract(to url: URL, from data: Data, embeddedNames: Bool) throws {
        let fm = FileManager.default
        
        for folder in folders {
            let folderPath = folder.name ?? "\(folder.hash)"
            var folderURL = url
            for component in folderPath.split(whereSeparator: { c in (c == "\\") || (c == "/") }) {
                folderURL = folderURL.appendingPathComponent(String(component))
            }
            try? fm.createDirectory(at: folderURL, withIntermediateDirectories: true)
            for file in folder.files {
                let fileName = file.name ?? "\(file.nameHash)"
                let fileURL = folderURL.appendingPathComponent(fileName)
                var offset = Int(file.offset)
                var size = Int(file.size)
                if embeddedNames {
                    let nameLength = Int(data[offset])
                    offset += 1
                    size -= 1
                    #if DEBUG
                    let nameData = data[offset..<offset+nameLength]
                    if let name = String(data: nameData, encoding: .utf8) {
                        print("Embedded name \(name)")
                    }
                    #endif
                    offset += nameLength
                    size -= nameLength
                }
                if file.isCompressed {
                    let lengthBytes = data[offset..<offset+4].littleEndianBytes
                    let originalLength = try UInt32(littleEndianBytes: lengthBytes)
                    offset += 4 // skip the original size
                    size -= 4
                    let compressedData = Data(data[offset..<offset+size])
                    let decompressed = try LZ4.decompress(data: compressedData)
                    assert(originalLength == decompressed.count)
                    try decompressed.write(to: fileURL)
                    unpackingChannel.log("unpacked: \(fileName), size: \(size), decompressed: \(decompressed.count)")
                } else {
                    unpackingChannel.log("unpacked: \(fileName), size: \(size)")
                    let fileData = data[offset..<offset+size]
                    try fileData.write(to: fileURL)
                }
            }
        }
    }
}
