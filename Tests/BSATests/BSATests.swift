// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 28/02/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BSA
import XCTest
import XCTestExtensions


class BSATests: XCTestCase {
    func testLoading() throws {
        let url = Bundle.module.url(forResource: "Example", withExtension: "bsa")!
        let bsa = try BSArchive(url: url)
        
        XCTAssertEqual(bsa.header.fileID, "BSA\0")
        XCTAssertEqual(bsa.header.version, 105)
        XCTAssertEqual(bsa.header.offset, 36)
        XCTAssertEqual(bsa.header.flags, [.includeFileNames, .includeDirectoryNames, .compressed])
        XCTAssertEqual(bsa.header.folderCount, 1)
        XCTAssertEqual(bsa.header.fileCount, 1)
        XCTAssertEqual(bsa.header.totalFolderNameLength, 29)
        XCTAssertEqual(bsa.header.totalFileNameLength, 14)
        XCTAssertEqual(bsa.header.fileFlags, 0)
        XCTAssertEqual(bsa.header.padding, 0)
    }
    
    @discardableResult func testExtraction(_ name: String) throws -> URL {
        let url = Bundle.module.url(forResource: name, withExtension: "bsa")!
        let bsa = try BSArchive(url: url)
        let output = outputDirectory().appendingPathComponent(name)
        try bsa.extract(to: output)
        
        var paths: [String] = []
        let enumerator = FileManager.default.enumerator(at: output, includingPropertiesForKeys: nil, options: [.producesRelativePathURLs])!
        for case let url as URL in enumerator {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize
            let sizeString = size.map { ", \($0)" } ?? ""
            paths.append("\(url.relativePath)\(sizeString)")
        }
        let manifest = paths.joined(separator: "\n")

        if let manifestURL = Bundle.module.url(forResource: name, withExtension: "txt") {
            let loadedManifest = String(data: try Data(contentsOf: manifestURL), encoding: .utf8)!
            XCTAssertEqual(manifest, loadedManifest)
        } else {
            print(manifest)
        }
        
        return output
    }
    
    func testExtractExample() throws {
        try testExtraction("Example")
    }
    
    func testExtractMCMHelper() throws {
        try testExtraction("MCMHelper")
    }

    func testExtractSkyUI() throws {
        try testExtraction("SkyUI_SE")
    }
    
//    func testExtractRaceMenu() throws {
//        try testExtraction("RaceMenu")
//    }
}
