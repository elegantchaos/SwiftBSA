// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BinaryCoding
import Compression
import Foundation
import Logger
import SWCompression

let packingChannel = Channel("BSA Pack")
let unpackingChannel = Channel("BSA Unpack")
let hashChannel = Channel("BSA Hash")

public struct Archive {
    public var id: Tag
    public var data: Data
    public var version: Int
    public var flags: BSAFlags
    public var fileFlags: UInt16
    public var folders: [BSAFolder]
    
    public init(version: Int = 105, flags: BSAFlags = [.includeFileNames, .includeDirectoryNames], fileFlags: UInt16 = 0) {
        self.id = "BSA\0"
        self.version = version
        self.flags = flags
        self.fileFlags = fileFlags
        self.data = Data()
        self.folders = []
    }
    
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
                hashChannel.debug("folder: \(folder.name!), hash: \(folder.nameHash)")
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
                    hashChannel.debug("file: \(folders[i].files[j].name!), hash: \(folders[i].files[j].nameHash)")
                }
            }
        }
        
        self.id = header.fileID
        self.version = Int(header.version)
        self.flags = header.flags
        self.fileFlags = header.fileFlags
        self.data = data
        self.folders = folders
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
                if flags.contains2(.embeddedFileNames) {
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
                } else {
                    let fileData = data[offset..<offset+size]
                    try fileData.write(to: fileURL)
                }
            }
        }
    }
    
    public mutating func pack(url: URL) throws {
        let folders = try packFolder(url: url)
        let sortedFolders = folders.sorted()
        let header = BSAHeader(version: version, flags: flags, fileFlags: fileFlags, folders: sortedFolders)
        print(header)
    }
    
    func packFolder(url: URL) throws -> [FolderSpec] {
        let fm = FileManager.default
        
        var folders: [FolderSpec] = []
        var files: [FileSpec] = []
        let urls = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.producesRelativePathURLs])
        for url in urls {
            var isDirectory: ObjCBool = false
            if fm.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    folders.append(contentsOf: try packFolder(url: url))
                } else {
                    files.append(FileSpec(url: url))
                }
            }
            
            
        }
        
        let thisFolder = FolderSpec(url: url, files: files)
        folders.append(thisFolder)
        
        return folders
    }
}

struct FolderSpec {
    let hash: UInt64
    let name: Data
    let files: [FileSpec]
    
    init(url: URL, files: [FileSpec]) {
        let path = url.relativePath.replacingOccurrences(of: "/", with: "\\").lowercased()
        
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

extension FolderSpec: Equatable {
}

extension FolderSpec: Comparable {
    static func < (lhs: FolderSpec, rhs: FolderSpec) -> Bool {
        lhs.hash < rhs.hash
    }
}

struct FileSpec {
    let name: Data
    let hash: UInt64
    let url: URL
    
    init(url: URL) {
        let name = url.lastPathComponent.lowercased()
        var data = Data()
        if let bytes = name.data(using: .windowsCP1252) {
            data.append(contentsOf: bytes)
            data.append(UInt8(0))
        }

        self.url = url
        self.name = data
        self.hash = name.bsaHash
    }
}

extension FileSpec: Comparable {
    static func < (lhs: FileSpec, rhs: FileSpec) -> Bool {
        return lhs.hash < rhs.hash
    }
    
    
}
