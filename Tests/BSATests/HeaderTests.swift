// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/03/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

@testable import BSA
import XCTest
import XCTestExtensions


class HeaderTests: XCTestCase {
    func testCounts() throws {
        let folders = [
            FolderPromise(path: "textures/clothes/blackgloves", files: [
                .init(url: URL(fileURLWithPath: "glovesm_d.dds"))
            ])
        ]
        
        let header = BSAHeader(flags: [.includeFileNames, .includeDirectoryNames, .compressed], folders: folders)
        XCTAssertEqual(header.fileID, "BSA\0")
        XCTAssertEqual(header.version, 105)
        XCTAssertEqual(header.flags, [.includeFileNames, .includeDirectoryNames, .compressed])
        XCTAssertEqual(header.folderCount, 1)
        XCTAssertEqual(header.fileCount, 1)
        XCTAssertEqual(header.totalFolderNameLength, 29)
        XCTAssertEqual(header.totalFileNameLength, 14)
        XCTAssertEqual(header.padding, 0)
    }
}
