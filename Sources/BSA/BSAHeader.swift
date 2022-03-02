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
    
    init(version: Int = 105, flags: BSAFlags = [.includeFileNames, .includeDirectoryNames], fileFlags: UInt16 = 0, folders: [FolderSpec]) {
        self.fileID = "BSA\0"
        self.version = UInt32(version)
        self.offset = 0x24
        self.flags = flags
        self.folderCount = 0
        self.fileCount = 0
        self.totalFolderNameLength = 0
        self.totalFileNameLength = 0
        self.fileFlags = fileFlags
        self.padding = 0
    }
}
