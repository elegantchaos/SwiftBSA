// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BinaryCoding
import Compression
import Foundation
import SWCompression

public struct BSArchive {
    public let url: URL
    public let data: Data
    public let header: BSAHeader
    public let folders: [BSAFolder]
    
    public init(url: URL) throws {
        
        let data = try Data(contentsOf: url)
        let decoder = BSADecoder(data: data)
        let header = try decoder.decode(BSAHeader.self)
        
        decoder.header = header

        var folders: [BSAFolder] = []
        for _ in 0..<header.folderCount {
            folders.append(try decoder.decode(BSAFolder.self))
        }

        var container = try decoder.unkeyedContainer()
        for i in 0..<folders.count {
            var folder = folders[i]

            if header.flags.contains2(.includeDirectoryNames) {
                let length = try container.decode(UInt8.self)
                var chars = try container.decodeArray(of: UInt8.self, count: length)
                if chars.last == 0 {
                    chars.removeLast()
                }
                folder.name = String(bytes: chars, encoding: decoder.stringEncoding)
                print("name: \(folder.name!), hash: \(folder.nameHash)")
            }
            
            var files: [BSAFile] = []
            for _ in 0..<folder.count {
                files.append(try container.decode(BSAFile.self))
            }
            folder.files = files
            folders[i] = folder
        }

        if header.flags.contains2(.includeFileNames) {
            for i in 0..<folders.count {
                for j in 0..<folders[i].files.count {
                    folders[i].files[j].name = try decoder.decode(String.self)
                    print("name: \(folders[i].files[j].name!), hash: \(folders[i].files[j].nameHash)")
                }
            }
        }
        
        self.url = url
        self.header = header
        self.folders = folders
        self.data = data
    }
    
    public func extract(to url: URL) throws {
        let fm = FileManager.default
        
        for folder in folders {
            let folderPath = folder.name ?? "\(folder.nameHash)"
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
                if header.flags.contains2(.embeddedFileNames) {
                    let nameLength = Int(data[offset])
                    offset += 1
                    size -= 1
                    let nameData = data[offset..<offset+nameLength]
                    let name = String(data: nameData, encoding: .utf8)
                    print("Embedded name \(name)")
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
                    try decompressed.write(to: fileURL)
                } else {
                    let fileData = data[offset..<offset+size]
                    try fileData.write(to: fileURL)
                }
            }
        }
    }
}
