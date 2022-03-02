// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BinaryCoding
import Compression
import Foundation
import Logger

let packingChannel = Channel("BSA Pack")
let unpackingChannel = Channel("BSA Unpack")
let hashChannel = Channel("BSA Hash")

public struct Archive {
    public var id: Tag
    public var data: Data
    public var version: Int
    public var flags: BSAFlags
    public var fileFlags: FileFlags
    public var folders: Folders
    
    public init(version: Int = 105, flags: BSAFlags = [.includeFileNames, .includeDirectoryNames], fileFlags: FileFlags = FileFlags()) {
        self.id = "BSA\0"
        self.version = version
        self.flags = flags
        self.fileFlags = fileFlags
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
        self.fileFlags = FileFlags(rawValue: header.fileFlags)
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
                hashChannel.debug("folder: \(name!), hash: \(record.nameHash)")
            } else {
                name = nil
            }
            
            var files: [BSAFile] = []
            for _ in 0..<record.count {
                files.append(try decoder.decode(BSAFile.self))
            }
            
            let folder = Folder(name: name, hash: record.nameHash, offset: record.offset, files: files)
            folders.append(folder)
        }
        return folders
    }
    
    public func extract(to url: URL) throws {
        try folders.extract(to: url, from: data, embeddedNames: flags.contains2(.embeddedFileNames))
    }
    
    public mutating func pack(url: URL) throws {
        let folders = try packFolder(url: url, to: "")
        let sortedFolders = folders.sorted()
        let header = BSAHeader(version: version, flags: flags, fileFlags: fileFlags, folders: sortedFolders)
        print(header)
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
