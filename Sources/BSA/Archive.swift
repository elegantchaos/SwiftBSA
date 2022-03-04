// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BinaryCoding
import Compression
import Foundation
import Logger

public let packingChannel = Channel("BSA Pack")
public let unpackingChannel = Channel("BSA Unpack")
public let hashChannel = Channel("BSA Hash")

public struct Archive {
    public var id: Tag
    public var data: Data
    public var version: Int
    public var flags: Flags
    public var content: ContentFlags
    public var folders: Folders
    
    public init(version: Int = 105, flags: Flags = [.includeFileNames, .includeDirectoryNames], content: ContentFlags = []) {
        self.id = "BSA\0"
        self.version = version
        self.flags = flags
        self.content = content
        self.data = Data()
        self.folders = Folders()
    }
    
    public init(url: URL) throws {
        
        let data = try Data(contentsOf: url)
        let decoder = BSADecoder(data: data)
        let header = try decoder.decode(BSAHeader.self)
        
        decoder.header = header

        let records = try decoder.decodeArray(of: FolderRecord.self, count: Int(header.folderCount))
        let folders = try Folders(records: records, decoder: decoder)
        
        self.id = header.fileID
        self.version = Int(header.version)
        self.flags = header.flags
        self.content = header.content
        self.data = data
        self.folders = folders
    }
    
    static func decodeFolders(from records: [FolderRecord], using decoder: BSADecoder) throws -> [Folder] {
        let includingNames = decoder.decodeBSADirectoryNames
        var folders: [Folder] = []
        for record in records {
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
            
            var files: [BSAFile] = []
            for _ in 0..<record.count {
                files.append(try decoder.decode(BSAFile.self))
            }
            
            let folder = Folder(name: name, hash: record.hash, offset: record.offset, files: files)
            folders.append(folder)
        }
        return folders
    }
    
    public func extract(to url: URL) throws {
        try folders.extract(to: url, from: data, embeddedNames: flags.contains2(.embeddedFileNames))
    }
    
    public mutating func pack(url: URL) throws {
        let folders = try packFolder(url: url, to: "")
        var sortedFolders = folders.sorted()
        let header = BSAHeader(version: version, flags: flags, content: content, folders: sortedFolders)
        
        let encoder = DataEncoder()
        try header.encode(to: encoder)

        // write folders
        for n in 0..<sortedFolders.count {
            try sortedFolders[n].encodeRecordingPatch(to: encoder)
        }
        
        
        // write file records
        let includeFolderNames = flags.contains2(.includeDirectoryNames)
        for n in 0..<sortedFolders.count {
            try encodeFileRecords(for: &sortedFolders[n], to: encoder, includeName: includeFolderNames, header: header)
        }

        // write file names
        let includeFileNames = flags.contains2(.includeFileNames)
        if includeFileNames {
            for folder in sortedFolders {
                for file in folder.files {
                    try file.name.encode(to: encoder)
                }
            }
        }
        
        // write data
        for folder in sortedFolders {
            for file in folder.files {
                try file.name.encode(to: encoder)
            }
        }

        self.data = encoder.data
    }
    
    func encodeFileRecords(for folder: inout FolderPromise, to encoder: DataEncoder, includeName: Bool, header: BSAHeader) throws {
        folder.resolvePatch(for: encoder, header: header)
        if includeName {
            try folder.name.encode(to: encoder)
        }

        for n in 0..<folder.files.count {
            folder.files[n].patchLocation = UInt32(encoder.data.count)
            try BSAFile(folder.files[n]).binaryEncode(to: encoder)
        }
    }
    
    func packFolder(url: URL, to path: String) throws -> [FolderPromise] {
        let fm = FileManager.default
        
        var folders: [FolderPromise] = []
        var files: [FileSpec] = []
        let urls = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        for url in urls {
            var isDirectory: ObjCBool = false
            if fm.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    let name = url.lastPathComponent.lowercased()
                    let subpath = path.isEmpty ? name : "\(path)\\\(name)"
                    folders.append(contentsOf: try packFolder(url: url, to: subpath))
                } else {
                    files.append(FileSpec(url: url))
                }
            }
        }
        
        if files.count > 0 {
            let thisFolder = FolderPromise(path: path, files: files)
            folders.append(thisFolder)
        }
        
        return folders
    }
    
    public var folderCount: Int {
        folders.folders.count
    }
}

struct FileSpec {
    let name: Data
    let hash: UInt64
    let url: URL
    var patchLocation: UInt32
    
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
        self.patchLocation = 0
        hashChannel.debug("file: \(name), hash: \(String(format: "0x%0X",hash))")
    }
}

extension FileSpec: Comparable {
    static func < (lhs: FileSpec, rhs: FileSpec) -> Bool {
        return lhs.hash < rhs.hash
    }
}
