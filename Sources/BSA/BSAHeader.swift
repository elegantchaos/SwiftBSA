// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BinaryCoding
import Foundation

public struct BSAHeader: BinaryCodable {
    public let fileID: Tag
    public let version: UInt32
    public let offset: UInt32
    public let flags: BSAFlags
    public let folderCount: UInt32
    public let fileCount: UInt32
    public let totalFolderNameLength: UInt32
    public let totalFileNameLength: UInt32
    public let fileFlags: UInt16
    public let padding: UInt16
    
    init(version: Int = 105, flags: BSAFlags = [.includeFileNames, .includeDirectoryNames], fileFlags: UInt16 = 0, folders: [FolderPromise]) {
        
        var fileCount = 0
        var fileNameLength = 0
        var folderNameLength = 0
        
        let countFileNames = flags.contains2(.includeFileNames)
        let countFolderNames = flags.contains2(.includeDirectoryNames)
        
        for folder in folders {
            fileCount += folder.files.count
            if countFolderNames {
                folderNameLength += folder.name.count - 1 // don't include the length byte (see: https://en.uesp.net/wiki/Skyrim_Mod:Archive_File_Format)
            }
            
            if countFileNames {
                for file in folder.files {
                    fileNameLength += file.name.count
                }
            }
        }
        
        self.fileID = "BSA\0"
        self.version = UInt32(version)
        self.offset = 0x24
        self.flags = flags
        self.folderCount = UInt32(folders.count)
        self.fileCount = UInt32(fileCount)
        self.totalFolderNameLength = UInt32(folderNameLength)
        self.totalFileNameLength = UInt32(fileNameLength)
        self.fileFlags = fileFlags
        self.padding = 0
    }
}
