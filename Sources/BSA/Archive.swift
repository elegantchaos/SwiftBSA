// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BinaryCoding
import Compression
import Foundation
import Logger
import SWCompression

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
        var folders = try getFolders(url: url, to: "").sorted(by: { $0.hash < $1.hash })
        let header = BSAHeader(version: version, flags: flags, content: content, folders: folders)
        
        let encoder = DataEncoder()
        try header.encode(to: encoder)

        let includeFolderNames = flags.contains2(.includeDirectoryNames)
        let includeFileNames = flags.contains2(.includeFileNames)
        let embedFullPath = flags.contains2(.embeddedFileNames)
        let compressData = flags.contains2(.compressed)
        
        // write folder records
        for n in 0..<folders.count {
            try folders[n].encodeRecordingPatch(to: encoder)
        }
        
        // write file records
        for n in 0..<folders.count {
            try encodeFileRecords(for: &folders[n], to: encoder, includeName: includeFolderNames, header: header)
        }

        // write file names
        if includeFileNames {
            for folder in folders {
                for file in folder.files {
                    try file.name.encode(to: encoder)
                }
            }
        }
        
        // write data
        for folder in folders {
            for file in folder.files {
                let raw = try Data(contentsOf: file.url)
                let data: Data
                let size: Int
                
                if compressData {
//                    data = LZ4.compress(data: raw)
                    data = LZ4.compress(data: raw, independentBlocks: true, blockChecksums: false, contentChecksum: false, contentSize: false, blockSize: 105592, dictionary: nil, dictionaryID: nil)
                    size = data.count + 4
                } else {
                    data = raw
                    size = data.count
                }
                
                file.resolvePatches(for: encoder, size: size)
                if embedFullPath {
                    try file.path.encode(to: encoder)
                }

                if compressData {
                    let originalSize = UInt32(raw.count)
                    try originalSize.encode(to: encoder)
                }
                
                try data.encode(to: encoder)
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
            try folder.files[n].encodeRecordingPatches(to: encoder)
        }
    }
    
    func getFolders(url: URL, to path: String) throws -> [FolderPromise] {
        let fm = FileManager.default
        
        var folders: [FolderPromise] = []
        var files: [FilePromise] = []
        let urls = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        for url in urls {
            var isDirectory: ObjCBool = false
            if fm.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    let name = url.lastPathComponent.lowercased()
                    let subpath = path.isEmpty ? name : "\(path)\\\(name)"
                    folders.append(contentsOf: try getFolders(url: url, to: subpath))
                } else {
                    files.append(FilePromise(url: url, path: path))
                }
            }
        }
        
        if files.count > 0 {
            let thisFolder = FolderPromise(path: path, files: files.sorted(by: { $0.hash < $1.hash }))
            folders.append(thisFolder)
        }
        
        return folders
    }
    
    public var folderCount: Int {
        folders.folders.count
    }
}
